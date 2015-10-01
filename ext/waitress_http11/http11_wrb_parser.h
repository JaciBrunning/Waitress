#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif
#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

char *substr(const char *buff, int start, int len) {
    char subbuff[len + 1];
    memcpy(subbuff, &buff[start], len);
    subbuff[len] = '\0';
    return strdup(subbuff);
}

int mat(char *str1, char *str2) {
    return strcmp(str1, str2) == 0;
}

VALUE WRB_Parse(VALUE self, VALUE string, VALUE buffer) {
  char *sptr = RSTRING_PTR(string);
  long slen = RSTRING_LEN(string);

  char *tar = "<?ruby";
  char tarlen = 6;
  char *end = "?>";
  char endlen = 2;

  int i = 0;
  char pc = NULL;
  int line_cur = 1;
  int line = 1;

  while (i < slen) {
    char c = sptr[i];
    if (c == '\n') line_cur += 1;

    int open_e = i + tarlen;
    char *open_s = substr(sptr, i, tarlen);

    if (mat(open_s, tar) && pc != '\\') {
      line = line_cur;
      int j = open_e;
      int search = 1;
      int q1 = 0; int q2 = 0;
      while (j < slen && search) {
        char cc = sptr[j];
        if (cc == '\n') line_cur += 1;

        int close_e = j + endlen;
        char *close_s = substr(sptr, j, endlen);

        if (sptr[j-1] != '\\') {
          if (cc == '\"') q1 = (q1 == 0 ? 1 : 0);
          if (cc == '\'') q2 = (q2 == 0 ? 1 : 0);
          if (mat(close_s, end) && !q1 && !q2) {
            i = close_e - 1;
            search = 0;
            char *rb_ev = substr(sptr, open_e, j - open_e);
            rb_yield_values(2, rb_str_new2(rb_ev), INT2NUM(line));
          }
        }

        j+=1;
      }

      if (j == slen && search) {
        char *rb_ev = substr(sptr, open_e, j);
        i = slen;
        rb_eval_string(rb_ev);
      }
    } else if (c == '\\') {
      if (!mat(substr(sptr, i+1, tarlen), tar)) {
        char strbuf[2] = "\0";
        strbuf[0] = c;
        rb_funcall(buffer, rb_intern("write"), 1, rb_str_new2(strbuf));
      }
    } else {
      char strbuf[2] = "\0";
      strbuf[0] = c;
      rb_funcall(buffer, rb_intern("write"), 1, rb_str_new2(strbuf));
    }

    pc = c;
    i += 1;
  }
}

void init_parse(VALUE rubyModule) {
  VALUE cWaParse = rb_define_class_under(rubyModule, "WRBParser", rb_cObject);
  rb_define_module_function(cWaParse, "parse!", WRB_Parse, 2);
}
