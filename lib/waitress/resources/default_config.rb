# This is the configuration for your waitress server, accepting connections on port '2910'
Waitress.configure!(2910) do |w|

  # You can run regular Ruby Code in here, too!
  @home = "~/.waitress/www/"
  def fl file
    File.join(@home, file)
  end

  # This is your main Virtual Host, accepting connections to 'example.mysite.com'
  w.host(/example.mysite.com/) do |host|
    # This is where your public documents and pages are stored
    host.root fl("example/http")

    # This is where your non-public includes are stored
    host.includes fl("example/rb")

    # This will show up when a 404 error occurs
    # host.set_404 fl("example/http/404.html")

    # Want to rewrite a URL? No problem.
    host.rewrite /some_url/, "some_other_url"
    host.rewrite /capture_group_(\d)/, "capture/group\\1"

    # Bind_Lib will allow you to automatically import lib tags into .wrb files
    # Before they are sent to the client.
    host.bind_lib /jquery.*/, :js, "jquery"
    host.bind_lib /boostrap.*/, :css, "boots"

    # Use combos to chain together libraries into a collection
    host.combo "all-lib", "jquery", "boots"

    # Change this to change where you store your libraries
    host.libdir fl("libs")

    # Change this to choose what URI the libraries are linked
    # to (yoursite.com/libraries/library_name)
    host.liburi "libraries"
  end

  # This is your other Virtual Host, accepting connections to any domain.
  # The '0' represents the priority, with the default being 50. Higher priority
  # Hosts will be chosen if the request matches multiple Hosts.
  w.host(/.*/, 0) do |host|
    # This is where your public documents and pages are stored
    host.root fl("main/http")

    # This is where your non-public includes are stored
    host.includes fl("main/rb")
  end

end
