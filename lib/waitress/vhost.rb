module Waitress
  class Vhost < Array

    attr_accessor :priority
    attr_accessor :domain
    attr_accessor :load_path

    attr_accessor :combos
    attr_accessor :libraries

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

      enable_waitress_resources
    end

    def on_request &block
      @on_request << block
    end

    def after_request &block
      @after_request << block
    end

    def disable_waitress_resources
      @resources = false
    end

    def enable_waitress_resources
      @resources = true
    end

    def resources?
      @resources
    end

    def set_404 link
      @page_404 = link
    end

    def get_404
      @page_404
    end

    def root dir, priority=50
      self << Waitress::DirHandler.new(File.expand_path(dir), priority)
    end

    def set_configure conf
      @configuration = conf
    end

    def libdir name
      @libdir = File.expand_path(name)
    end

    def liburi name=nil
      @liburi = name unless name.nil?
      @liburi
    end

    def bind_lib pattern, type, name, *options
      lib = { :pattern => pattern, :bindtype => type, :options => options}
      @libraries[name.to_sym] = lib
    end

    def lib_combo name, *targets
      @combos[name.to_sym] = targets
      targets
    end

    def parse_libraries
      self << Waitress::LibraryHandler.new(@libraries, @libdir, @liburi, self)
    end

    def on_server_start srv
      parse_libraries
    end

    def includes dir
      if dir.is_a? String
        load_path << File.expand_path(dir)
      elsif dir.is_a? Array
        load_path = dir.map { |x| File.expand_path(x) }
      end
    end

    def cancel_request
      @cancelled = true
    end

    def rewrite pattern, newpath
      on_request do |request, vhost|
        request.path = request.path.gsub(pattern, newpath)
      end
    end

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
