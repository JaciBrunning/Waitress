module Waitress

  # The LibraryHandler is used to handle requests to the VHost regarding the
  # libraries to be loaded by other Handlers and .wrb files. This will take any
  # requests to /libraries (or whatever the user has set it to) to load libraries
  class LibraryHandler < Handler

    require 'json'
    require 'less'
    require 'digest'

    attr_accessor :priority

    def initialize libraries, libdir, liburi, vhost
      @priority = 150
      @vhost = vhost
      @libraries, @libdir, @liburi = libraries, File.expand_path(libdir), liburi
      @cachedir = File.join(@libdir, ".libcache")
      @lesscache = File.join(@cachedir, "less_compile")
      FileUtils.mkdir_p(@libdir) unless File.exist?(@libdir)
      parse_libraries
      basic_libs
      compiler_libs

      setup_bower
    end

    def compile_less main_file, path
      parser = Less::Parser.new :paths => [path].flatten, :filename => main_file
      tree = parser.parse(File.read(main_file))

      FileUtils.mkdir_p(@lesscache) unless File.exist?(@lesscache)
      output = File.join(@lesscache, "#{Digest::MD5.hexdigest(main_file)}.min.css")
      File.write(output, tree.to_css(:compress => true))

      {:file => output, :type => :css}
    end

    def parse_libraries
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
    end

    def basic_libs
      [:css, :js].each do |k|
        d = dirType k
        FileUtils.mkdir_p(d) unless File.exist?(d)

        Dir["#{d}/**/*.#{k.to_s}"].each do |fl|
          @libraries[File.basename(fl).to_sym] = { :file => fl, :type => k }
        end
      end
    end

    def compiler_libs
      lessdir = dirType :less
      FileUtils.mkdir_p(lessdir) unless File.exist?(lessdir)
      entry = File.join(lessdir, "less.yml")
      if File.exist? entry
        conf = YAML.load(File.read(entry))
        unless conf["libs"].nil?
          conf["libs"].each do |libname, lib|
            @libraries[libname.to_sym] = compile_less File.expand_path(lib, lessdir), lessdir
          end
        end

        unless conf["watch"].nil? || (conf["watch"].length == 0)
          map = conf["watch"].map { |x| File.expand_path(x, lessdir) }
          Waitress::LESSWatcher.new(map) { |file| compile_less(file, lessdir) }
        end
      else
        File.write(entry, File.read(File.join(Waitress::Chef.resources, "default_less.yml")))
      end
    end

    def setup_bower
      bowerdir = File.join(@libdir, "bower_components")
      Dir["#{bowerdir}/**"].each do |component|
        bowerfile = JSON.parse File.read(File.join(component, "bower.json"))
        loadfiles = [bowerfile["main"]].flatten
        loadfiles.each { |x| loadBower(x, bowerfile["name"], component, loadfiles.length > 1) }
      end
    end

    def loadBower main, libname, home, append_type=false
      ext = File.extname(main)
      lib = {}

      main = File.expand_path(main, home)

      if ext == ".css"
        lib[:file] = main
        lib[:type] = :css
      elsif ext == ".js"
        lib[:file] = main
        lib[:type] = :js
      elsif ext == ".less"
        lib = compile_less main, File.dirname(libname)
      end

      libname = libname + "_#{lib[:type].to_s}" if append_type
      libname = libname.to_sym
      @libraries[libname] = lib
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
