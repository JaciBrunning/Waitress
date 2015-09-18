require 'socket'
require 'thread'

module Waitress
  class HttpServer

    class HttpParams < Hash
      attr_accessor :http_body
    end

    def initialize(*ports)
      ports << 80 if ports.length == 0
      @ports = ports
    end

    def ports *ports
      @ports = ports unless ports.length == 0
      @ports
    end

    def run *ports
      @ports = ports unless ports.length == 0
      @threads = @ports.map { |x| Thread.new { launch_port x } }
      self
    end

    def join
      @threads.each { |x| x.join }
    end

  :private
    def launch_port port
      @server = TCPServer.new port
      while true
        client = @server.accept
        go { handle_client client }
      end
    end

    def handle_client client_socket
      data = client_socket.readpartial(8196)
      gofork do |chan|
        parser = Waitress::HttpParser.new
        params = HttpParams.new
        parser.execute(params, data, 0)
        build_request params, client_socket
      end.wait
      client_socket.close
    end

    def build_request headers, client_socket
      request_headers = {}
      headers.each do |k,v|
        if k.start_with? "HTTP_HEAD_"
          request_headers[k.sub(/HTTP_HEAD_/, "")] = v
        end
      end
      request = Waitress::HttpRequest.new(
        headers["REQUEST_METHOD"], headers["REQUEST_PATH"], headers["REQUEST_URI"],
        headers["QUERY_STRING"], headers["HTTP_VERSION"], headers.http_body, request_headers
      )
      puts request
    end

  end
end
