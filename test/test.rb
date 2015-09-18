$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'waitress'

# parser = Waitress::HttpParser.new
# params = {}
# socket = TCPServer.new 2160
#
# while true
#   begin
#     client = socket.accept
#     data = client.readpartial(1024)
#     parser.execute(params, data, 0)
#     puts params
#   rescue
#   end
# end
#
# server = Waitress::HttpServer.new 2910
# server.run[0].join

Waitress.serve!.run(2910).join
