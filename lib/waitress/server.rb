require 'socket'
require 'thread'

module Waitress

  # The Waitress HTTPServer. This class is responsible for handling traffic from
  # clients and delegating it to the correct Virtual Host to further handle.
  # New threads and Processes are spawned for each connection to the server
  class HttpServer < Array

    class HttpParams < Hash
      attr_accessor :http_body
    end

    attr_accessor :processes

    # Create a new Server instance with the given ports. If no ports are given,
    # port 80 will be used as a default
    def initialize(*ports)
      ports << 80 if ports.length == 0
      @ports = ports
      @processes = 5
      @processes = ENV["WAITRESS_PROCESSES"].to_i if ENV.include? "WAITRESS_PROCESSES"
      @running_processes = []
    end

    # Set the amount of concurrent Waitress Processes to run on this Server, per Port
    def set_processes count
      @processes = count
    end

    # Set or Get the ports for this server. If arguments are provided, the ports
    # for this server will be replaced with the ones listed. If no arguments are provided,
    # this method simply returns the ports
    def ports *ports
      @ports = *ports unless ports.length == 0
      @ports
    end

    # Start the server. If arguments are provided, it will run with the ports
    # declared in the arguments, otherwise, it will use the ports it already has
    # set (or 80 for the default)
    def run *ports
      @ports = ports unless ports.length == 0
      self.each do |vhost|
        vhost.on_server_start self
      end

      @running_processes = @ports.map do |port|
        launch_port(port)
      end
      @running_processes.flatten!
      self
    end

    # Killall running processes
    def killall
      @running_processes.each { |x| x.kill rescue nil }
    end

    # Join the server, blocking the current thread in order to keep the server alive.
    def join
      @running_processes.each { |x| x.wait }
    end

    # Handle a client based on an IO stream, if you plan to serve on a non-socket
    # connection
    def read_io io
      handle_client io
    end

  :private
    def launch_port port
      serv = TCPServer.new port
      processes = []
      @processes.times do
        processes << gofork {
          while true
            begin
              client = serv.accept
              gofork do               # Makes sure requires etc don't get triggered across requests
                handle_client client
              end.wait
              client.close rescue nil
            rescue => e
              puts "Server Error: #{e} (Fix This!)"
              puts e.backtrace
              client.close rescue nil
            end
          end
        }
      end

      processes.each do |pr|
        Process.detach(pr.pid)
      end
      processes
    end

    def handle_client client_socket
      # pro = gofork do
      begin
        data = client_socket.readpartial(8192)
        nparsed = 0

        parser = Waitress::HttpParser.new
        params = HttpParams.new

        while nparsed < data.length
          nparsed = parser.execute(params, data, nparsed)
          if parser.finished?
            build_request params, client_socket
          else
            ch = client.readpartial(8192)
            break if !ch or ch.length == 0

            data << ch
          end
        end
      rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL, Errno::EBADF
        client_socket.close rescue nil
      rescue => e
        puts "Client Error: #{e}"
        puts e.backtrace
      end
      # end
      client_socket.close rescue nil
      # pro.wait
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
