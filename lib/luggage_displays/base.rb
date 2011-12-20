require 'markaby'

#required for markdown view
require 'kramdown'

#required for source view
require 'albino'

module LuggageDisplays
  class Default
    HANDLES = {}

    def initialize(item)
      @item = item
    end

    #TODO: see if we can't remove one of these...
    def get_web_path(path)
      path.sub( $config['upload_path'], $config['static_url'])
    end

    def get_direct_link
      get_web_path(@item.path)
    end

    #this method may not be needed, putting it up for deletion
    #I was thinking the markdown/source classes would use it. They could
    #still use, but as of now they are generating based when a file is
    #viewed.
    def process
      #no processing needed for the default case
      #since we'll only give them a download link
    end

    #this should be the main function extended in children classes. It
    #is the one responsible for generating the html based of the
    #handler.
    def generate_html(item)
      @markaby.p do
        span "You can download "
        b "#{item.name} " 
        a "right here", :href => item.path
        span "."

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
    HANDLES  = {".jpg" => 1, ".png" => 1}

    def generate_html(item)
      img_src = get_web_path(item.path)

      @markaby.div.image do
        img :src => img_src
      end
    end
  end

  #Markdown and Source both have two tabs, one for pretty output and
  #another for the raw source
  #TODO: Have Markdown handle {% highglight python %}{% endhighlight %}
  #style tags and use Albino for the output
  class Markdown < Default
    HANDLES  = {".md" => 1, ".markdown" => 1}

    def parse_contents(contents)
      Kramdown::Document.new(contents).to_html
    end

    def generate_html(item)
      #get source text
      source = File.open(item.path, "r")
      contents = source.read

      #if we have a cached file use that
      if File.exists?("#{$config['upload_path']}/cache/#{item.key}")
        parsed = File.open("#{$config['upload_path']}/cache/#{item.key}", "r")
        html = parsed.read
      else
        #else generate file
        html = parse_contents(contents)
        parsed = File.new("#{$config['upload_path']}/cache/#{item.key}", "w")
        parsed.write(html)
      end

      @markaby.div.container do
        ul :class => "tabs view-tabs" do
          li.active do
            a item.name, :href => '#output'
          end
          li do
            a "Source", :href => '#source'
          end
        end
        div :class => "tab-content" do
          div :id => "output", :class => "active" do
            html
          end
          div :id => "source" do
            pre contents
          end
        end
      end
    end
  end

  class Source < Markdown
    HANDLES  = {".php" => 'php', ".py" => 'python', '.rb' => 'ruby',
      '.html' => 'html', '.css' => 'css', '.js' => "javascript", 
      '.c'=> 'c', '.cpp' => 'cpp'}

    def parse_contents(contents)
      syntaxer = Albino.new(contents, Source::HANDLES[@item.filetype])
      syntaxer.colorize( :O => "linenos=True,bg=light")
    end
  end
end
