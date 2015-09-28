module Waitress

  class Configuration

    attr_accessor :hosts
    attr_accessor :ports

    def initialize configure, *ports
      @ports = *ports
      @hosts = []
      @configure = configure
    end

    def host regex, priority=50, &block
      host = Waitress::Vhost.new regex, priority
      host.set_configure @configure
      block.call(host)
      @hosts << host
    end

    def all_hosts &block
      @hosts.each { |h| block.call(h) }
    end

    def to_s
      m = lambda { |a,x| x.nil? ? "" : "\r\n#{a}=#{x.inspect}" }
      "#<#{self.class} #{m.call('ports', @ports)} #{m.call('hosts', @hosts)}>"
    end

  end

  class Configure

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
        s.ports *conf.ports
        s
      end
    end

    def run
      @servers.each { |s| s.run }
    end

    def join
      @servers.each { |s| s.join }
    end

    def read_configure *args, &block
      config = Configuration.new self, *args
      block.call(config)
      @configurations << config
    end

    def generate_configs
      FileUtils.mkdir_p(@root) unless File.exist?(@root)
      raise "File #{@root} is not a directory!" unless File.directory?(@root)
      @config = File.join(@root, "config.rb")
      unless File.exist?(@config)
        c = File.read(File.join(Waitress::Chef.resources, "default_config.rb"))
        File.write(@config, c)
      end
    end

    def load_cfg
      Waitress::Configure.config_target self
      path = File.absolute_path(@config)
      require path
      Waitress::Configure.config_target nil
    end

  end
end
