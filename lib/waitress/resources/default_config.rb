# This is the configuration for your waitress server, accepting connections on port '80'
Waitress.configure!(80) do |w|

  # This is your main Virtual Host, accepting connections to 'example.mysite.com'
  w.host(/example.mysite.com/) do |host|
    host.root "~/waitress/www/example/http"      # This is where your documents are stored
    host.includes "~/waitress/www/example/rb"    # This is where your non-public includes are stored
    host.set_404 "~/waitress/www/example/http/404.html"  # This will show up when a 404 error occurs
  end

  # This is your other Virtual Host, accepting connections to any domain.
  # The '0' represents the priority, with the default being 50. Higher priority
  # Hosts will be chosen if the request matches multiple Hosts.
  w.host(/.*/, 0) do |host|
    host.root "~/waitress/www/main/http"         # This is where your documents are stored
    host.includes "~/waitress/www/main/rb"       # This is where your non-public includes are stored
  end

end
