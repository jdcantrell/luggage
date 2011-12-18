require 'camping'
require 'camping/ar'
require 'camping/session'

#Custom requirements
require 'bcrypt'
require 'fileutils'
require 'logger'

#Here are our custom displays
require './luggage_displays/base'

Camping.goes :Luggage

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
        render :index
      end
    end

    class Login
      def get
        render :login
      end

      def post
        #TODO: make this do something useful
        @password = Password.new(ENV['LUGGAGE_HASH'])
        if ENV['LUGGAGE_USER'] == input.username and @password == input.password
          @state.user_id = 1
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
        dir = ENV['LUGGAGE_UPLOAD_PATH']
        path = "#{dir}/#{key}-#{filename}"
        FileUtils.cp temp, path

        #find an appropriate handler
        handlerClass = nil
        classes = LuggageDisplays.constants.collect{ |c| LuggageDisplays.const_get(c) }
        puts "Looking for handler for #{extension}"

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
        handler = handlerClass.new
        handler.process item
        @item = item
        #returns json if ajax: true

        #else redirect to Open/filename
        #TODO: Redirect!
        render :view_file
      end
    end

    class Open
      def get
        #require_login!
        render :list_files
      end
    end

    class OpenX
      
      def get(key)
        if key.index('.')
          #debug
          ActiveRecord::Base.logger = Logger.new(STDOUT)

          #lookup item by name
          item = Item.order('id DESC').where( :name => key).first

          #get handler class
          handlerClassName = item.handler.split('::')[1]
          handlerClass =  LuggageDisplays.const_get(handlerClassName)

          #create handler and render
          if handlerClass == nil
            handlerClass = LuggageDisplays::Default
          end

          @handler = handlerClass.new(item)
          render @handler.display
        end
      end
    end
  end

  module Views
    def layout
      html do
        head do
          title { "Luggage" }
        end
        body {self << yield }
      end
    end

    def uploader
      div :class => "uploader" do
        form :action => "/upload/", :method => "post", :enctype => "form/multipart" do
          input :type => 'file', :name => 'upload'
          input :type => 'submit'
        end
      end
    end

    def index
      uploader()
      p do
        "We should show the file list if you're logged in, otherwise let us show something different, not sure what yet"
      end
    end

    def login
      p "This is not yet ready!"
    end

    def logout
      p "Poof you're logged out"
    end
    
    def list_files
      p "there will be files here"
    end

    def view_file
      p do
        @handler.display @item
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
