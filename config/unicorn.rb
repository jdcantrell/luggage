# This more or less the sample configuration file for Unicorn, the
# things you'll want to change for you server are
#
# /working/dir
# /unicorn/sockets
# /unicorn/pids
# /luggage/logs
#
# I use fabric to take care of that.

worker_processes 1

working_directory "/working/dir/"

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/unicorn/sockets/luggage.sock", :backlog => 64
#listen 8080, :tcp_nopush => true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "/unicorn/pids/luggage.pid"

stderr_path "/luggage/logs/luggage.stderr.log"
stdout_path "/luggage/logs/luggage.stdout.log"

preload_app true

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
end

after_fork do |server, worker|
end
