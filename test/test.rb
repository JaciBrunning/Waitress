$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'waitress'

trap("INT") { exit }

server = Waitress.serve!
vhost = Waitress::Vhost.new /.*/
server << vhost


# vhost << Waitress::Handler.new(/.*/i, 100) do
#   file_ext ".html"
#   println "<h1> Hello World! </h1>"
#   println "<h2> Hi, #{post["name"]} </h2>"
# end

server.run(2910).join




# vhost.set_404 "web_test/index.html"

# vhost << Waitress::Handler.new(/.*/) do |req, res|
#   file_ext ".txt"
#   echo "Waitress is Working"
# end

# vhost << Waitress::DirHandler.new("web_test", 120)
