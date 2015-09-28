require 'socket'
require 'thread'

module Waitress
  class HttpServer < Array

    class HttpParams < Hash
      attr_accessor :http_body
    end

    def initialize(*ports)
      ports << 80 if ports.length == 0
      @ports = ports
    end

    def ports *ports
      @ports = *ports unless ports.length == 0
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

    def read_io io
      handle_client io
    end

  :private
    def launch_port port
      @server = TCPServer.new port
      while true
        client = @server.accept
        go do
          begin
            handle_client client
          rescue => e
            puts "Server Error: #{e} (Fix This!)"
            puts e.backtrace
          end
        end
      end
    end

    def handle_client client_socket
      begin
        data = client_socket.readpartial(8196)
      rescue
        client_socket.close unless client_socket.closed?
        return
      end

      gofork do
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
      request = Waitress::Request.new(
        headers["REQUEST_METHOD"], headers["REQUEST_PATH"], headers["REQUEST_URI"],
        headers["QUERY_STRING"], headers["HTTP_VERSION"], headers.http_body, request_headers
      )
      handle_request request, client_socket
    end

    def handle_request request, client
      match, pri = self[0], nil
      self.each do |vhost|
        if (request.headers['Host'].to_s =~ vhost.domain) != nil
          match = vhost if pri.nil? || vhost.priority > pri
        end
      end

      if match.nil?
        # Subdomain not found (or default)
      else
        match.handle_request request, client
      end
    end
  end
end
