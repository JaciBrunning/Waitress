module Waitress
  class REST < Handler

    require 'json'
    require 'scon'
    require 'yaml'

    attr_accessor :priority

    SUPPORTED_FORMATS = [:json, :scon, :yaml, :yml]

    def self.build! schema, &call
      pattern = /:([^\/:\?\[]+)(\?)?(\[[a-zA-Z0-9\-_\s,]+\])?\//

      a = schema.gsub(pattern) do |match|
        capture_name = $1
        optional = ($2 == "?")
        enumerations = nil
        enumerations = $3.gsub(/\[|\]/, "").split(/,\s?/) unless $3.nil?
        buildRe = "(?<#{capture_name}>"
        if enumerations.nil?
          buildRe << "[^\\/]+"
        else
          buildRe << enumerations.join("|")
        end
        buildRe << ")"
        buildRe << "?" if optional
        buildRe << "/"
        buildRe << "?" if optional

        buildRe
      end

      Waitress::REST.new(Regexp.new(a), &call)
    end

    def initialize regex, &call
      @regex = regex
      @call = call
      @priority = 200
    end

    def respond? request, vhost
      (request.uri =~ @regex) != nil
    end

    def encode_format content_hash, request, response, type
      ret = ""
      if type == :json
        if request.get_query.include? "pretty"
          ret = JSON.pretty_generate(content_hash)
        else
          ret = JSON.generate(content_hash)
        end
      elsif type == :scon
        ret = SCON.generate!(content_hash)
      elsif type == :yaml || type == :yml
        ret = content_hash.to_yaml
      end
      ret
    end

    def serve request, response, client, vhost
      match = request.uri.match @regex

      form = :json
      if (request.get_query.include? "format")
        val = request.get_query["format"].downcase.to_sym
        form = val if SUPPORTED_FORMATS.include?(val)
      end

      response.mime ".#{form.to_s}"

      content_hash = @call.call(match, request, response, vhost)
      response.body encode_format(content_hash, request, response, form)
    end

  end
end
