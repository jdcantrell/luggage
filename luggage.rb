Camping.goes :Luggage

module Luggage::Models
  class Item < Base
    belongs_to :user 
  end

  class User < Base 
    has_many :items 
  end

  class BasicFields < V 1.0
    def self.up
      create_table Item.table_name do |t|
        t.string   :key
        t.string   :name
        t.string   :path
        t.string   :filetype
        t.timestamps
      end

      create_table User.table_name do |t|
        t.int      :user_id
        t.string   :name
      end
    end

    def self.down
     drop_table Item.table_name
     drop_table User.table_name
    end
  end


end


module Luggage::Controllers
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
  end 

  class Logout
    def get
      render :login
    end
  end

  class Files
    def get
      render :files
    end
  end

  class FilesX
    def get(everything)
      render :view_file
    end
  end
end

module Luggage::Views
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
