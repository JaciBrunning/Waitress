module Waitress
  class Handler404 < ErrorHandler

    def serve request, response, client, vhost
      response.status 404
      e404page = vhost.get_404
      if !e404page.nil? && (Waitress::Chef.find_file(e404page)[:result]==:ok)
        Waitress::Chef.serve_file request, response, client, vhost, e404page
      else
        h = File.join Waitress::Chef.resources_http, "404.html"
        Waitress::Chef.serve_file request, response, client, vhost, h
      end
    end

  end
end
