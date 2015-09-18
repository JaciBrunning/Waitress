require 'mkmf'

dir_config("waitress_http11")
have_library("c", "main")

create_makefile("waitress_http11")
