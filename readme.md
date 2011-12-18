#Why?

Luggage is designed to be a simple script that provides similar
functionality to cloud.app. It basically allows you to drag and drop
files on to the web page so that you can share them with friends and
all. 

I originally started this as a way to dip my toes in to Ruby
development. I also have done this as a chance to play with the new
javascript File.API available in Chrome and Firefox. 

It also solves a frustration of mine that, while cloud.app's user
experience is very good, the cost for what is delivered is not that
great. However, take that from someone who already pays for a webserver,
knows how to code, and does *not* pay for cloud.app currently. 

#Required software
You will need:
* Ruby and Ruby Gems

Here is the quick and dirty way to get going:

`gem install camping-omnibus bcrypt-ruby`

Once you have done that download or clone the luggage repository and
fire up your vim (or whatever poor excuse for an editor you're using)
and modify .init\_env\_vars.sh to any reasonable value you can think of.
LUGGAGE\_HASH is your bcrypted password (TODO: demonstrate this further)


#Okay how do we do it?

One sad side affect of going with Camping as the main framework is that
I also chose not to implement a static file controller. Instead I opted
to have a virtual server handle serving static files while another
virtual server handles running camping. So here is the basic setup that
I have going:

* TODO: how the heck do I setup camping on nginx
* TODO: show the static virtual server config

#Other things?
You can access files by either going open/key or open/filename. In the
case of filename, luggage will display the most recently uploaded file
matching the given filename.

I opted to not make this app multi-user, instead going for a single-user
web app. Which, turns out, is a little bit of a strange concept. This is
the reason why you setup your username and password in environment
variables. So I recommend you be smart about that, if your server is
accessed by anyone else they will be able to get that username and hash,
for whatever that is worth to them. 

#Roadmap
* make sure all controllers are working
* implement login stuff
* Do we need open/ or can we just get away with open/item
* Should non-logged in users see / as a the file list? (I am leaning
  towards yes at this point in time.
* File.API
* Make it look nice (probably twitter bootstrap initially)
