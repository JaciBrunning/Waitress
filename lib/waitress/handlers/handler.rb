module Waitress

  # The Handler class is responsible for handling incoming HTTP requests for a
  # given URL Path. This default class works by matching a regular expression to
  # the request path, however subclasses may choose to use their own matching
  # methods (see +Waitress::DirHandler+).
  #
  # Each Handler acts off of a priority system, where if multiple handlers
  # can respond to the request, the one with the highest priority will be chosen.
  class Handler

    attr_accessor :priority

    # Create a new Regex-Based Handler
    # Params:
    # +regex+:: The regex pattern to match against the request path
    # +priority+:: Priority of the handler. Default: 50
    # +action+:: The block to call when a match is reached. Should take args
    # request, response, client and vhost.
    def initialize regex=nil, priority=50, &action
      @regex = regex
      @action = action
      @priority = priority
    end

    # Returns true if this handler is valid for the given request
    def respond? request, vhost
      (request.path =~ @regex) != nil
    end

    # Don't touch this -- this adds Kernel bindings
    def serve! request, response, client, vhost
      kernel_prepare
      serve request, response, client, vhost
    end

    # If we can respond to the request, this method is called to
    # serve a response based on this handler. Do your response logic here.
    # Params:
    # +request+:: The +Waitress::Request+ object
    # +response+:: The +Waitress::Response+ object
    # +client+:: The client socket
    # +vhost+:: The Virtual Host responsible for the connection
    def serve request, response, client, vhost
      @action.call(request, response, client, vhost) unless @action.nil?
    end

  end

  # The ErrorHandler has the lowest priority, as it shouldn't be triggered
  # unless there is an error (i.e. 404, 500)
  class ErrorHandler < Handler
    def initialize
      @priority = -65536
    end
  end
end
