module Waitress
  # The request class is used to represent a HTTP request by a client. This includes
  # all the headers sent to the server by the client, request URI and those properties
  # parsed by Mongrel, including the Path and QueryString. GET and POST queries are to
  # be parsed on-request by the handler or .wrb file as to not waste CPU resources.
  class Request

    attr_accessor :method
    attr_accessor :path
    attr_accessor :uri
    attr_accessor :querystring
    attr_accessor :http_version
    attr_accessor :body
    attr_accessor :headers

    def initialize method, path, uri, query, http_version, body, headers
      @method = method
      @path = Waitress::QueryParser.unescape(path)
      @uri = Waitress::QueryParser.unescape(uri)
      @querystring = query
      @http_version = http_version
      @body = body
      @headers = headers
      @marks = {}
    end

    # The GET query for the request in the form of a hash. This is parsed on-request
    def get_query
      @get ||= Waitress::QueryParser.parse(@querystring)
      @get
    end

    # The POST query for the request in the form of a hash. This is parsed on-request
    def post_query
      @post ||= Waitress::QueryParser.parse(@body)
      @post
    end

    def to_s
      m = lambda { |a,x| x.nil? ? "" : "#{a}=#{x.inspect}" }
      "#<#{self.class} method=#{@method} path=#{@path} #{m.call("query", @query)}>"
    end

  end
end
