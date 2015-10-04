TEST_QUERY = "a=true
  &b=false
  &c[]=true&c[]=false
  &c[=true&c[=false
  &d]a=true&d]b=false
  &e[a=true&e[b=true
  ".sub "\n",""

defbench "QueryString Parsing", 100 do
  Waitress::QueryParser.parse TEST_QUERY
end

UNESCAPE = (0..255).map { |x| "%#{x.to_s(16).rjust(2, "0")}" }.join ""

defbench "Unescaping URL", 100 do
  Waitress::QueryParser.unescape(UNESCAPE)
end
