module Waitress
  class Response

    @@global = nil

    def globalize
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
      m = Waitress::Util.mime filext
      header "Content-Type", m
    end

    def mime_raw type
      header "Content-Type", type
    end

    def header header, data
      @headers[header] = data
    end

    def body_io io=:get
      @io = io unless io == :get
      @io
    end

    def append obj
      @io.write obj
    end

    def body str
      body_io StringIO.new(str)
    end

    def serve sock
      sock.write "HTTP/1.1 #{@status} #{@status_msg}\r\n"
      @headers.each do |k, v|
        sock.write "#{k}: #{v}\r\n"
      end
      sock.write "\r\n"
      # TODO: Check IO for nil, write 500 error if nil
      @io.pos = 0
      until @io.eof?
        s = @io.read(1024)
        sock.write s
      end
      done
      sock.close
    end

  end
end
