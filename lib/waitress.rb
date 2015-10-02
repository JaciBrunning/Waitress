require 'waitress/version'
require 'waitress/util'
require 'waitress/kernel'
require 'waitress/configure'
require 'waitress/parse/query'

require 'waitress/server'
require 'waitress/request'
require 'waitress/response'

require 'waitress/vhost'
require 'waitress/handlers/handler'
require 'waitress/handlers/dirhandler'
require 'waitress/handlers/handler404'
require 'waitress/handlers/libhandler'
require 'waitress/chef'
require 'waitress/evalbind'

require 'waitress_http11'

require 'go'
require 'configfile'
require 'fileutils'

# The Base module for the Waitress Web Server, containing all the required
# classes and utilities created by Waitress
module Waitress

  # Create a new Waitress Server, or, in case of the Filesystem, create a Configuration
  # for a set of Servers
  # Params:
  # +filesystem+:: True if waitress should be loaded from the Filesystem. Default: false
  # +rootdir+:: The root directory to load waitress from, defaults to ~/.waitress
  def self.serve! filesystem=false, rootdir=:default
    waitress = Waitress.new
    waitress.serve! filesystem, rootdir
  end

  # Create a configuration for a single Waitress Server instance. This should be called
  # from the config.rb file and nowhere else.
  # Params:
  # +args+:: The arguments to configure with. This should be a variable amount of arguments
  # representing what ports to run the server on. If no args are provided, port 80 will
  # be used as a default
  # +block+:: The block to call once the configuration has been created. Setup should be
  # done in here
  def self.configure! *args, &block
    Waitress::Configure.configure! *args, &block
  end

  # Create a new Launch Instance, used to serve a simple Waitress Server from either the
  # filesystem, or embedded.
  def self.new *args
    Waitress::Launcher.new *args
  end

  class Launcher

    # Create a new launcher. This is responsible for creating Waitress server instances
    # from either the Filesystem, or being embedded in an application
    def initialize waitress_root="~/.waitress"
      @waitress_root = File.expand_path waitress_root
    end

    # Serve a Waitress server from either the Filesystem or embedded in an application
    def serve! filesystem=false, rootdir=:default
      if filesystem
        serve_filesystem rootdir
      else
        serve
      end
    end

  :private
    def config
      ConfigFile.new File.join(@waitress_root, "config.yml"),
        {"server_root" => File.join(@waitress_root, "www")}, :yaml
    end

    def serve_filesystem rootdir
      if rootdir == :default
        FileUtils.mkdir_p @waitress_root unless File.exist? @waitress_root
        cfg = config
        cfg.load
        @root = File.expand_path cfg["server_root"]
      else
        @root = rootdir
      end
      # s = serve
      # Waitress::Configure.new s, @root
      # s
      Waitress::Configure.new @root
    end

    def serve
      Waitress::HttpServer.new
    end
  end
end
