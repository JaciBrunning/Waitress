module Waitress
  class Handler

    def initialize regex=nil, priority=50, &action
      @regex = regex
      @action = action
      @priority = priority
    end

    def respond? request, vhost
      (request.uri =~ @regex) != nil
    end

    def priority
      @priority
    end

    # Don't touch this -- this adds Kernel bindings
    def serve! request, response, client
      request.globalize
      response.globalize
      kernel_prepare
      serve request, response, client
    end

    def serve request, response, client
      @action.call(request, response, client) unless @action.nil?
    end

  end
end
