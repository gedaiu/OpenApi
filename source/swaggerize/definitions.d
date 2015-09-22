/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.definitions;

import std.traits;
import std.conv;
import std.exception;
import std.algorithm.iteration;
import std.algorithm.comparison;
import std.path;
import std.stdio;
import std.array;
import std.string;

import vibe.data.serialization : aliasName = name, optional, ignore;
import vibe.data.json, vibe.http.common;
import vibe.http.server;

import tested: testName = name;

enum Schemes: string {
  http = "http",
  https = "https",
  ws = "ws",
  wss = "wss"
}

struct Swagger {
  string swagger;
  Info info;
  Path[string] paths;

  @optional {
    string host;
    string basePath = "/";
    Schemes[] schemes;
    string[] consumes;
    string[] produces;
    Schema[string] definitions;
    Parameter[string] parameters;
    Response[string] responses;
    SecurityScheme[string] securityDefinitions;
    Schema[] security;
    Tag[] tags;
    ExternalDocumentation externalDocs;
  }

  Json getReference(string path) {
    import std.array : split;
    auto pieces = path.split('/');

    enforce(pieces[0] == "#", "First item in path must be `#`");

    switch(pieces[1]) {
      case "definitions":
        return definitions[pieces[2]].fields;

      case "parameters":
        return parameters[pieces[2]].toJson();

      default: break;
    }

    enforce(false, "", "unknwn path #/" ~ pieces[1]);

    return Json.emptyObject;
  }
}

struct Info {
  string title;
  @aliasName("version") string version_;

  @optional {
    string description;
    string termsOfService;
    Contact contact;
    License license;
  }
}

struct Contact {
  @optional {
    string name;
    string url;
    string email;
  }
}

struct License {
  @optional {
    string name;
    string url;
  }
}

struct Path {
  enum OperationsType: string {
    get = "get",
    put = "put",
    post = "post",
    delete_ = "delete",
    options = "options",
    head = "head",
    patch = "patch"
  }

  string _ref;

  Operation[OperationsType] operations;
  Parameter[] parameters;

  int opApply(int delegate(ref OperationsType, ref Operation) dg)
  {
      int result = 0;

      foreach(operationsType, operation; operations)
      {
          result = dg(operationsType, operation);
          if (result)
              break;
      }
      return result;
  }

  Operation opIndex(string key) {
    auto t = strToType(key);

    if(t !in operations) {
      operations[t] = Operation();
    }

    return operations[t];
  }

  Operation opDispatch(string key)() {
    return opIndex(key);
  }

  Json toJson() const { throw new Exception("not implemented"); };

  static Path fromJson(Json src) {
    Path path;

    foreach(string key, Json value; src) {
      if(key == "parameters") {
        foreach(parameter; value)
          path.parameters ~= Parameter.fromJson(parameter);
      } else {
        path.operations[strToType(key)] = value.deserializeJson!Operation;
      }
    }

    return path;
  }

  static OperationsType strToType(string key) {
    return key == "delete" ? OperationsType.delete_ : key.to!OperationsType;
  }
}

struct Operation {
  Response[string] responses;

  @optional {
    string[] tags;
    string summary;
    string description;
    ExternalDocumentation externalDocs;
    string operationId;
    string[] consumes;
    string[] produces;
    Parameter[] parameters;
    Schema[] schemes;
    bool isDeprecated;
    string[][string][] security;
  }
}

struct ExternalDocumentation {
  string description;

  @optional {
    string url;
  }
}

enum ParameterType: string {
  string_ = "string",
  number = "number",
  integer = "integer",
  boolean = "boolean",
  array = "array",
  file = "file"
}

enum CollectionFormat: string {
  csv = "csv",
  ssv = "ssv",
  tsv = "tsv",
  pipes = "pipes",
  multi = "multi"
}

struct Parameter {
  string reference;

  enum In: string {
    query = "query",
    header = "header",
    path = "path",
    formData = "formData",
    body_ = "body"
  }

  string name;
  In in_;

  string description;
  bool required;

  Schema schema;

  Json other;

  void updateReference(ref Swagger root) {
      if(reference != "") {
        auto fields = root.getReference(reference);

        if(fields.type == Json.Type.object) {
          foreach(string key, value; fields) {
            if(key == "name")
              name = value.to!string;
            else if(key == "in")
              in_ = stringToIn(value.to!string);
            else if(key == "description")
              description = value.to!string;
            else if(key == "required")
              required = value.to!bool;
            else if(key == "schema")
              schema.fields = value;
            else
              other[key] = value;
          }
        }
      }
  }

  Operation opDispatch(string key)() {
    return other[key];
  }

  Json toJson() const {
    Json dest = other.clone;

    dest.name = name;
    dest["in"] = in_;
    dest.description = description;
    dest.required = required;
    dest.schema = schema.fields.clone;

    return dest;
  }

