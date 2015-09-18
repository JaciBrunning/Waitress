module Waitress
  class HttpRequest

    def initialize method, path, uri, query, http_version, body, headers
      @method = method
      @path = path
      @uri = uri
      @query = query
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
