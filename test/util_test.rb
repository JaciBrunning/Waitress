class UtilTest < Test::Unit::TestCase

  def test_mimetype
    tests = {
      ".html" => "text/html",
      ".scon" => "application/scon",
      ".unknown" => "application/octet-stream"
    }

    tests.each do |f, t|
      assert_equal(t, Waitress::Util.mime(f))
    end
  end

  def test_status
    tests = {
      404 => "Not Found",
      200 => "OK",
      304 => "Not Modified"
    }

    tests.each do |c, m|
      assert_equal(m, Waitress::Util.status(c))
    end
  end

end
