/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 8, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.validation;

import swaggerize.definitions;

import vibe.http.server;
import vibe.data.json;

import tested: testName = name;
import std.conv;
import std.datetime;
import std.regex;
import std.stdio;
import std.algorithm.iteration;
import std.algorithm.comparison;
import std.array;
import std.traits;
import vibe.utils.dictionarylist;

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

bool isValid(string value, string type, string format = "") {
  if(format == "undefined") {
    format = "";
  }

  try {
    try {
      if(type == "integer" && format == "int32") {
        value.to!int;
        return true;
      }

      if(type == "integer" && format == "int64") {
        value.to!long;
        return true;
      }

      if(type == "integer" && format == "") {
        return value.isValid(type, "int32") || value.isValid(type, "int64");
      }

      if(type == "number" && format == "float") {
        value.to!float;
        return true;
      }

      if(type == "number" && format == "double") {
        value.to!double;
        return true;
      }

      if(type == "number" && format == "") {
        return value.isValid(type, "double") || value.isValid(type, "float");
      }

      if(type == "boolean") {
        value.to!bool;
        return true;
      }

      if(type == "string" && format == "") {
        return true;
      }

      if(type == "string" && format == "password") {
        return true;
      }

      if(type == "string" && format == "binary") {
        return true;
      }
    } catch(ConvException e) {
      return false;
    }
  } catch(ConvOverflowException e) {
    return false;
  }

  try {
    if(type == "string" && format == "date-time") {
      SysTime.fromISOExtString(value);
      return true;
    }

    if(type == "string" && format == "date") {
      Date.fromISOExtString(value);
      return true;
    }

    if(type == "string" && format == "time") {
      TimeOfDay.fromISOExtString(value);
      return true;
    }
  } catch(Exception e) {
    return false;
  }

  if(type == "string" && format == "byte") {
    auto ctr = ctRegex!(`^([A-Za-z0-9]*\n{0,1})*`);
    auto matches = value.matchAll(ctr);

    if(matches.post != "" || matches.pre != "") {
      return false;
    }

    return true;
  }

  return false;
}

@testName("it should validate integers")
unittest {
  assert("0".isValid("integer", "int32"));
  assert("2147483647".isValid("integer", "int32"));
  assert("-2147483648".isValid("integer", "int32"));
  assert(!"2147483648".isValid("integer", "int32"));
  assert(!"-2147483649".isValid("integer", "int32"));
  assert(!"text".isValid("integer", "int32"));

  assert("0".isValid("integer", "int64"));
  assert("9223372036854775807".isValid("integer", "int64"));
  assert("-9223372036854775807".isValid("integer", "int64"));
  assert(!"9223372036854775808".isValid("integer", "int64"));
  assert(!"9223372036854775808".isValid("integer", "int64"));
  assert(!"text".isValid("integer", "int64"));
}

@testName("it should validate numbers")
unittest {
  assert("0".isValid("number", "float"));
  assert("0.5".isValid("number", "float"));
  assert("-0.5".isValid("number", "float"));
  assert(!"0,5".isValid("number", "float"));
  assert(!"-0,5".isValid("number", "float"));
  assert(!"text".isValid("number", "float"));

  assert("0".isValid("number", "double"));
  assert("0.5".isValid("number", "double"));
  assert("-0.5".isValid("number", "double"));
  assert(!"0,5".isValid("number", "double"));
  assert(!"-0,5".isValid("number", "double"));
  assert(!"text".isValid("number", "double"));
}

@testName("it should validate boolean")
unittest {
  assert(!"0".isValid("boolean"));
  assert(!"1".isValid("boolean"));
  assert(!"2".isValid("boolean"));
  assert(!"-1".isValid("boolean"));
  assert("true".isValid("boolean"));
  assert("false".isValid("boolean"));
  assert(!"text".isValid("boolean"));
}

@testName("it should validate strings")
unittest {
  assert("text".isValid("string"));

  assert("text".isValid("string", "password"));

  assert("text".isValid("string", "binary"));

  assert(!"text".isValid("string", "date-time"));
  assert("2000-01-01T00:00:00Z".isValid("string", "date-time"));

  assert("2000-01-01".isValid("string", "date"));
  assert(!"text".isValid("string", "date"));

  assert("00:00:00".isValid("string", "time"));
  assert(!"text".isValid("string", "time"));

  assert("ASDASDasd0123\nadma21".isValid("string", "byte"));
  assert(!"!@#".isValid("string", "byte"));
}

private string[] keys(T)(T list) {
  string[] keyList;

  foreach(string key, val; list)
    keyList ~= key;

  return keyList;
}

void validate(Parameter.In in_)(HTTPServerRequest request, Swagger definition) {

  static if(in_ == Parameter.In.path) {
    enum string property = "params";
  } else static if(in_ == Parameter.In.query) {
    enum string property = "query";
  } else {
    static assert("Validation for `" ~ in_ ~ "` is not supported. Only `params`, `query`.");
  }

  /*
  enum In: string {
    header = "header",
    formData = "formData",
    body_ = "body"
  }*/

  auto params = request.getSwaggerOperation(definition).parameters.filter!(a => a.in_ == in_).map!"a.name".array;
  auto requestProperty = __traits(getMember, request, property);

  if(!equal(requestProperty.keys, params)) {
    throw new SwaggerParameterException("Invalid `" ~ property ~ "` parameters.");
  }

  void isValid(Parameter parameter) {
    if(parameter.name !in requestProperty)
      throw new SwaggerParameterException("`" ~ parameter.name ~ "` " ~ property ~ " not found");

    if(!requestProperty[parameter.name]
          .isValid(parameter.other["type"].to!string, parameter.other["format"].to!string)) {
      throw new SwaggerValidationException("Invalid `" ~ parameter.name ~ "` parameter.");
    }
  }

  definition
    .matchedPath(request.path)
    .operations.get(request.method)
    .parameters.filter!(a => a.in_ == in_).each!isValid;
}

@testName("it should raise exception when path validation fails")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test/asd";
  request.params["id"] = "asd";

  Parameter parameter;
  parameter.in_ = Parameter.In.path;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test/{id}"] = Path();
  definition.paths["/test/{id}"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(Parameter.In.path)(definition);
  } catch(SwaggerValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should not raise exception when path validation succedes")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test/1";
  request.params["id"] = "1";

  Parameter parameter;
  parameter.in_ = Parameter.In.path;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test/{id}"] = Path();
  definition.paths["/test/{id}"].operations[Path.OperationsType.get] = operation;

  request.validate!(Parameter.In.path)(definition);
}

@testName("it should raise exception when query validation fails")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.query["id"] = "asd";

  Parameter parameter;
  parameter.in_ = Parameter.In.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(Parameter.In.query)(definition);
  } catch(SwaggerValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should not raise exception when query succedes")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.query["id"] = "123";

  Parameter parameter;
  parameter.in_ = Parameter.In.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  request.validate!(Parameter.In.query)(definition);
}

@testName("it should raise exception when query parameter is missing")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";

  Parameter parameter;
  parameter.in_ = Parameter.In.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(Parameter.In.query)(definition);
  } catch(SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should raise exception when there is an extra query parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.query["id"] = "123";
  request.query["value"] = "123";

  Parameter parameter;
  parameter.in_ = Parameter.In.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(Parameter.In.query)(definition);
  } catch(SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}
