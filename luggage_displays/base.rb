require 'markaby'

module LuggageDisplays
  class Default
    HANDLES = {}

    def initialize(item)
      @item = item
    end

    def get_web_path(path)
      path.sub( $config['upload_path'], $config['static_url'])
    end

    def process
      #no processing needed for the default case
      #since we'll only give them a download link
    end

    def get_direct_link
      get_web_path(@item.path)
    end

    def generate_html(item)
      @markaby.p do
        span "You can download "
        b "#{item.name} " 
        a "right here", :href => item.path
        span "."

      end
    end

    def get_html
      @markaby = Markaby::Builder.new
      #We pass item in here, because once we're inside the markaby
      #object we no longer are in our object, so our class vars need to
      #be local vars for easy access
      generate_html @item
      @markaby.to_s
    end
  end

  class Images < Default
    HANDLES  = {".jpg" => 1, ".png" => 1}

    def generate_html(item)
      img_src = get_web_path(item.path)

      @markaby.div :style => "text-align:center" do
        img :src => img_src
      end
    end
  end

  
  class Markdown < Default
    HANDLES  = {".md" => 1, ".markdown" => 1}
  end

  class Html < Default
    HANDLES  = {".html" => 1, ".txt" => 1}
  end

end
