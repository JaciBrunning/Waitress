module Waitress
  
  # The 404 Handler is a simple "Catch-All" handler which will be triggered if
  # a valid handler is not found for the page, and will show an error page
  # telling the user the page cannot be found
  class Handler404 < ErrorHandler

    def serve request, response, client, vhost
      response.status 404
      e404page = vhost.get_404
      if !e404page.nil? && (Waitress::Chef.find_file(e404page)[:result]==:ok)
        Waitress::Chef.serve_file request, response, client, vhost, e404page
      else
        if vhost.resources?
          h = File.join Waitress::Chef.resources_http, "404.html"
          Waitress::Chef.serve_file request, response, client, vhost, h
        else
          response.mime ".html"
          response.body "<h1> 404 - Not Found </h1> <p> The page you have requested is not here </p>"
        end
      end
    end

  end
end
