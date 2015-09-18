module Waitress
  class FileHandler

    def intialize dir
      @directory = File.expand_path(dir)
    end

    def active? request

    end

    def priority
      10
    end

    def serve

    end

  end
end
