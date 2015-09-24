module Waitress
  class Chef

    HANDLERS = {
      404 => Handler404.new
    }

    def self.resources
      File.expand_path "../resources", __FILE__
    end

    def self.error code, request, response, client, vhost
      HANDLERS[code].serve!(request, response, client, vhost)
    end

    def self.serve_file request, response, client, vhost, file
      response.mime File.extname(file)
      response.body_io File.open(file, "r")
    end

    # Big mess of file finding logic
    def self.find_file abspath
      ret = {}
      if File.exist?(abspath)
        if File.directory?(abspath)
          wrb = File.join(abspath, "index.wrb")
          html = File.join(abspath, "index.html")
          if File.exist?(wrb)
            ret = { :result => :ok, :file => wrb }
          elsif File.exist?(html)
            ret = { :result => :ok, :file => html }
          else
            ret = { :result => :dir, :file => abspath }
          end
        else
          ret = { :result => :ok, :file => abspath }
        end
      elsif File.exist?("#{abspath}.html")
        ret = { :result => :ok, :file => "#{abspath}.html" }
      else
        ret = { :result => :notfound }
      end
      ret
    end

  end
end
