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

    def serve request, response, client
      request.globalize
      response.globalize
      @action.call(request, response, client) unless @action.nil?
    end

  end
end
