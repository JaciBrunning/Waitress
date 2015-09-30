module Waitress

  # The DirHandler class is an instance of +Waitress::Handler+ that is responsible
  # for loading files from the filesystem and serving them if they exist in the VHost's
  # root. It automatically handles mimetypes, evaluation and almost everything about
  # the serving process for files in the FileSystem.
  class DirHandler < Handler

    attr_accessor :priority
    attr_accessor :directory

    # Get the instance of DirHandler that will load Waitress' resources
    # such as the default 404 and index pages, as well as CSS and JS
    def self.resources_handler
      @@resources_handler ||= Waitress::DirHandler.new(Waitress::Chef.resources_http, -1000)
      @@resources_handler
    end

    # Create a new DirHandler, with the given FileSystem directory as a root
    # and priority.
    def initialize directory, priority=50
      @directory = File.absolute_path(directory)
      @priority = priority
    end

    def respond? request, vhost
      path = File.expand_path File.join("#{directory}", request.path)
      res = Waitress::Chef.find_file(path)[:result]
      path.include?(directory) && (res == :ok)
    end

    def serve request, response, client, vhost
      path = File.expand_path File.join("#{directory}", request.path)
      file = Waitress::Chef.find_file(path)[:file]
      Waitress::Chef.serve_file request, response, client, vhost, file
    end

  end
end
