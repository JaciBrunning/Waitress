class EmbedTest < Test::Unit::TestCase

  def setup_server
    server = Waitress.serve!
    server.ports 2940, 2941
    assert_equal(server.ports, [2940, 2941])

    vhost = Waitress::Vhost.new /.*/
    server << vhost

    vhost << Waitress::Handler.new(/.*/, 100) do
      file_ext ".html"
      println "Hello World"
    end

    vhost << Waitress::Handler.new(/world/, 150) do
      file_ext ".txt"
      println "Goodbye World"
    end

    server.run(2950, 2951)

    @server = server
  end


  def test_hello
    setup_server

    resp = open("http://localhost:2950/somepage").read
    assert_equal(resp, "Hello World\n")

    resp = open("http://localhost:2950/world").read
    assert_equal(resp, "Goodbye World\n")

    resp = open("http://localhost:2951/someotherpage").read
    assert_equal(resp, "Hello World\n")

    @server.killall
  end

end
