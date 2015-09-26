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
require 'waitress/chef'

require 'waitress_http11'

require 'go'
require 'configfile'
require 'fileutils'

module Waitress

  def self.serve! filesystem=false, rootdir=:default
    waitress = Waitress.new
    waitress.serve! filesystem, rootdir
  end

  def self.configure! *args, &block
    Waitress::Configure.configure! *args, &block
  end

  def self.new *args
    Waitress::Launcher.new *args
  end

  class Launcher

    def initialize waitress_root="~/.waitress"
      @waitress_root = File.expand_path waitress_root
    end

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
