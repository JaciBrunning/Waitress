module Waitress
  
  # The 500 Handler is a simple handler which is triggered when the server encounters an error
  # in the serving of a request. If possible, the handler will alert the client of an internal 
  # server error, and if applicable, will display a stacktrace. Stacktraces may be disabled
  # in the server configuration.
  class Handler500
    def self.trigger client, server, error, backtrace
      begin
        client.write "HTTP/1.1 500 Internal Server Error\r\n"
        client.write "Content-Type: text/html\r\n"
        client.write "\r\n"
        client.write "<center> <h1> 500 </h1> <h2> Internal Server Error </h2>"
        
        if backtrace
          client.write "<h3> Error Backtrace: </h3>"
          client.write "<div style='text-align: left; width: 50%'>"
          client.write "<p> #{error.backtrace.join '<br>'} </p> </div>"
        end
        
        client.write "<hr /> <h5> Waitress HTTP Server Version #{Waitress::VERSION} </h5> </center>"
        client.close
      rescue => e
        # Do nothing, it's a lost cause
      end
    end
  end
end