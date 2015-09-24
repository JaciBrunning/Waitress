module Waitress
  class Vhost < Array

    attr_accessor :priority
    attr_accessor :domain

    def initialize pattern, priority=50, doc_root=nil
      @domain = pattern
      @documentroot = doc_root
      @priority = priority
      self << Waitress::DirHandler.resources_handler
      #* Do Dir Handler Here *#
    end

    def document_root
      @documentroot
    end

    def set_404 link
      @page_404 = link
    end

    def get_404
      @page_404
    end

    def handle_request request, client
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
