require 'markaby'

#required for markdown view
require 'kramdown'

module LuggageDisplays
  class Default
    HANDLES = {}

    def initialize(item)
      @item = item
    end

    #TODO: see if we can't remove one of these...
    def get_web_path(path)
      path.sub( $config['upload_path'], "#{$config['static_url']}/uploads")
    end

    def get_direct_link
      get_web_path(@item.path)
    end

    #this gets called when the item is uploaded, allows the display to
    #do things like, convert markdown to html and cache the copy, etc
    def process
      #no processing needed for the default case
      #since we'll only give them a download link
    end

    #this is called when an item is removed from the database, it gives
    #the class a chance to remove any cached files or do any required
    #cleanup (this may get called on a file move too)
    def remove
    end

    #this should be the main function extended in children classes. It
    #is the one responsible for generating the html based of the
    #handler.
    def generate_html(item)
      file = get_web_path item.path
      @markaby.p do
        div.container do
          div.span12 do
            div :class => "alert alert-block alert-info" do
              p :class => "download" do
                text "You may download #{item.name} " 
                a "right here", :href => file
                text "."
              end
            end
          end
        end
      end
    end

    #Called in Luggage::Views::view_file
    def get_html
      @markaby = Markaby::Builder.new
      #We pass item in here, because once we're inside the markaby
      #object we no longer are in our object, so our class vars need to
      #be local vars for easy access
      generate_html @item
      @markaby.to_s
    end
  end

  #Small class to handle displaying image files
  #TODO: decide if we should convert from png, bmp, etc => jpg
  class Images < Default
    HANDLES  = {".jpg" => 1, ".png" => 1, ".gif" => 1}

    def generate_html(item)
      img_src = get_web_path item.path

      @markaby.div.image do
        img :src => img_src
      end
    end
  end

  #Source view has two tabs, one for a pretty version of the source and
  #another for the raw text 
  #Don't really need the second tab when we use prettify, but whatevs
  class Source < Default
    HANDLES  = {".php" => 'php', ".py" => 'python', '.rb' => 'ruby',
      '.html' => 'html', '.css' => 'css', '.js' => "javascript", 
      '.c'=> 'c', '.cpp' => 'cpp'}

    def generate_html(item)
      #get source text
      source = File.open(item.path, "r")
      contents = source.read
      source.close

      ext = item.filetype.sub '.', ''

      @markaby.div.container do
        link :rel => "stylesheet", :href =>"#{$config['static_url']}/assets/css/prettify.css"
        ul :class => "nav nav-tabs" do
          li.active do
            a item.name, :href => '#output', "data-toggle" => "tab"
          end
          li do
            a "Raw", :href => '#source', "data-toggle" => "tab" 
          end
        end
        div :class => "tab-content" do
          div :id => "output", :class => "tab-pane active" do
            pre contents, :class => "prettyprint linenums lang-#{ext}"
          end
          div :id => "source", :class => "tab-pane"  do
            pre contents
          end
        end
        script :type => "text/javascript", :src => "#{$config['static_url']}/assets/js/prettify.js" do; end
      end
    end
  end

  #TODO: replace {% highlight python %} tags and use prettify
  class Markdown < Default
    HANDLES  = {".md" => 1, ".markdown" => 1}

    def parse_contents(contents)
      Kramdown::Document.new(contents).to_html
    end

    def process
      #get source text
      source = File.open(@item.path, "r")
      contents = source.read
      source.close

      #else generate file
      html = parse_contents(contents)
      parsed = File.new("#{$config['upload_path']}/cache/#{@item.key}", "w")
      parsed.write(html)
      parsed.close
    end

    def generate_html(item)
      #get source text
      source = File.open(item.path, "r")
      contents = source.read
      source.close

      if not File.exists?("#{$config['upload_path']}/cache/#{item.key}")
        self.process
      end

      parsed = File.open("#{$config['upload_path']}/cache/#{item.key}", "r")
      html = parsed.read
      parsed.close

      @markaby.div.container do
        link :rel => "stylesheet", :href =>"#{$config['static_url']}/assets/css/prettify.css"
        ul :class => "nav nav-tabs" do
          li.active do
            a item.name, :href => '#output', "data-toggle" => "tab"
          end
          li do
            a "Source", :href => '#source', "data-toggle" => "tab"
          end
        end
        div :class => "tab-content" do
          div :id => "output", :class => "tab-pane active" do
            html
          end
          div :id => "source", :class => "tab-pane" do
            pre contents
          end
        end
        script :type => "text/javascript", :src => "#{$config['static_url']}/assets/js/prettify.js" do; end
      end
    end
  end
end
