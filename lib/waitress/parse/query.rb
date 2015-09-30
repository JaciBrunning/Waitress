module Waitress
  # A lot of this class uses methods from Rack::QueryParser in order to Parse
  # a given QueryString into a Hash of key/value pairs
  class QueryParser
    require 'uri'

    DEFAULT_SEP = /[&;] */n

    # Unescape a HTTP URL to regular text. e.g. %20 becomes a space (" ")
    def self.unescape str, enc=Encoding::UTF_8
      URI.decode_www_form_component(str, enc)
    end

    # Parse the given QueryString into a hash of key/value pairs
    def self.parse qs
      return {} if qs.nil? || qs.empty?
      results = {}
      (qs || '').split(DEFAULT_SEP).each do |p|
        k, v = p.split('='.freeze, 2).map! { |s| unescape(s) }

        normalize results, k, v
      end
      results
    end

    def self.normalize hash, name, v
      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      return if k.empty?

      if after == ""
        hash[k] = v
      elsif after == "["
        hash[name] = v
      elsif after == "[]"
        hash[k] ||= []
        raise TypeError, "expected Array (got #{hash[k].class.name}) for param `#{k}'" unless hash[k].is_a?(Array)
        hash[k] << v
      elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
        child_key = $1
        hash[k] ||= []
        raise TypeError, "expected Array (got #{hash[k].class.name}) for param `#{k}'" unless hash[k].is_a?(Array)
        if hash[k].last.is_a?(Hash) && !hash[k].last.key?(child_key)
          normalize(hash[k].last, child_key, v)
        else
          hash[k] << normalize({}, child_key, v)
        end
      else
        hash[k] ||= {}
        raise TypeError, "expected Hash (got #{hash[k].class.name}) for param `#{k}'" unless hash[k].is_a?(Hash)
        hash[k] = normalize(hash[k], after, v)
      end

      hash
    end

  end
end
