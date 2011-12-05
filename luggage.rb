require 'camping'
require 'camping/ar'
require 'camping/session'

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
        @time = Time.now
        render :sundial
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

    class Files
      def get
        require_login!
        render :files
      end
    end

    class FilesX
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

    def sundial
      p "The current time is #{@time}"
    end

    def login
      p "This is not yet ready!"
    end

    def logout
      p "Poof you're logged out"
    end
    
    def files
      p "there will be files here"
    end

    def view_file
      p "this is your specific file view"
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
