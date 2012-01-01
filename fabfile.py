from __future__ import with_statement
from fabric.api import local, run, cd, settings, sudo
from fabric.decorators import hosts
from fabric.colors import green, blue, red
from fabric.contrib.files import sed, exists
from time import sleep

code_dir = "/path/to/luggage"
static_dir = "/path/to/static/luggage"
pid = "/path/to/unicorn/pids/luggage.pid"
log_dir = "/path/to/unicorn/logs"
unicorn_dir = "/path/to/unicorn"

def deploy():
  if not exists(code_dir):
    run("git clone https://github.com/jdcantrell/luggage.git %s" % code_dir)

  with cd(code_dir):
    #reset and update
    run ("git reset --hard");
    run ("git clean -f");
    run ("git pull");

    #update config/unicorn.rb to use the correct paths
    sed("%s/config/unicorn.rb" % code_dir, "/working/dir", code_dir)
    sed("%s/config/unicorn.rb" % code_dir, "/unicorn/sockets", unicorn_dir)
    sed("%s/config/unicorn.rb" % code_dir, "/unicorn/pids", unicorn_dir)
    sed("%s/config/unicorn.rb" % code_dir, "/luggage/logs", log_dir)

    #move config files where unicorn doesn't have a fit
    run("mv %s/config/* %s" % (code_dir, code_dir))

    #update config.yml
    sed("%s/config.yml" % code_dir, "STATIC_URL", "http://STATIC.YOURURL.COM/WHEREVER")
    sed("%s/config.yml" % code_dir, "USERNAME", "USERNAME")
    sed("%s/config.yml" % code_dir, "PASSWORD_HASH", "PASSWORD_HASH")
    sed("%s/config.yml" % code_dir, "UPLOAD_PATH", "%s/uploads" % static_dir)
    sed("%s/config.yml" % code_dir, "luggage.db", "/path/to/sqlite3/dbs/luggage.db")

    #ln assets and uploads to static directory
    if not exists(static_dir):
      sudo("mkdir -p %s" % static_dir)
      sudo("mkdir -p %s/uploads" % static_dir)
      sudo("mkdir -p %s/uploads/cache" % static_dir)
      sudo("chown -R YOUR_USER %s" % static_dir)
      sudo("ln -s %s/assets %s/assets" % (code_dir, static_dir))

    restart()

def restart():
  with settings(warn_only=True):
    #FIXME: pid file may exist but not have a running process
    if exists(pid):
      print(blue("Restarting unicorn", True))
      run("kill -USR2 `cat %s`" % pid)

      while not exists("%s.oldbin" % pid):
        print(red("Waiting for new unicorn...", True))
        sleep(.5)

      print(blue("Killing an old unicorn...", True))
      run("kill `cat %s.oldbin`" % pid)
    else:
      print(blue("Starting unicorn", True))
      run ("unicorn -c %s/config/unicorn.rb" % code_dir)

    print(blue("Unicorn is up", True))
