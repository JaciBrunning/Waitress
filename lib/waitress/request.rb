module Waitress
  class Request

    @@global = nil

    def globalize
      @@global = self
    end

    def self.global
      @@global
    end

    attr_accessor :method
    attr_accessor :path
    attr_accessor :uri
    attr_accessor :querystring
    attr_accessor :http_version
    attr_accessor :body
    attr_accessor :headers

    def initialize method, path, uri, query, http_version, body, headers
      @method = method
      @path = path
      @uri = uri
      @querystring = query
      @http_version = http_version
      @body = body
      @headers = headers
    end

    def to_s
      m = lambda { |a,x| x.nil? ? "" : "#{a}=#{x.inspect}" }
      "#<#{self.class} method=#{@method} path=#{@path} #{m.call("query", @query)}>"
    end

  end
end
