module Waitress
  class Vhost < Array

    attr_accessor :priority
    attr_accessor :domain
    attr_accessor :load_path

    def initialize pattern, priority=50
      @domain = pattern
      @priority = priority
      @load_path = []
      self << Waitress::DirHandler.resources_handler
      #* Do Dir Handler Here *#
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
      load_path = dir
    end

    def handle_request request, client
      puts "Done #{request}"
      match, pri = nil, nil
      self.each do |handler|
         match = handler if handler.respond?(request, self) && (pri.nil? || handler.priority > pri)
      end

      response = Waitress::Response.new
      if match.nil?
        Waitress::Chef.error 404, request, response, client, self
      else
        match.serve! request, response, client, self
      end
      response.serve(client) unless (response.done? || client.closed?)
    end

  end
end
