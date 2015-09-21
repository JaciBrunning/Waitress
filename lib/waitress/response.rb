module Waitress
  class Response

    def initialize
      @headers = {}
      @status = 200
    end

    def status status_code
      @status = status_code
      set_header "Status", "#{@status} #{Waitress::Const::Status[@status]}"
    end

    def set_header header, data
      @headers[header] = data
    end

    def body_io io
      
    end

  end
end
