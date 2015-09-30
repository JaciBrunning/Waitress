# Waitress

[![Join the chat at https://gitter.im/JacisNonsense/Waitress](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JacisNonsense/Waitress?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
Waitress is a lightweight Ruby Web Server with support for dynamic pages,
virtual hosts, library management and much more. Waitress remains quick to
deliver by using C Native Extensions from both the [Mongrel HTTP Parser](https://github.com/mongrel/mongrel)
and those crafted specifically for the Waitress Server.

Waitress is known to be compatible on Mac and Linux systems, but will not
function on non-POSIX thread model systems (Windows)

## Getting Started
Getting started is very simple. First, install the gem:
```
gem install waitress-core
```

To get a server up and running, simply run ``` waitress ``` in any command shell. The
server instance will be running under ``` ~/.waitress ```

If you want to embed Waitress in your application, you can do so using the following
example:

```ruby
require 'waitress'

server = Waitress.serve!                    # Create a new Waitress Server instance
vhost = Waitress::Vhost.new /.*/            # Create a VHost listening on any domain
server << vhost

vhost << Waitress::Handler.new(/.*/i, 100) do      # Create a simple handler responding to any URL
  file_ext ".html"
  println "<h1> Hello World! </h1>"
end

server.run(2910).join                       # Run the server on port 2910
```

## What does it do?
When running from the command line, Waitress sets itself up in the ``` ~/.waitress/www ``` directory (this can be changed with the -h switch). The ``` config.rb ``` file contains all the setup for your server. This file runs regular Ruby code responsible for setting up your server. A default template is seen below:
```ruby
# This is the configuration for your waitress server, accepting connections on port '2910'
Waitress.configure!(2910) do |w|

  # You can run regular Ruby Code in here, too!
  @home = "~/.waitress/www/"
  def fl file
    File.join(@home, file)
  end

  # This is your other Virtual Host, accepting connections to any domain.
  # The '0' represents the priority, with the default being 50. Higher priority
  # Hosts will be chosen if the request matches multiple Hosts.
  w.host(/.*/, 0) do |host|
    # This is where your public documents and pages are stored
    host.root fl("main/http")
    # This is where your non-public includes are stored
    host.includes fl("main/rb")

    # This will show up when a 404 error occurs
    host.set_404 fl("main/http/404.html")

    # Want to rewrite a URL? No problem.
    host.rewrite /some_url/, "some_other_url"
    host.rewrite /capture_group_(\d)/, "capture/group\\1"

    # Bind_Lib will allow you to automatically import lib tags into .wrb files
    # Before they are sent to the client.
    host.bind_lib /jquery.*/, :js, "jquery"
    host.bind_lib /boostrap.*/, :css, "bootstrap"

    # Use combos to chain together libraries into a collection
    host.combo "all-lib", "jquery", "bootstrap"

    # Change this to change where you store your libraries
    host.libdir fl("libs")

    # Change this to choose what URI the libraries are linked
    # to (yoursite.com/libraries/library_name)
    host.liburi "libraries"
  end

end
```

In this config file, your Libraries are stored under ``` libs/ ```, and your public HTML is found under ``` main/http/ ```. You can use the ``` main/http/ ``` folder to contain web resources as you would with a normal server.  

The real magic comes with ``` .wrb ``` files, HTML files with some Ruby mixed in. Let's create an example:
```html
#index.wrb
<html>
  <head>
    <title> Hello World! </title>
    <?ruby
      lib("bootstrap")
    ?>
  </head>
  <body>
    <?ruby
      echo "Hello World"
    ?>
  </body>
</html>
```
This is a very simple .wrb file that will simply echo out "Hello World" to the body whenever the page
is accessed. Additionally, any files under ``` libs/css ``` or ``` libs/js ``` with the filename "bootstrap" will also be loaded into the appropriate ```<script>``` or ```<link>``` tag. These libraries can also be given short names as defined in the ```config.rb``` file using ```host.bind_lib```.  

Combinations of Libraries can be loaded using the ``` host.combo ``` in the ```config.rb``` file, and accessed using ```combo(combo_name)``` in your .wrb files.  

More bindings including POST and GET, headers and request / response details are all accessible in the .wrb file.

Many more methods of serving pages, including custom handlers can be found in the examples and documentation.  

## How does it work?
Waitress is designed to be really fast at parsing and serving of webpages, and to do so, we employ two key features: C Native Extensions and Process Forking.

C Native Extensions allow HTTP requests to be parsed extremely fast, and also allow .wrb files to be evaluated really quickly. HTTP Request Parsing is from the [Mongrel Project](http://github.com/mongrel/mongrel), and WRB Parsing is custom made for Waitress.  

Whenever a new request comes in, Waitress parses the request and then spawns a new Process. This Process manages that request and that request only, meaning that .wrb files have access to the entire Ruby runtime without interfering with other requests. This also means that requests can be served extremely quickly.
