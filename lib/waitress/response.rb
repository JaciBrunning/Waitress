module Waitress
  # The response class is used to cook responses to be served to the client.
  # This class contains things like response headers, status codes and the response
  # body itself
  class Response

    def initialize
      @headers = {}
      status 200
      default_headers
      @isdone = false
    end

    # Returns true if the response has already been sent to the client
    def done?
      @isdone
    end

    # Mark the response as done (already sent to the client)
    def done state=true
      @isdone = state
    end

    # Apply the default headers to this response
    def default_headers
      header "Server", "Waitress #{Waitress::VERSION} (#{RUBY_PLATFORM})"
    end

    # Apply the given Status code to the response, such as 200, 404, 500 or
    # any other code listed in the HTTP protocol specification
    def status status_code
      @status = status_code
      @status_msg = Waitress::Util.status @status
      header "Status", "#{@status} #{@status_msg}"
    end

    # Set the mimetype (Content-Type header) of this response to the one matching
    # the given file extension as matched by the +Waitress::Util+ class
    # +filext+:: The file extension to match, e.g. .html, .css, .js
    def mime filext
      m = Waitress::Util.mime filext
      header "Content-Type", m
    end

    # Set the mimetype (Content-Type header) of this response to the one given.
    # +type+:: The mime type to use, e.g. application/json, text/html,
    # application/scon
    def mime_raw type
      header "Content-Type", type
    end

    # Set a header for the response. This header will be encoded to the http
    # response
    # Params:
    # +header+:: The name of the header. e.g. "Content-Type"
    # +data+:: The data to be encoded into the header. e.g. "text/html"
    def header header, data
      @headers[header] = data
    end

    # Set the Body IO object for the response. This IO object will be read from
    # when the webpage is served, so usually this is a File reference or a StringIO
    # +io+:: The io object to use. Not required if you just want to get the IO object
    def body_io io=:get
      @io = io unless io == :get
      @io
    end

    # Append something to the Body IO. If the Body IO is a StringIO, this will usually be
    # a String. This is mostly used for the 'echo' function
    def append obj
      @io.write obj
    end

    # Set the body to be a String. This will replace the BodyIO with a StringIO
    # containing the string
    # +str+:: The new string to replace the BodyIO with
    def body str
      body_io StringIO.new(str)
    end

    # Serve the response to the given socket. This will write the Headers, Response
    # Code and Body.
    def serve sock
      unless done?
        sock.write "HTTP/1.1 #{@status} #{@status_msg}\r\n"
        @headers.each do |k, v|
          sock.write "#{k}: #{v}\r\n"
        end
        sock.write "\r\n"
        unless @io.nil?
          @io.pos = 0
          until @io.eof?
            s = @io.read(4096)
            sock.write s
          end
        end
        done
        sock.close rescue nil
        @io.close rescue nil
      end
    end

  end
end
