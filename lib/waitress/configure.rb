module Waitress

  # The Configure Class is used to load Waitress configurations from the filesystem,
  # usually used in the config.rb file.
  class Configure

    # Endpoint for Waitress.configure!
    def self.configure! *args, &block
      raise "Using 'configure!' outside of file target" if @@configure_target.nil?
      @@configure_target.read_configure *args, &block
    end

    def self.config_target o
      @@configure_target = o
    end

    attr_accessor :servers
    attr_accessor :root

    def initialize root
      @root = root
      @configurations = []
      generate_configs

      load_cfg

      @servers = @configurations.map do |conf|
        s = Waitress::HttpServer.new
        conf.hosts.each { |h| s << h }
        s.set_processes conf.processes
        s.ports *conf.ports
        s.internal_error conf.internal_error
        s
      end
      puts "Waitress Configuration Complete"
      puts "Servers Started on Ports: "
      @servers.each do |x|
        puts "\t#{x.ports.join ", "}"
      end
    end

    # Run all servers in this configuration
    def run
      @servers.each { |s| s.run }
    end

    # Join all the server threads in this configuration
    def join
      @servers.each { |s| s.join }
    end

    # Read the configuration object
    def read_configure *args, &block
      config = Configuration.new self, *args
      block.call(config)
      @configurations << config
    end

    # Generate the configuration file if it doesn't already exist.
    def generate_configs
      FileUtils.mkdir_p(@root) unless File.exist?(@root)
      raise "File #{@root} is not a directory!" unless File.directory?(@root)
      @config = File.join(@root, "config.rb")
      unless File.exist?(@config)
        c = File.read(File.join(Waitress::Chef.resources, "default_config.rb"))
        File.write(@config, c)
      end
    end

    # Load the config.rb file
    def load_cfg
      Waitress::Configure.config_target self
      path = File.absolute_path(@config)
      require path
      Waitress::Configure.config_target nil
    end

  end

  # The Configuration Class is the object that contains a configuration
  # of a single server instance, hosting all the methods provided by
  # Waitress.configure!
  class Configuration

    attr_accessor :hosts
    attr_accessor :ports
    attr_accessor :processes
    attr_accessor :internal_error

    def initialize configure, *ports
      @ports = *ports
      @hosts = []
      @configure = configure
      @internal_error = false

      @processes = 5
      @processes = ENV["WAITRESS_PROCESSES"].to_i if ENV.include? "WAITRESS_PROCESSES"
    end

    # Create a new VirtualHost with the given regex, priority, and configure it
    # inside of its own block.
    def host regex, priority=50, &block
      host = Waitress::Vhost.new regex, priority
      host.set_configure @configure
      block.call(host)
      @hosts << host
      host
    end

    # Over all the registered VHosts, call this method. Use this to configure
    # a similar setting for all vhosts at once instead of duplicating code
    # across all of them.
    def all_hosts &block
      @hosts.each { |h| block.call(h) }
    end

    # Set the watch period for the LESS Watcher, i.e. how long to sleep before
    # checking LESS files for an update and recompile
    def less_watch time
      Waitress::LESSWatcher.set_time time
    end
    
    # Set to true to enable 500 error backtraces in the browser
    def detailed_500 enabled
      @internal_error = enabled
    end

    def to_s
      m = lambda { |a,x| x.nil? ? "" : "\r\n#{a}=#{x.inspect}" }
      "#<#{self.class} #{m.call('ports', @ports)} #{m.call('hosts', @hosts)}>"
    end

  end

end
