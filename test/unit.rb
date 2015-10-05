$LOAD_PATH.unshift File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'coveralls'
Coveralls.wear!
require 'test/unit'

require 'waitress'
require 'open-uri'

require_relative 'query_test'
require_relative 'util_test'
require_relative 'embed_test'
require_relative 'restful_test'
