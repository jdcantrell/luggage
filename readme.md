#Why?
Luggage is designed to be a simple script that provides similar
functionality to cloud.app. It basically allows you to drag and drop
files on to the web page so that you can share them with friends and
all. 

I originally started this as a way to dip my toes in to Ruby
development. I also have done this as a chance to play with the new
javascript File.API available in Chrome and Firefox. 

#Required software
You will need:
* Ruby and Ruby Gems

Here is the quick and dirty way to get going:

`gem install camping-omnibus bcrypt-ruby kramdown`

Once you have done that download or clone the luggage repository and
fire up a text editor modify config.yml to any reasonable value you can
think of.  password\_hash is your bcrypted password. You can run the
included hash.rb file: `ruby hash.rb` to generate the correct hash
string. 

You can test out luggage locally by modifying config.yml and then by
running `camping luggage.rb` and then starting another web server in the
same directory to serve out static files (Personally I use `python -m
SimpleHTTPServer 40001`)

#Gettings things on the web
The two things I use to serve luggage is nginx with a proxy to unicorn.
The settings are pretty standard, set up nginx to use unicorn as in the
[example](http://unicorn.bogomips.org/examples/nginx.conf) given from
the unicorn website. And for your unicorn.rb file you can use the
[example](http://unicorn.bogomips.org/examples/unicorn.conf.rb) on the
unicorn site, just be sure to remove the lines pertaining to
ActiveRecord in the functions before_fork and after_fork.

Luggage does not have any code for dealing with static files (ie the
files you uploaded) because this is not something camping has built in.
For this reason luggage relies on a STATIC_URL in the config file this
should point to a virtual server that will then serve the files for you
(on my site this is static.goodrobot.net).

#Other things?
You can access files by either going open/key or open/filename. In the
case of filename, luggage will display the most recently uploaded file
matching the given filename.

I opted to not make this app multi-user, instead going for a single-user
web app. Which, turns out, is a little bit of a strange concept. This is
the reason why you store your username and password hash in the yaml
file. So I recommend you be smart about that, if your server is accessed
by anyone else they will be able to get that username and hash if they
can read config.yml file, for whatever that is worth to them. 

The repo contains a demo fabfile.py for deploying, you will probably
need to modify it to suit your needs.

Some of this code may not be 100% awesome. But it works, which is 100%
awesome.

#Roadmap
* Enhance syntax colors
* Demo branch

* Make site work with javascript off (because it should be easy)

* Make user sessions optionally last for a 30days instead of a year?
* Caching example: http://snippets.dzone.com/posts/show/4988
* Look into how camping's state works, is it secure enough to store
  user session info? I'd think so given their examples, but it is worth
  knowing

#Full list of software/code that is used in this project
* Ruby with camping, kramdown, bcrypt-ruby
* [Twitter Bootstrap](http://twitter.github.com/bootstrap/)
* [google-code-prettify](http://code.google.com/p/google-code-prettify/)
* [jQuery](http://jquery.com/)
