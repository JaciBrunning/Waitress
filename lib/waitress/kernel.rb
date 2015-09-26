module ::Kernel

  def response_object
    $RESPONSE
  end

  def request_object
    $REQUEST
  end

  def kernel_prepare
    $METHOD = get_method
    $HEADERS = get_headers
    $PATH = get_path
    $URI = get_uri
    $BODY = get_body
  end

  def includes filename
    Waitress::Chef.include_file filename
  end

  def includes_file filename
    Waitress::Chef.include_absfile filename
  end

  def get
    request_object.get_query
  end

  def post
    request_object.post_query
  end

  def get_header name
    request_object.headers[name]
  end

  def get_headers
    request_object.headers
  end

  def get_method
    request_object.method
  end

  def get_path
    request_object.path
  end

  def get_uri
    request_object.uri
  end

  def get_body
    request_object.body
  end

  def get_querystring
    request_object.querystring
  end

  def set_header name, value
    response_object.header name, value
  end

  def content_type raw_type
    response_object.mime_raw raw_type
  end

  def file_ext extension
    response_object.mime extension
  end

  def echo obj
    str = obj.to_s
    write str
  end

  def write bytes
    r = response_object
    r.body "" if r.body_io.nil?
    r.body_io.write bytes
  end

  def println obj
    echo(obj.to_s + "\n")
  end

end
