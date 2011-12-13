module LuggageDisplays

  class Default
    HANDLES = {}

    def process(item)
      #no processing needed for the default case
      #since we'll only give them a download link
    end

    def display(item)
      p do
        "We currently have no fancy way of displaying this file, so here is a"
        a :href => item.path do
          "link"
        end
      end
    end
  end

  class Images
    HANDLES  = {".jpg" => 1, ".png" => 1}

    def process(item)
      #things we need to do immediately after upload
      #suche as resize/convert to jpg, etc
    end

    def display(item)
      #return any html needed for displaying this
      #filetype
      img :src => filename
    end
  end

  class Markdown
    HANDLES  = {".md" => 1, ".markdown" => 1}

    def process(item)
      #things we need to do immediately after upload
      #such as resize/convert to jpg, etc
    end

    def display(item)
      #return any html needed for displaying this
      #filetype
    end
  end

  class Html
    HANDLES  = {".html" => 1, ".txt" => 1}

    def process(item)
      #things we need to do immediately after upload
      #such as resize/convert to jpg, etc
    end

    def display(item)
      #return any html needed for displaying this
      #filetype
    end
  end

end
