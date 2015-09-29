module Waitress
  class LibraryHandler < Handler

    attr_accessor :priority

    def initialize libraries, libdir, liburi, vhost
      @priority = 150
      @vhost = vhost
      @libraries, @libdir, @liburi = libraries, File.expand_path(libdir), liburi
      FileUtils.mkdir_p(@libdir) unless File.exist?(@libdir)

      @libraries.each do |name, lib|
        l = {}
        d = dirType(lib[:bindtype])
        matches = Dir["#{d}/**/*.#{lib[:bindtype].to_s}"].select { |x| (x =~ lib[:pattern]) != nil }
        if matches.length > 0
          l[:file] = matches[0]
          l[:type] = lib[:bindtype]
        else
          l = nil
        end
        @libraries[name] = l
      end

      [:css, :js].each do |k|
        d = dirType k
        FileUtils.mkdir_p(d) unless File.exist?(d)

        Dir["#{d}/**/*.#{k.to_s}"].each do |fl|
          @libraries[File.basename(fl, ".#{k.to_s}").to_sym] = { :file => fl, :type => k }
        end
      end
    end

    def dirType k
      File.join(@libdir, k.to_s)
    end

    def respond? request, vhost
      path = request.path
      return false unless path.start_with?("/#{@liburi}/")
      name = path.sub("/#{@liburi}/", "").to_sym
      @libraries.include?(name)
    end

    def serve request, response, client, vhost
      path = request.path
      name = path.sub("/#{@liburi}/", "").to_sym
      lib = @libraries[name]
      Waitress::Chef.serve_file request, response, client, vhost, lib[:file]
    end

  end
end
