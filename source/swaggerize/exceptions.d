/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 10 4, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.exceptions;

class SwaggerValidationException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}

class SwaggerParameterException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}

class SwaggerNotFoundException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}
