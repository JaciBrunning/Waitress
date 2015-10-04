module Waitress
  # The VHost class is responsible for the actions of a Virtual Host, that is
  # reacting to a certain subdomain and handling the requests that are sent to it.
  # The requests are managed through the usage of +Waitress::Handler+ instances.
  class Vhost < Array

    attr_accessor :priority
    attr_accessor :domain
    attr_accessor :load_path

    attr_accessor :combos
    attr_accessor :libraries

    # Create a new Virtual Host to manage traffic on a Subdomain (Host header)
    # Params:
    # +pattern+:: The regex pattern used to match this VHost to subdomain(s)
    # +priority+:: The priority of the VHost. If multiple VHosts match the subdomain,
    # the VHost with the highest priority will be chosen. Default: 50
    def initialize pattern, priority=50
      @domain = pattern
      @priority = priority
      @load_path = []

      @libdir = "~/.waitress/www/libs"
      @liburi = "libraries"

      @libraries = {}
      @combos = {}

      @on_request = []
      @after_request = []

      @config_data = {}

      enable_waitress_resources
    end

    # The config data of the VHost. This config data is set by the configuration
    # file and can be read by the server when serving requests. This is so users
    # can set data in their config.rb file and read it out on their requests. Use
    # this to set constants such as Social Media IDs and other details
    def config
      @config_data
    end

    # Register a listener that will be triggered once a request has been received
    # by this VHost, but before it has been passed to a listener or served. Use this
    # to modify a request before it is handled.
    # The Block should take arguments:
    # +request+:: The +Waitress::Request+ object
    # +vhost+:: The VirtualHost instance
    # +client+:: The Client Socket object
    def on_request &block
      @on_request << block
    end

    # Register a listener that will be triggered once a request has been received
    # by this VHost, after it has been handled, but before it is served.
    # The Block should take arguments:
    # +request+:: The +Waitress::Request+ object
    # +response+:: The +Waitress::Response+ object
    # +vhost+:: The VirtualHost instance
    # +client+:: The Client Socket object
    def after_request &block
      @after_request << block
    end

    # Call this to disable the Waitress Handler (Waitress' default CSS, JS, 404 and Index)
    def disable_waitress_resources
      @resources = false
    end

    # Call this to enable the Waitress Handler (Waitress' default CSS, JS, 404 and Index)
    def enable_waitress_resources
      @resources = true
    end

    # Returns true if the VHost has the Waitress Handler enabled (Waitress' default CSS, JS, 404 and Index)
    def resources?
      @resources
    end

    # Change the default 404 page for the VHost. This should be an absolute file path to your 404 page
    # file that you wish to use
    def set_404 link
      @page_404 = link
    end

    # Get the absolute file path for the 404 page to use for this VHost. May be nil.
    def get_404
      @page_404
    end

    # Add a Document Root for this VHost. This document root will contain all of your
    # public files that can be served by the vhost.
    # Params:
    # +dir+:: The directory for the Document Root
    # +priority+:: The priority for the directory. If multiple Handlers respond to the target
    # URI, the one with the highest priority will be chosen. Default: 50
    def root dir, priority=50
      self << Waitress::DirHandler.new(File.expand_path(dir), priority)
    end

    # Internal
    def set_configure conf
      @configuration = conf
    end

    # Set the directory in which Libraries are contained. Libraries are specially handled by
    # waitress to be loaded into .wrb files and handlers. Default: "libs/"
    # This file will contain your CSS, JS and any other libraries.
    # Bower packages are also supported under this directory ("bower_components")
    def libdir name
      @libdir = File.expand_path(name)
    end

    # Change the uri that Libraries should be accessed from. Libraries present in the "libs/"
    # directory are served from this URI. This URI is relative to the base "/" uri for the VirtualHost,
    # for example, a LibUri of "libraries/" (the default) will be accessed by "your.site/libraries/lib_name"
    def liburi name=nil
      @liburi = name unless name.nil?
      @liburi
    end

    # Bind a library to a name. By default, when libraries are found in the css/ and js/ folders of your
    # lib directory, they are loaded under the lib name of "filename.type", with type being .css or .js.
    # By binding a library, you can give this a different name based on the file found by regular expression,
    # for example, binding /jquery/ to "jquery" will match any filenames containing 'jquery', meaning the full
    # name of 'jquery-ver.sion' is matched, and can be accessed simply by "jquery"
    # Params:
    # +pattern+:: The regular expression to check files against. This will match the first file it finds with
    # the expression to the library.
    # +type+:: The type of file. This should be a symbol of either :js or :css, or any other supported lib types
    # +name+:: The new name to reference this library by
    # +options+:: Any extra options to use when loading the library (to be used in the future)
    def bind_lib pattern, type, name, *options
      lib = { :pattern => pattern, :bindtype => type, :options => options}
      @libraries[name.to_sym] = lib
    end

    # Define a combination of libraries. Calling this method will bind all the libaries listed under one common
    # name that can be loaded into .wrb files and handlers using combo(). This is used to load a collection of
    # libraries simply and easily without repeating lib() methods.
    # Params:
    # +name+:: The desired name of the combo
    # +targets+:: A list of all the libraries to bind to this combo
    def combo name, *targets
      @combos[name.to_sym] = targets
      targets
    end

    # Internal
    def parse_libraries
      self << Waitress::LibraryHandler.new(@libraries, @libdir, @liburi, self)
    end

    # Internal (called on Server Start)
    def on_server_start srv
      parse_libraries
    end

    # Used to define the load path for the VHost. The Load Path defines what files can be
    # included from outside of the public web directory, such as database backend or
    # authentication. These files are not available to the public, but can be included by
    # the .wrb files.
    # Params:
    # +dir+: The directory to use for the loadpath. If a string is provided, it is added,
    # however, if an array is provided, it will override with the array.
    def includes dir
      if dir.is_a? String
        load_path << File.expand_path(dir)
      elsif dir.is_a? Array
        load_path = dir.map { |x| File.expand_path(x) }
      end
    end

    # Cancel the current request (don't serve the response)
    def cancel_request
      @cancelled = true
    end

    # Define a rewrite rule. A rewrite rule is used to rewrite a URL's path
    # before it is handled. Keep in mind that this does not function for a query string,
    # which should instead be handled with the on_request event.
    # Params;
    # +pattern+:: The pattern to match the URL against
    # +newpath+:: The new path to replace the matched pattern with. This can include
    # capture groups through the use of \\1 (where 1 is the capture group number)
    def rewrite pattern, newpath
      on_request do |request, vhost|
        request.path = request.path.gsub(pattern, newpath)
      end
    end

    # Internal (matches requests)
    def handle_request request, client
      @cancelled = false

      response = Waitress::Response.new

      $REQUEST = request
      $RESPONSE = response
      $VHOST = self

      @on_request.each { |x| x.call(request, self, client) }

      unless @cancelled
        match = nil
        if @resources && Waitress::DirHandler.resources_handler.respond?(request, self)
          match = Waitress::DirHandler.resources_handler
        end

        self.each do |handler|
           match = handler if handler.respond?(request, self) && (match.nil? || handler.priority > match.priority)
        end

        if match.nil?
          Waitress::Chef.error 404, request, response, client, self
        else
          match.serve! request, response, client, self
        end
      end

      @after_request.each { |x| x.call(request, response, self, client) }
      response.serve(client) unless (response.done? || client.closed?)
    end

  end
end
