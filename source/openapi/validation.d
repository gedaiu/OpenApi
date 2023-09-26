/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 8, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.validation;

import openapi.definitions;
import openapi.exceptions;

import vibe.http.server;
import vibe.data.json;

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

bool isValid(Json value, string type, string format = "") {
  if(type == "object")
    return value.type == Json.Type.object;

  if(type == "array")
    return value.type == Json.Type.array;

  return value.to!string.isValid(type, format);
}

bool isValid(string value, string type, string format = "") {
  if(format == "undefined") {
    format = "";
  }

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
  } catch(ConvOverflowException e) {
    return false;
  } catch(ConvException e) {
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

@("it should validate integers")
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

@("it should validate numbers")
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

@("it should validate boolean")
unittest {
  assert(!"0".isValid("boolean"));
  assert(!"1".isValid("boolean"));
  assert(!"2".isValid("boolean"));
  assert(!"-1".isValid("boolean"));
  assert("true".isValid("boolean"));
  assert("false".isValid("boolean"));
  assert(!"text".isValid("boolean"));
}

@("it should validate strings")
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

Components getOpenApiOperation(HTTPServerRequest, OpenApi) {
  return Components();
}

void validateExistence(ParameterIn in_)(HTTPServerRequest request, OpenApi definition) {

}

Path matchedPath(OpenApi definition, string) {
  return Path();
}

void validateValues(ParameterIn in_)(HTTPServerRequest request, OpenApi definition) {

}

void validateAgainstSchema(Json value, Json schema) {
  if("required" in schema) {
    foreach(field; schema["required"]) {
      if(field.to!string !in value) {
        throw new OpenApiParameterException("Missing `" ~ field.to!string ~ "` parameter.");
      }
    }
  }

  if(value.type == Json.Type.object) {
    foreach(string key, subValue; value) {
      if(key !in schema["properties"]) {
        throw new OpenApiParameterException("Extra `"~key~"` parameter found.");
      }

      string format = "format" in schema["properties"][key] ? schema["properties"][key]["format"].to!string : "";

      if(!subValue.isValid(schema["properties"][key]["type"].to!string, format)) {
        throw new OpenApiValidationException("Invalid `" ~ key ~ "` schema value.");
      }

      subValue.validateAgainstSchema(schema["properties"][key]);
    }
  }
}

void validateBody(HTTPServerRequest request, OpenApi definition) {

}

void validate(ParameterIn in_)(HTTPServerRequest request, OpenApi definition) {
  request.validateExistence!in_(definition);
  request.validateValues!in_(definition);
}
