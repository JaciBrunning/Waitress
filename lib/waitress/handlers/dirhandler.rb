module Waitress
  class DirHandler < Handler

    attr_accessor :priority
    attr_accessor :directory

    def initialize directory, priority=50
      @directory = File.absolute_path(directory)
      @priority = priority
    end

    def respond? request, vhost
      path = File.expand_path File.join("#{directory}", request.path)
      path.include?(directory) && (Waitress::Chef.find_file(path)[:result] == :ok)
    end

    def serve request, response, client, vhost
      path = File.expand_path File.join("#{directory}", request.path)
      file = Waitress::Chef.find_file(path)[:file]
      Waitress::Chef.serve_file request, response, client, vhost, file
      # response.mime File.extname(file)
      # response.body_io File.open(file, "r")
      # response.status 200       # TODO: Cache Engine
    end

  end
end
