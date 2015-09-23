module ::Kernel

  def response_object
    Waitress::Reponse.global
  end

  def request_object
    Waitress::Request.global
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

  def content_type_auto extension
    response_object.mime extension
  end

end
