#Caching example: http://snippets.dzone.com/posts/show/4988

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
        @files = Item.order('created_at DESC').limit(20)
        render :index
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
        temp = input.upload[:tempfile].path()

        #Setup item details

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
        redirect OpenX, item.name
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
            { "text" => "Edit", "href" => '#edit' },
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
      assets_url = $config['assets_url']
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
          script :type => "text/javascript", :src => "#{assets_url}/js/luggage.js" do; end
        end
      end
    end

    def topbar
      div.topbar do
        div :class => "topbar-inner" do
          div.container do
            a.brand "Luggage", :href => '/'
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
        div.row
          div :class => "page-header" do
            h1 "Share something new"
          end
          div.span16 do
          form :action => "/upload/", :method => "post", :enctype => "form/multipart" do
            div.clearfix do
              label "File Input", :for => "upload"
              div.input do
                input :type => 'file', :name => 'upload'
                input :value => "Share File" ,:type => 'submit', :class => 'btn primary'
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
          form :action => "/login/", :method => "post", :enctype => "form/multipart" do
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
      if @files.empty?
        h2 "Nothing uploaded!"
      else
        div.row do
          div :class => "page-header" do
            h1 "Your previously shared files"
          end
          div.span16 do
            table do
              thead do
                tr do
                  th "File Name"
                  th "Views"
                  th "Uploaded On"
                end
              end
              tbody do
                @files.each do |file|
                  url = R(OpenX, file.key)
                  tr do
                    td { a file.name, :href => url }
                    td file.views
                    td file.created_at
                  end
                end
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
    end
  end

  module Helpers
    def logged_in?
      !!@state.user_id
    end

    def require_login!
      unless logged_in?
        redirect Controllers::Login
        throw :halt
      end
    end
  end

end

def Luggage.create
  Luggage::Models.create_schema :assume => (Luggage::Models::Item.table_exists? ? 1.0 : 0.0)
end
