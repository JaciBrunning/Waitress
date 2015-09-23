module Waitress
  class Response

    @@global = nil

    def self.globalize
      @@global = self
    end

    def self.global
      @@global
    end

    def initialize
      @headers = {}
      status 200
      default_headers
      @isdone = false
    end

    def done?
      @isdone
    end

    def done state=true
      @isdone = state
    end

    def default_headers
      header "Server", "Waitress #{Waitress::VERSION} (#{RUBY_PLATFORM})"
    end

    def status status_code
      @status = status_code
      @status_msg = Waitress::Util.status @status
      header "Status", "#{@status} #{@status_msg}"
    end

    def mime filext
      m = Waitress::Const.mime filext
      header "Content-Type", m
    end

    def mime_raw type
      header "Content-Type", type
    end

    def header header, data
      @headers[header] = data
    end

    def body_io io
      @io = io
    end

    def serve sock
      sock.write "HTTP/1.1 #{@status} #{@status_msg}\r\n"
      @headers.each do |k, v|
        sock.write "#{k}: #{v}\r\n"
      end
      sock.write "\r\n"
      sock.write @io.read
      done
      sock.close
    end

  end
end
