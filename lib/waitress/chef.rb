module Waitress

  # The chef class handles the cooking of responses, by serving errors and files
  # from the Filesystem, as well as providing a system for including files within
  # handlers and .wrb files. This class handles most loading from Filesystems
  # and serving of the body of a response.
  class Chef

    HANDLERS = {
      404 => Handler404.new
    }

    # Get the waitress resources directory, containing templates and the default
    # http assets of waitress
    def self.resources
      File.expand_path "../resources", __FILE__
    end

    # Get the waitress HTTP assets directory, containing the default index, 404
    # and styles resources.
    def self.resources_http
      File.join(resources, "http")
    end

    # Set the response to use an error page with the given error code (usually 404)
    def self.error code, request, response, client, vhost
      HANDLERS[code].serve!(request, response, client, vhost)
    end

    # Serve a file from the Filesystem, automatically handling based on whether the
    # file is dynamic or static. This will set the body io and any required
    # headers on the reponse object.
    def self.serve_file request, response, client, vhost, file
      if File.extname(file) == ".wrb" || File.extname(file) == ".rb"
        response.mime ".html"
        include_absfile File.expand_path(file)
      else
        response.mime File.extname(file)
        response.body_io File.open(file, "r")
      end
    end

    # Include a file from the VHost loadpath in the current running instance.
    # Params:
    # +filename+:: The filename of the file, relative to the load path of the VHost.
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

      raise LoadError.new("Include does not exist in Load Path: #{target}") if target.nil?
      include_absfile target
    end

    # Include a file from anywhere in the filesystem (absolute) in the current running
    # instance. This will load the file's content and, if dynamic, evaluate it to the
    # current response.
    # Params:
    # +target+:: The target file, given in absolute path form.
    def self.include_absfile target
      ext = File.extname target
      if ext == ".wrb"
        Waitress::WRBParser.parse! File.read(target), $RESPONSE.body_io
      elsif ext == ".rb"
        require target
      else
        echo File.read(target)
      end
    end

    # Find a file to serve. This is used by the DirHandler
    # to automatically include an index file if it exists under the
    # requested directory, automatically add the .wrb or .html file extension
    # for paths without the extension, etc. A hash containing the result (ok / notfound)
    # and the new filepath will be given. 
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
