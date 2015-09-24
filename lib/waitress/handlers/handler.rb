module Waitress
  class Handler

    attr_accessor :priority

    def initialize regex=nil, priority=50, &action
      @regex = regex
      @action = action
      @priority = priority
    end

    def respond? request, vhost
      (request.uri =~ @regex) != nil
    end

    # Don't touch this -- this adds Kernel bindings
    def serve! request, response, client, vhost
      request.globalize
      response.globalize
      kernel_prepare
      serve request, response, client, vhost
    end

    def serve request, response, client, vhost
      @action.call(request, response, client, vhost) unless @action.nil?
    end

  end

  class ErrorHandler < Handler
    def initialize
      @priority = -65536
    end
  end
end
