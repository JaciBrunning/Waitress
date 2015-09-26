module Waitress
  class Chef

    HANDLERS = {
      404 => Handler404.new
    }

    def self.resources
      File.expand_path "../resources", __FILE__
    end

    def self.resources_http
      File.join(resources, "http")
    end

    def self.error code, request, response, client, vhost
      HANDLERS[code].serve!(request, response, client, vhost)
    end

    def self.serve_file request, response, client, vhost, file
      if File.extname(file) == ".wrb" || File.extname(file) == ".rb"
        response.mime ".html"
        include_absfile File.expand_path(file)
      else
        response.mime File.extname(file)
        response.body_io File.open(file, "r")
      end
    end

    def self.include_file filename
      lp = $VHOST.load_path
      target = nil
      lp.each do |path|
        fl = File.join(path, filename)
        ext = ["", ".rb", ".wrb"]
        ext.each do |e|
          flnew = "#{fl}#{e}"
          target = flnew if File.exist?(flnew)
        end
      end

      include_absfile target
    end

    def self.include_absfile target
      raise LoadError.new("Include does not exist in Load Path: #{target}") if target.nil?
      ext = File.extname target
      if ext == ".wrb"
        Waitress::WRBParser.parse! File.read(target), $RESPONSE.body_io
      elsif ext == ".rb"
        require target
      else
        echo File.read(target)
      end
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
      elsif File.exist?("#{abspath}.wrb")
        ret = { :result => :ok, :file => "#{abspath}.wrb" }
      else
        ret = { :result => :notfound }
      end
      ret
    end

  end
end