  static Parameter fromJson(Json src) {
    Parameter parameter;
    parameter.other = Json.emptyObject;

    foreach(string key, value; src) {
      if(key == "$ref") {
        parameter.reference = value.to!string;
        break;
      }

      if(key == "name")
        parameter.name = src["name"].to!string;
      else if(key == "in")
        parameter.in_ = stringToIn(src["in"].to!string);

      else if(key == "description")
        parameter.description = src["description"].to!string;
      else if(key == "required")
        parameter.required = src["required"].to!bool;
      else if(key == "schema")
        parameter.schema = src["schema"].deserializeJson!Schema;
      else
        parameter.other[key] = value;
    }

    return parameter;
  }

  static In stringToIn(string value) {
    return value == "body" ? In.body_ : value.to!In;
  }
}

struct Schema {
  Json fields;

  void updateReference(ref Swagger root) {
    updateJsonRef(fields, root);
  }

  private void updateJsonRef(ref Json fields, ref Swagger root) {
    if(fields.type == Json.Type.object) {
      foreach(string key, value; fields) {
        if(key == "$ref") {
          auto references = root.getReference(fields["$ref"].to!string);

          foreach(string key, value; references)
            fields[key] = value;

        } else if(value.type == Json.Type.object) {
          updateJsonRef(value, root);
        }
      }
    }
  }

  auto opDispatch(string key)() in {
    enforce(key in fields, "`" ~ key ~ "` field not found in schema");
  } body {
    return fields[key];
  }

  string toString() const {
    return fields.toPrettyString;
  }

  Json toJson() const {
    throw new Exception("not implemented");
  }

  static Schema fromJson(Json src) {
    auto schema = Schema(src);

    if(schema.fields.type != Json.Type.object)
      schema.fields = Json.emptyObject;

    return schema;
  }
}

struct Response {
  string description;

  @optional {
    Schema schema;
    string[string] headers;
    string[string] examples;
  }
}

struct SecurityScheme {
  enum In: string {
    query = "query",
    header = "header"
  }

  enum Type: string {
    basic  = "basic",
    apiKey = "apiKey",
    oauth2 = "oauth2"
  }

  enum Flow: string {
    implicit = "implicit",
    password = "password",
    application = "application",
    accessCode = "accessCode"
  }

  @optional {
    Type type;
    string name;
    In in_;
    Flow flow;
    string authorizationUrl;
    string tokenUrl;
    string[string] scopes;
    string description;
  }
}

struct Tag {
  string name;

  @optional {
    string description;
    ExternalDocumentation externalDocs;
  }
}

bool containParameter(string item) {
  return item.indexOf('{') < item.indexOf('}');
}

bool parametrisedPathEqual(T)(T path1, T path2) {
  auto p1 = path1.array;
  auto p2 = path2.array;

  if(p1.length != p2.length) {
    return false;
  }

  foreach(index, item; p1)
    if(!item.containParameter && p2[index].containParameter && item != p2[index])
      return false;

  return true;
}

Path matchedPath(Swagger definition, string path) {
  auto pathPieces = path.pathSplitter;

  string isMatchingPath(string prevResult, string itemPath) {
    if(prevResult.length > 0)
      return prevResult;

    string tmpPath = itemPath.isRooted ?
      buildPath(definition.basePath, itemPath[1..$]).array.to!string:
      buildPath(definition.basePath, itemPath).array.to!string;

    if(tmpPath.pathSplitter.parametrisedPathEqual(pathPieces)) {
      return itemPath;
    }

    return prevResult;
  }

  auto matched = reduce!(isMatchingPath)("", definition.paths.keys);

  if(matched !in definition.paths)
    throw new Exception("page `"~path~"` not found");

  return definition.paths[matched];
}

@testName("it should match unparametrised paths")
unittest {
  Swagger definition;
  definition.paths["/test"] = Path();
  definition.paths["/test"]._ref = "ref";

  assert(definition.matchedPath("/test")._ref == "ref");
}

@testName("it should match parametrised paths")
unittest {
  Swagger definition;
  definition.paths["/test/{id}"] = Path();
  definition.paths["/test/{id}"]._ref = "ref";

  assert(definition.matchedPath("/test/1")._ref == "ref");
}

@testName("it should match unparametrised paths that have a base path")
unittest {
  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"]._ref = "ref";

  assert(definition.matchedPath("/api/test")._ref == "ref");
}

Operation get(Operation[Path.OperationsType] operations, HTTPMethod method) {
  switch(method) {
    case HTTPMethod.GET: return operations[Path.OperationsType.get];
    case HTTPMethod.POST : return operations[Path.OperationsType.post];
    case HTTPMethod.DELETE : return operations[Path.OperationsType.delete_];
    case HTTPMethod.OPTIONS : return operations[Path.OperationsType.options];
    case HTTPMethod.HEAD : return operations[Path.OperationsType.head];
    case HTTPMethod.PATCH : return operations[Path.OperationsType.patch];

    default:
      throw new Exception("method not found");
  }
}

Operation getSwaggerOperation(HTTPServerRequest request, Swagger definition) {
  return definition.matchedPath(request.path).operations.get(request.method);

}
