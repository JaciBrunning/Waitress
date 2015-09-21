require 'waitress/version'
require 'waitress/server'
require 'waitress/request'
require 'waitress/constants'

require 'go'
require 'configfile'
require 'waitress_http11'
require 'fileutils'

module Waitress

  def self.serve! filesystem=false, rootdir=:default
    waitress = Waitress.new
    waitress.serve! filesystem, rootdir
  end

  def self.new *args
    Waitress::Launcher.new *args
  end

  class Launcher

    def new usr_root="~/waitress"
      @usr_root = File.expand_path usr_root
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
        ConfigFile.new File.join(@usr_root, "config.yml"), {"server_root" => "~/waitress/www"}, :yaml
      end

      def serve_filesystem rootdir
        if rootdir == :default
          FileUtils.mkdir_p @usr_root unless File.exist? @usr_root
          cfg = config
          cfg.load
          @root = File.expand_path cfg["server_root"]
        else
          @root = rootdir
        end
        s = serve
      end

      def serve
        Waitress::HttpServer.new
      end
  end
end
