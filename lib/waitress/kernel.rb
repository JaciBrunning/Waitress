# The Kernel Module provides global methods that will provide the 'builtins' for .wrb files
# and handlers. This is used to prevent verbose access of a namespace like Waitress::Global,
# and instead provide them here. Because requests are handled in new Processes, these values
# will change in each request and will not interfere.
module ::Kernel

  # The +Waitress::Response+ object being used
  def response_object
    $RESPONSE
  end

  # The +Waitress::Request+ object being used
  def request_object
    $REQUEST
  end

  # Prepare the Kernel, by linking global variables
  def kernel_prepare
    $METHOD = get_method
    $HEADERS = get_headers
    $PATH = get_path
    $URI = get_uri
    $BODY = get_body
  end

  # Automatically load a library header into this file in the form of HTML.
  # This will load a library in the VHost's libs/ folder, or any lib defined in the
  # VHost's config.rb file with the name given. JS libraries will be linked with the
  # <script> tag, whilst css files will be linked with the <link rel="stylesheet">
  # tag. This is the recommended way of handling library loading.
  # Params:
  # +name+:: The name of the lib (the filename), or the name of the library as bound
  # in the config.rb file.
  def lib name
    name = name.to_sym
    type = $VHOST.libraries[name][:type]
    libhome = $VHOST.liburi
    if type == :js
      echo "<script type='text/javascript' src='/#{libhome}/#{name}'></script>"
    elsif type == :css
      echo "<link rel='stylesheet' href='/#{libhome}/#{name}'></link>"
    end
  end

  # Automatically load a Library Combo into this file. This will consecutively load
  # all the libraries bound to the combination with the given name as defined in the
  # VHost's config.rb file. This will call lib() for each of these libraries.
  # Params:
  # +name+:: The name of the combo to load
  def combo name
    name = name.to_sym
    combo_arr = $VHOST.combos[name]
    combo_arr.each { |n| lib(n) }
  end

  # Include another .wrb, .rb or any other file in the load path of the VHost into this
  # file. If this file is .wrb or .rb, it will be evaluated. If it is another type of file
  # (e.g. html), it will be directly echoed to the output buffer
  # Params:
  # +filename+:: The name of the file, relative to the loadpath
  def includes filename
    Waitress::Chef.include_file filename
  end

  # Include another .wrb, .rb or any other file in this file. If this file is
  # .wrb or .rb, it will be evaluated. If it is another type of file
  # (e.g. html), it will be directly echoed to the output buffer
  # Params:
  # +filename+:: The absolute filename of the file to load, anywhere in the filesystem
  def includes_file filename
    Waitress::Chef.include_absfile filename
  end

  # Returns a Hash of the GET query of the request. This may be an empty array
  # if querystring was present
  def get
    request_object.get_query
  end

  # Returns a Hash of the POST query of the request. This may be an empty array
  # if the body is not a valid querystring, or an exception raised if there was
  # an error in parsing.
  def post
    request_object.post_query
  end

  # Get a header from the HTTP Request. This will fetch the header by the given
  # name from the request object. Keep in mind that in requests, Headers are fully
  # capitalized and any hyphens replaced with underscores (e.g. Content-Type becomes
  # CONTENT_TYPE)
  def get_header name
    request_object.headers[name]
  end

  # Return the full list of headers available in the request object.
  def get_headers
    request_object.headers
  end

  # Returns the HTTP method that was used to retrieve this page (GET, POST, UPDATE,
  # DELETE, PUT, etc)
  def get_method
    request_object.method
  end

  # Get the path of this request. This is after a URL rewrite, and does not contain
  # a querystring. Be careful with these, as they start with a "/" and if not joined
  # correctly can cause issues in the root of your filesystem (use File.join) if you
  # plan to use this
  def get_path
    request_object.path
  end

  # Get the URI of this request. Unlike the path, the URI is not modified after a rewrite,
  # and does contain a querystring. Use this if you want the *original* path and query
  # of the request before it was rewritten
  def get_uri
    request_object.uri
  end

  # Get the request body. In most cases, this will be blank, but for POST requests it may
  # contain a querystring, and for PUT and UPDATE methods it may contain other data
  def get_body
    request_object.body
  end

  # Get the querystring object as a string before it is parsed
  def get_querystring
    request_object.querystring
  end

  # Set a response header. This will be joined when writing the response with the delimiter ": "
  # as in regular HTTP Protocol fashion.
  # Params:
  # +name+:: The name of the header, e.g. "Content-Type"
  # +value+:: The value of the header, e.g. "text/html"
  def set_header name, value
    response_object.header name, value
  end

  # Set the content-type of the response. This is a shortcut to the Content-Type
  # header and takes the full content-type (not fileextension) as an argument
  # Params:
  # +raw_type+:: The mime type of the content, e.g. "text/html"
  def content_type raw_type
    response_object.mime_raw raw_type
  end

  # Set the content-type of the response. This is a shortcut to the Content-Type
  # header, and will also lookup the fileextension in the +Waitress::Util+ mime-type
  # lookup.
  # Params:
  # +extension+:: The file extension to map to a mimetype, e.g. ".html"
  def file_ext extension
    response_object.mime extension
  end

  # Write a string to the output buffer. This will write directly to the body of the
  # response, similar to what 'print()' does for STDOUT. Use this to write data to the
  # output stream
  def echo obj
    str = obj.to_s
    write str
  end

  # Write a string to the output buffer, followed by a newline. Similar to echo(),
  # this will write to the output buffer, but also adds a "\n". This does to the
  # client output as 'puts()' does to STDOUT. Use this to write data to the output
  # stream
  def println obj
    echo(obj.to_s + "\n")
  end

  # Write a set of bytes directly to the output stream. Use this if you don't want
  # to cast to a string as echo() and println() do. 
  def write bytes
    r = response_object
    r.body "" if r.body_io.nil?
    r.body_io.write bytes
  end

end
