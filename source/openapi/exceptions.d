/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 10 4, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.exceptions;

class OpenApiValidationException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}

class OpenApiParameterException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}

class OpenApiNotFoundException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}
