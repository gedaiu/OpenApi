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
import std.algorithm.searching;
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

class SwaggerNotFoundException : Exception {
  this(string msg = null, Throwable next = null) { super(msg, next); }
  this(string msg, string file, size_t line, Throwable next = null) {
      super(msg, file, line, next);
  }
}

bool isValid(Json value, string type, string format = "") {
  if(type == "object")
    return value.type == Json.Type.Object;

  return value.to!string.isValid(type, format);
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

void validateExistence(Parameter.In in_)(HTTPServerRequest request, Swagger definition) {
  static if(in_ == Parameter.In.path) {
    enum string property = "params";
  } else static if(in_ == Parameter.In.query) {
    enum string property = "query";
  } else static if(in_ == Parameter.In.header) {
    enum string property = "headers";
  } else static if(in_ == Parameter.In.body_) {
    enum string property = "json";
  } else {
    static assert("Validation for `" ~ in_ ~ "` is not supported. Only `params`, `query`, `headers`, `body`.");
  }

  auto allParams = request.getSwaggerOperation(definition).parameters.filter!(a => a.in_ == in_ ).map!"a.name".array;
  auto requiredParams = request.getSwaggerOperation(definition).parameters.filter!(a => a.in_ == in_ && a.required).map!"a.name".array;
  auto requestProperty = __traits(getMember, request, property);

  static if(in_ == Parameter.In.body_) {
    string[] keys;

    if(requestProperty.type == Json.Type.object) {
      foreach(string key, value; requestProperty)
        keys ~= key;
    }
  } else {
    auto keys = requestProperty.keys;
  }

  foreach(string param; requiredParams)
    if(param !in requestProperty)
      throw new SwaggerParameterException("Required `" ~param~ "` " ~ property ~ " missing.");

  static if(in_ != Parameter.In.header) {
    foreach(string param; keys)
      if(!allParams.canFind(param)) {
        throw new SwaggerParameterException("Extra `" ~param~ "` " ~ property ~ " found.");
      }
  }
}

void validateValues(Parameter.In in_)(HTTPServerRequest request, Swagger definition) {
  static if(in_ == Parameter.In.path) {
    enum string property = "params";
  } else static if(in_ == Parameter.In.query) {
    enum string property = "query";
  } else static if(in_ == Parameter.In.header) {
    enum string property = "headers";
  } else static if(in_ == Parameter.In.body_) {
    enum string property = "json";
  } else {
    static assert("Validation for `" ~ in_ ~ "` is not supported. Only `params`, `query`, `headers`, `body`.");
  }

  auto requestProperty = __traits(getMember, request, property);

  void isValid(Parameter parameter) {
    if(parameter.name !in requestProperty)
      throw new SwaggerParameterException("`" ~ parameter.name ~ "` " ~ property ~ " not found");

    static if(in_ == Parameter.In.body_) {
      string type = parameter.schema.fields["type"].to!string;
      string format = parameter.schema.fields["format"].to!string;
    } else {
      string type = parameter.other["type"].to!string;
      string format = parameter.other["format"].to!string;
    }

    if(!requestProperty[parameter.name]
          .isValid(type, format)) {
      throw new SwaggerValidationException("Invalid `" ~ parameter.name ~ "` parameter.");
    }
  }

  definition
    .matchedPath(request.path)
    .operations.get(request.method)
    .parameters.filter!(a => a.in_ == in_)
    .each!isValid;
}

void validateAgainstSchema(Json value, Json schema) {
  if("required" in schema) {
    foreach(field; schema.required) {
      if(field.to!string !in value) {
        throw new SwaggerParameterException("Missing `"~field.to!string~"` parameter.");
      }
    }
  }

  if(value.type == Json.Type.object) {
    foreach(string key, subValue; value) {
      if(key !in schema.properties) {
        throw new SwaggerParameterException("Extra `"~key~"` parameter found.");
      }

      if(!subValue.isValid(schema.properties[key]["type"].to!string, schema.properties[key]["format"].to!string)) {
        throw new SwaggerValidationException("Invalid `"~key~"` value.");
      }

      subValue.validateAgainstSchema(schema.properties[key]);
    }
  }
}

void validateBody(HTTPServerRequest request, Swagger definition) {

  auto parameters = definition
                      .matchedPath(request.path)
                      .operations
                        .get(request.method)
                          .parameters
                            .filter!(a => a.in_ == Parameter.In.body_ && a.schema.fields["type"] == "object");

  void validateSchema(Parameter parameter) {
    string name = parameter.name;
    request.json.validateAgainstSchema(parameter.schema.fields);
  }

  parameters.each!validateSchema;
}

void validate(Parameter.In in_)(HTTPServerRequest request, Swagger definition) {
  request.validateExistence!in_(definition);
  request.validateValues!in_(definition);
}
