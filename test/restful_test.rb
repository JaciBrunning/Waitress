class RestfulTest < Test::Unit::TestCase
  REST_TESTS = {
    "/root/:test/:maybe?/:schema[a, b]/" => {
      :success => [
        "/root/aTest/perhaps/a/",
        "/root/aTest/perhaps/b/",
        "/root/aTest/b/",
        "/root/aTest/a"
      ],
      :failure => [
        "/notroot/bTest/perhaps/a/",
        "/root/",
        "/root/bTest/perhaps/c/",
        "/root/bTest/perhaps/ab/",
        "/root/bTest/",
        "/another/root/aTest/perhaps/a/",
        "/root/aTest/perhaps/b/morestuff"
      ]
    }
  }

  class DummyRequest
    attr_accessor :path
  end

  def test_restful
    REST_TESTS.each do |key, val|
      handler = Waitress::REST.build!(key)

      val[:success].each do |success|
        req = DummyRequest.new
        req.path = success
        respond = handler.respond?(req, nil)
        puts "ERROR: " + failure.match(handler.regex).inspect unless respond
        assert_equal(true, respond)
      end

      val[:failure].each do |failure|
        req = DummyRequest.new
        req.path = failure
        respond = handler.respond?(req, nil)
        puts "ERROR: " + failure.match(handler.regex).inspect if respond
        assert_equal(false, respond)
      end
    end
  end
end
