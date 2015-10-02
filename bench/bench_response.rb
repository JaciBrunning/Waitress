require 'open-uri'

def setup_server
  server = Waitress.serve!

  vhost = Waitress::Vhost.new /.*/
  server << vhost

  vhost << Waitress::Handler.new(/.*/, 100) do
    file_ext ".html"
    println "Hello World"
  end

  server.run(2950)

  @server = server
end


defbench "Server Response", 100 do |a|
  begin
    if a == :start
      setup_server
    elsif a == :stop
      @server.killall
    else
      open("http://localhost:2950/test.html").close
    end
  rescue => e
    @server.killall rescue nil
    raise e
  end
end
