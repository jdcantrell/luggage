#Our camping items
require 'camping'
require 'camping/ar'
require 'camping/session'

#Custom requirements
require 'bcrypt'
require 'fileutils'
require 'yaml'

#Here are our custom displays
require './lib/luggage_displays/base'

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDOUT)

Camping.goes :Luggage

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
        @files = Item.order('created_at DESC').limit($config['items_per_page'])
        @count = Item.count()
        @page = 1
        render :index
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
        #TODO: make this do something useful
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
        key = Time.now.to_i.to_s(36)

        filename = input.upload[:filename]
        extension = File.extname(filename)
        dir = $config['upload_path']
        path = "#{dir}/#{key}-#{filename}"
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

        #else redirect to Open/filename
        #TODO: Redirect!
        if input.json
          item.to_json
        else
          redirect OpenX, item.name
        end
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
          @item = Item.order('id DESC').where( :name => key).first
        else
          @item = Item.order('id DESC').where( :key => key).first
        end

        # if key or name is different
        # mv file to key-name
        # save item
        # redirect to OpenX with key
      end
    end

    class OpenX
      
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
            { "text" => "Edit","href" => URL(EditX, @item.key) },
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
    def layout
      assets_url = "#{$config['static_url']}/assets"
      text '<!DOCTYPE html>'
      html do
        head do
          title { "Luggage" }
          link :rel => "stylesheet", :href =>"#{assets_url}/css/bootstrap.css"
          link :rel => "stylesheet", :href =>"#{assets_url}/css/luggage.css"
          link :rel => "stylesheet", :href =>"#{assets_url}/css/default.css"
        end
        body :style => "padding-top:60px" do
          topbar
          self << yield 
          script :type => "text/javascript", :src => "http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/bootstrap-modal.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/bootstrap-tabs.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/bootstrap-alerts.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/bootstrap-buttons.js" do; end
          script :type => "text/javascript", :src => "#{assets_url}/js/luggage.js" do; end
        end
      end
    end

    def topbar
      div.topbar do
        div :class => "topbar-inner" do
          div.container do
            a.brand $config['title'], :href => URL(Index)
            ul.nav do
              if @nav_links == nil
              else
                @nav_links.each do |link|
                  li { a link['text'], :href => link['href'] }
                end
              end
            end
            ul :class => "nav secondary-nav" do
              if logged_in?
                li { a "Log out", :href => URL(Logout) }
              else
                li { a "Log in", :href => URL(Login) }
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
          form :id => "upload_form", :action => URL(Upload), :method => "post", :enctype => "form/multipart" do
          div.span16 do
            div :id => "file_api" do
              div :id => "drag_area", :class => "alert-message block-message info" do
                p :class => "drag-upload" do
                  strong "Drag"
                  text " and "
                  strong "drop"
                  text " your files "
                  strong "here"
                  text " to upload!"
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
                "x" 
              end
              p do
                strong "Oops!"
                text "It seems that you may have typed something incorrectly, please try again."
              end
            end
          end

          div.span16 do
          form :action => URL(Login), :method => "post", :enctype => "form/multipart" do
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
      puts "PAGER"
      puts page
      if @files.empty?
        h2 "Nothing uploaded!"
      else
        div.row do
          div :class => "page-header" do
            h1 "Your previously shared files"
          end
          div.span16 do
            table :class => "file-list" do
              thead do
                tr do
                  th "File Name"
                  th "Views"
                  th "Uploaded On"
                end
              end
              tbody do
                @files.each do |file|
                  url = URL(OpenX, file.key)
                  tr do
                    td { a file.name, :href => url }
                    td file.views
                    td file.created_at
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
                      puts "Prev"
                      puts @page
                      a "< Previous", :class => "prev", :href => URL(PageN, @page - 1)
                    end
                  end
                  until i * $config['items_per_page'] > @count do
                    i += 1
                    if i == @page
                      li :class => "active" do
                        a i, :href => URL(PageN, i)
                      end
                    else
                      li do
                        a i, :href => URL(PageN, i)
                      end
                    end
                  end
                  li do
                    if @page * $config['items_per_page'] >= @count
                      a "Next >", :class => "next disabled"
                    else
                      a "Next >", :class => "next", :href => URL(PageN, @page + 1)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    def edit_form
      form do
        fieldset do
          div.clearfix do
            label  "Name", :for => "name"
            div.input do
              input :class => "xlarge", :name => "name", :size => 30, :type => "text", :value => @item.name
              span :class => "help-inline" do
                "Please enter a name"
              end
            end
          end
          div.clearfix do
            label "Short Key", :for => "shortKey" 
            div.input do
              input :class => "xlarge", :name => "shortKey", :size => 30, :type => "text", :value => @item.key
              span :class => "help-inline" do
                "Please enter a key"
              end
            end
          end
          div.clearfix do
            label "Handler", :for => "handler" 
            div.input do
              select :class => "xlarge", :name => "handler" do
                classes = LuggageDisplays.constants.collect{ |c| LuggageDisplays.const_get(c) }
                puts @item.handler
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
      end
    end

    def edit
      div.container do
        div.row do
          div :class => "page-header" do
            h1 "Update #{@item.name}"
          end
          div.span16 do
            edit_form
            div.actions do
              button :id => "edit_submit", :class => 'btn primary' do
                "Save Changes"
              end
              text " "
              button :class => 'btn secondary' do
                "Cancel"
              end
            end
          end
        end
      end
    end

    def view_file
      div.content do
        @handlerHTML
      end
      if logged_in?
        div.hide do 
          div :class => "modal hide fade", :id => "edit_form" do
            div :class => "modal-header" do
              a :href => "#", :class => "close" do
                "&times;"
              end
              h3 "File Settings"
            end
            div :class => "modal-body" do
              edit_form
            end
            div :class => "modal-footer" do
              a :href => "#", :id => "edit_save", :class => "btn primary" do
                "Update"
              end
              a :href => "#", :class => "btn secondary" do
                "Cancel"
              end
            end
          end
        end
      end
    end
  end

  module Helpers
    def logged_in?
      !!@state.user_id
    end

    def require_login!
      unless logged_in?
        redirect Controllers::Index
        throw :halt
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
