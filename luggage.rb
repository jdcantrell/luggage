require 'camping'
require 'camping/ar'
require 'camping/session'

#
require 'bcrypt'
require 'fileutils'



Camping.goes :Luggage

module Luggage
  include Camping::Session

  module Models
    class Item < Base
    end

    class BasicFields < V 1.0
      def self.up
        create_table :luggage_items do |t|
          t.string   :key
          t.string   :name
          t.string   :path
          t.string   :filetype
          t.int      :views
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
        @input = input.upload

        #this reads our file - need to copy file to permanent location
        #FileUtils.cp input.upload[:tempfile].read
        #generate uniqe filename
        #filename will be in this structure:
        #uniqIdentifier-orginialName.ext
        #copy file to LUGGAGE_STORE_DIR
        #create new item for database
        #returns json if ajax: true
        #else redirect to Open/filename
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
      def get(everything)
        render :view_file
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
        "We should so the file list if you're logged in, otherwise let us show something different, not sure what yet"
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
        "this is your specific file view"
        @input
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
