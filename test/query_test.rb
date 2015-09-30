class QueryTest < Test::Unit::TestCase

  def test_unescape
    charmap = (0..255).map { |x| [x.chr, "%#{x.to_s(16).rjust(2, "0")}"] }        # Maps ASCII to URL Encode
    charmap.each do |m|
      assert_equal("My#{m[0]}URL#{m[0]}Value".force_encoding("utf-8"),
        Waitress::QueryParser.unescape("My#{m[1]}URL#{m[1]}Value"))
    end
  end

  def test_querystring
    tests = {
      "test=true" => {"test" => "true"},
      "test=true&test=false" => { "test" => "false" },
      "test[]=true&test[]=false" => { "test" => ["true", "false"] },
      "test[=true&test[=false" => { "test[" => "false" },
      "test[]other=true&test[]another=false" => { "test" => [{"other" => "true", "another" => "false"}] },
      "test]other=true&test]another=false" => {"test" => {"other" => "true", "another" => "false"}},
      "test[other=true&test[another=false" => {"test" => {"other" => "true", "another" => "false"}}
    }
    tests.each do |key, val|
      assert_equal(val, Waitress::QueryParser.parse(key))
    end
  end

end
