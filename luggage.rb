#Our camping items
require 'camping'
require 'camping/ar'
require 'camping/session'
require 'rack/csrf'

#Custom requirements
require 'bcrypt'
require 'fileutils'
require 'yaml'

#Here are our custom displays
require './views/base'

#require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

Camping.goes :Luggage
Markaby::Builder.set(:auto_validation, false)
$config = YAML::load_file('config.yml') 

module Luggage
  include Camping::Session

  module Models
    class Item < Base;end

    class BasicFields < V 1.0
      def self.up
        create_table :luggage_items, :force => true do |t|
          t.string   :key
          t.string   :name
          t.string   :path
          t.string   :filetype
          t.integer  :views
          t.string   :handler
          t.timestamps
        end
      end

      def self.down
       drop_table :luggage_items
      end
    end
  end

  module Controllers
    class Index
      def get
        if logged_in?
          @files = Item.order('created_at DESC').limit($config['items_per_page'])
          @count = Item.count()
          @page = 1
          render :index
        else
          item = Item.order('created_at DESC').limit(1).first
          redirect ViewX, item.key
        end
      end
    end

    class PageN
      def get(page)

        #If we're not given a number, go to index
        begin
          @page = Integer(page)
        rescue
          redirect Index
        end

        @count = Item.count()
        #If we're giving a number below zero or greater than we have
        #pages for go to the index
        if @page < 1 or (@page - 1) * $config['items_per_page'] > @count
          redirect Index
        else
          @files = Item.order('created_at DESC').limit($config['items_per_page']).offset((@page - 1) * $config['items_per_page'])
          render :index
        end
      end
    end

    class Login
      def get
        if logged_in?
          redirect Index
        else
          @login_error = false
          render :login
        end
      end

      def post
        @password = BCrypt::Password.new($config['password_hash'])
        if $config['username'] == input.username and @password == input.password
          @state.user_id = 1
          redirect Index
        else
          @login_error = true
          render :login
        end
      end
    end 

    class Logout
      def get
        @state.user_id = nil
        redirect Index
      end
    end

    class Upload
      def post
        require_login!
        temp = input.upload[:tempfile].path()

        #TODO: something different and only if this is really needed
        #new key every second, good until 2038-12-24
        time = Time.now.to_f * 100
        key = time.to_i.to_s(36)

        filename = input.upload[:filename]
        extension = File.extname(filename)
        path = "#{$config['upload_path']}/#{key}-#{filename}"
        FileUtils.cp temp, path

        #find an appropriate handler
        handlerClass = nil
        classes = LuggageDisplays.constants.collect{ |c| LuggageDisplays.const_get(c) }

        classes.each do |c|
          if c::HANDLES[extension] != nil
            handlerClass = c
          end
        end

        if handlerClass == nil
          handlerClass = LuggageDisplays::Default
        end

        item = Item.create :key => key, :name => filename, :path => path, :filetype => extension, :views => 0, :handler => handlerClass.name

        #instantiate handler and process
        handler = handlerClass.new(item)
        handler.process

        #returns json if ajax: true
        if input.json
          item.to_json
        else
          redirect ViewX, item.name
        end
      end
    end

    class RemoveX
      def get(key)
        if logged_in?
          item = Item.order('id DESC').where( :key => key).first
          #remove file
          FileUtils.rm item.path, :force => true
          #remove db record
          Item.delete(item.id)
        end

        redirect Index
      end
    end

    class EditX
      def get(key)
        if key.index('.')
          #lookup item by name
          @item = Item.order('id DESC').where( :name => key).first
        else
          @item = Item.order('id DESC').where( :key => key).first
        end
        render :edit
      end

      def post(key)
        if key.index('.')
          #lookup item by name
          item = Item.order('id DESC').where( :name => key).first
        else
          item = Item.order('id DESC').where( :key => key).first
        end

        rename = false
        orig = "#{$config['upload_path']}/#{item.key}-#{item.name}"

        @errors = {}
        if item.key != input.shortKey
          if /^[a-zA-Z0-9._\-]*$/ =~ input.shortKey
            #need to validate shortkey
            checkItem = Item.order('id DESC').where( :key => input.shortKey).first
            if checkItem == nil
              item.key = input.shortKey
              rename = true
            else
              @errors['shortKey'] = 'Sorry that shortkey is already in use, please select a different one'
            end
          else
            @errors['shortKey'] = 'Please use only letters, numbers, dash and period.'
          end
        end

        if item.name != input.name
          if /^[a-zA-Z0-9._\-]*$/ =~ input.shortKey
            item.name = input.name
            rename = true
          else
            @errors['name'] = 'Please use only letters, numbers, dash and period.'
          end
        end

        #TODO: do discard changes
        if @errors.length != 0
          @item = item
          return render :edit
        end

        #no errors so let us update
        if rename
          new_name = "#{$config['upload_path']}/#{input.shortKey}-#{input.name}"
          item.path = new_name
          FileUtils.mv orig, new_name
        end

        #See if we were given a valid handler to use and if so, let us
        #update!
        classes = LuggageDisplays.constants.collect{ |c| LuggageDisplays.const_get(c) }

        classes.each do |c|
          if c.to_s == input.handler
            item.handler = input.handler
          end
        end

        item.save

        redirect ViewX, item.key

      end
    end

    #keeping this around since I've shared a few links with open
    class OpenX
      def get(key)
        redirect ViewX, key
      end
    end

    class ViewX
      
      def get(key)
        if key.index('.')

          #lookup item by name
          @item = Item.order('id DESC').where( :name => key).first
        else
          @item = Item.order('id DESC').where( :key => key).first
        end

        @item.views += 1
        @item.save

        #get handler class
        handlerClassName = @item.handler.split('::')[1]
        handlerClass =  LuggageDisplays.const_get(handlerClassName)

        #create handler and render
        if handlerClass == nil
          handlerClass = LuggageDisplays::Default
        end

        @handler = handlerClass.new(@item)
        @handlerHTML = @handler.get_html

        #set up nav links
        if logged_in?
          @nav_links = [
            { "text" => "Direct Link", "href" => @handler.get_direct_link },
            { "text" => "Edit","href" => R(EditX, @item.key) },
          ]
        else
          @nav_links = [
            { "text" => "Direct Link", "href" => @handler.get_direct_link },
          ]
        end

        render :view_file
      end
    end
  end

  module Views
    @auto_validation = false
    def layout
      assets_url = "#{$config['static_url']}/assets"
      text '<!DOCTYPE html>'
      html do
        head do
          title { "Luggage" }
          link :rel => "stylesheet", :href =>"#{assets_url}/css/bootstrap.min.css"
          link :rel => "stylesheet", :href =>"#{assets_url}/css/luggage.css"
        end
        body :style => "padding-top:60px" do
          topbar
          self << yield 
          script :type => "text/javascript", :src => "http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/bootstrap.min.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/luggage.js" do; end
        end
      end
    end

    def topbar
      div :class =>"navbar  navbar-fixed-top" do
        div :class => "navbar-inner" do
          div.container do
            a.brand $config['title'], :href => R(Index)
            ul.nav do
              if @nav_links == nil
              else
                @nav_links.each do |link|
                  li { a link['text'], :href => link['href'] }
                end
              end
            end
            ul :class => "nav pull-right" do
              if logged_in?
                li { a "Log out", :href => R(Logout) }
              else
                li { a "Log in", :href => R(Login) }
              end
            end
          end
        end
      end
    end

    def uploader
      div :class => "uploader" do
        div :class => "row post-form"
          div :class => "page-header" do
            h1 "Share something new"
          end
          form :id => "upload_form", :action => R(Upload), :method => "post", :enctype => "form/multipart" do
          div.span12 do
            div :id => "file_api" do
              div :id => "drag_area", :class => "alert alert-block alert-info" do
                p :class => "drag-upload" do
                  strong "Drag"
                  text " and "
                  strong "drop"
                  text " your files "
                  strong "here"
                  text " to upload!"
                end
                div :id => "upload_status" do
                  div :id=>"upload_status_text" do
                    "Ready to go!"
                  end
                  div :id=>"upload_status_bar", :style=>"display:none", :class => "progress progress-info progress-striped active" do
                    div.bar :id=>"upload_status_progress", :style=>"width:40%" do
                      " "
                    end
                  end
                  div :style=>"display:none", :id=>"upload_status_progress_text" do
                    "Upload in progress"
                  end
                end
              end
              div :class => "file-api-actions" do
                a "Use regular upload form", :href => "#", :id => "toggle_form"
              end
            end

            div :id => "fallback" do
              div.clearfix :id => "upload_input" do
                label "File Input", :for => "upload"
                div.input do
                  input :type => 'file', :name => 'upload', :id => 'upload'
                  span :class => "help-inline" do
                    "Please select a file to upload"
                  end
                end
              end
              div.actions do
                input :id => "upload_submit", :value => "Share File" ,:type => 'submit', :class => 'btn primary'
              end
            end
          end
        end
      end
    end

    def index
      if logged_in?
        div.container do
          uploader
        end
        div :class => "modal fade", :id => "confirm_remove" do
          div :class => "modal-header" do
            a :href => "#", :class => "close", "data-dismiss" => "modal" do
              "&times;"
            end
            h3 "Remove this file?"
          end
          div :class => "modal-body" do
            "Are you sure you want to remove this file? It will be removed completey from the system."
          end
          div :class => "modal-footer" do
            a :href => "#", :class => "confirm_button btn btn-primary" do
              "Remove"
            end
            a :href => "#", "data-dismiss" => "modal", :class => "cancel_button btn secondary" do
              "Cancel"
            end
          end
        end
      end
      div.container do
        list_files
      end
    end

    def login
      error = @login_error
      div.container do
        div.row
          div :class => "page-header" do
            h1 "Please login"
          end

          if error
            div :class => "alert-message error" do
              a.close :href => "#" do
                "&times;" 
              end
              p do
                strong "Oops!"
                text "It seems that you may have typed something incorrectly, please try again."
              end
            end
          end

          div.span12 do
          form :action => R(Login), :method => "post", :enctype => "form/multipart" do
            fieldset do
              div.clearfix do
                label "Username", :for => "username"
                div.input do
                  input.xlarge :type => 'text', :name => 'username'
                end
              end
              div.clearfix do
                label "Password", :for => "password"
                div.input do
                  input.xlarge :type => 'password', :name => 'password'
                end
              end
              div.actions do
                input :value => "Login" ,:type => 'submit', :class => 'btn primary'
              end
            end
          end
        end
      end
    end

    def logout
      p "Poof you're logged out"
    end
    
    def list_files
      i = 0
      page = @page
      if @files.empty?
        div.row do
          h1 "Shared files"
          div.span12 do
            table :class => "file-list table" do
              thead do
                tr do
                  th "File Name"
                  th "Views", :class => "views"
                  th "Uploaded On", :class => "uploaded"
                  if logged_in?
                    th "Remove", :class => "remove"
                  end
                end
              end
              tbody do
                tr do
                  td "No files are currently available", :style => "text-align:center", :id => "no_files", :colspan => 4 
                end
              end
            end
          end
        end
      else
        div.row do
          div :class => "page-header" do
            h1 "Shared files"
          end
          div.span12 do
            table :class => "file-list table" do
              thead do
                tr do
                  th "File Name"
                  th "Views", :class => "views"
                  th "Uploaded On", :class => "uploaded"
                  if logged_in?
                    th "Remove", :class => "remove"
                  end
                end
              end
              tbody do
                @files.each do |file|
                  url = R(ViewX, file.key)
                  tr do
                    td { a file.name, :href => url }
                    td file.views, :class => "views"
                    td relative_time(file.created_at), :class => "uploaded"
                    if logged_in?
                      td :class => "remove" do
                        a :href => R(RemoveX, file.key), :class => "confirm", "data-target" => "#confirm_remove", "data-toggle" => "modal" do
                          span :class => "icon-remove" do
                            " "
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            if @count > $config['items_per_page']
              div.pagination do
                ul do
                  li do
                    if @page == 1
                      a "< Previous", :class => "prev disabled"
                    else
                      a "< Previous", :class => "prev", :href => R(PageN, @page - 1)
                    end
                  end
                  until i * $config['items_per_page'] > @count do
                    i += 1
                    if i == @page
                      li :class => "active" do
                        a i, :href => R(PageN, i)
                      end
                    else
                      li do
                        a i, :href => R(PageN, i)
                      end
                    end
                  end
                  li do
                    if @page * $config['items_per_page'] >= @count
                      a "Next >", :class => "next disabled"
                    else
                      a "Next >", :class => "next", :href => R(PageN, @page + 1)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    def edit_form(buttons=nil)
      name_error = ""
      key_error = ""
      if @errors == nil
        @errors = {}
      else
        if @errors['name']
          name_error = "error"
        end

        if @errors['shortKey']
          key_error = "error"
        end
      end

      form :action => R(EditX, @item.key), :method => 'post', :class => "form-horizontal" do
        fieldset do
          div :class => "control-group " + name_error do
            label  "Name", :for => "name", :class => "control-label"
            div.controls do
              input :class => "xlarge " + name_error, :name => "name", :size => 30, :type => "text", :value => @item.name
              span :class => "help-inline" do
                @errors['name']
              end
            end
          end
          div :class => "control-group " + key_error do
            label "Short Key", :for => "shortKey", :class => "control-label"
            div.controls do
              input :class => "xlarge " + key_error, :name => "shortKey", :size => 30, :type => "text", :value => @item.key
              span :class => "help-inline" do
                @errors['shortKey']
              end
            end
          end
          div :class => "control-group" do
            label "Handler", :for => "handler" , :class => "control-label"
            div.controls do
              select :class => "xlarge", :name => "handler" do
                classes = LuggageDisplays.constants.collect{ |c| LuggageDisplays.const_get(c) }
                classes.each do |c|
                  if c.to_s == @item.handler
                    option :selected => 1 do
                      c
                    end
                  else
                    option c
                  end
                end
              end
              span :class => "help-inline" do
                "Please select a handler"
              end
            end
          end
        end
        if buttons != nil
          div :class => "form-actions" do
            button :class => 'btn btn-secondary' do
              "Cancel"
            end
            text " "
            input :type=>"submit", :value => "Save Changes", :id => "edit_submit", :class => 'btn btn-primary'
          end
        end
      end
    end

    def edit
      div.container do
        div.row do
          div :class => "page-header" do
            h1 "Update #{@item.name}"
          end
          div.span12 do
            edit_form true
          end
        end
      end
    end

    def view_file
      div.content do
        @handlerHTML
      end
      if logged_in?
        div :class => "modal hide fade", :id => "edit_form" do
          div :class => "modal-header" do
            a :href => "#", :class => "close", "data-dismiss" => "modal" do
              "&times;"
            end
            h3 "File Settings"
          end
          div :class => "modal-body" do
            edit_form
          end
          div :class => "modal-footer" do
            a :href => "#", :id => "edit_save", :class => "btn btn-primary" do
              "Update"
            end
            a :href => "#", :class => "cancel_button btn btn-secondary" do
              "Cancel"
            end
          end
        end
      end
    end
  end

  module Helpers
    def form(*)
      super do
        self << Rack::Csrf.tag(@env)
        yield
      end
    end

    def logged_in?
      !!@state.user_id
    end

    def require_login!
      unless logged_in?
        redirect Controllers::Index
        throw :halt
      end
    end

    #borrowed from http://stackoverflow.com/questions/195740/how-do-you-do-relative-time-in-rails
    #added .round so the numbers are nice
    def relative_time(start_time)
      diff_seconds = Time.now - start_time
      case diff_seconds
        when 0 .. 59
          "#{diff_seconds.round} seconds ago"
        when 60 .. (3600-1)
          "#{(diff_seconds/60).round} minutes ago"
        when 3600 .. (3600*24-1)
          "#{(diff_seconds/3600).round} hours ago"
        when (3600*24) .. (3600*24*30) 
          "#{(diff_seconds/(3600*24)).round} days ago"
        else
          start_time.strftime("%m/%d/%Y")
      end
    end

  end

end

def Luggage.create
  if $config['adapter'] == 'sqlite3'
    Camping::Models::Base.establish_connection(
     :adapter => $config['db_adapter'],
     :database => $config['db_name'])
  else
    Camping::Models::Base.establish_connection(
     :adapter => $config['db_adapter'],
     :database => $config['db_name'],
     :host => $config['db_host'],
     :username => $config['db_username'],
     :password => $config['db_password'])
  end
  Luggage::Models.create_schema :assume => (Luggage::Models::Item.table_exists? ? 1.0 : 0.0)
end
