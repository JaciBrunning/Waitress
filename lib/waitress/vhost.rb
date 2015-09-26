module Waitress
  class Vhost < Array

    attr_accessor :priority
    attr_accessor :domain
    attr_accessor :load_path

    def initialize pattern, priority=50
      @domain = pattern
      @priority = priority
      @load_path = []
      enable_waitress_resources
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

    def includes dir
      if dir.is_a? String
        load_path << File.expand_path(dir)
      elsif dir.is_a? Array
        load_path = dir.map { |x| File.expand_path(x) }
      end
    end

    def handle_request request, client
      match = nil
      if @resources && Waitress::DirHandler.resources_handler.respond?(request, self)
        match = Waitress::DirHandler.resources_handler
      end

      self.each do |handler|
         match = handler if handler.respond?(request, self) && (match.nil? || handler.priority > match.priority)
      end

      response = Waitress::Response.new

      $REQUEST = request
      $RESPONSE = response
      $VHOST = self

      if match.nil?
        Waitress::Chef.error 404, request, response, client, self
      else
        match.serve! request, response, client, self
      end
      response.serve(client) unless (response.done? || client.closed?)
    end

  end
end
