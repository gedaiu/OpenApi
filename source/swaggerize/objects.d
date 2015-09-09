/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.object;

import std.traits;
import std.conv;

enum Schemes: string {
  http = "http",
  https = "https",
  ws = "ws",
  wss = "wss"
}

struct Swagger {
  string swagger;
  Info info;
  string host;
  string basePath;
  Schemes[] schemes;
  string[] consumes;
  string[] produces;
  Path[string] paths;
  Schema[string] definitions;
  Parameter[] parameters;
  Response[string] responses;
  SecurityScheme[string] securityDefinitions;
  string[string] security;
  Tag[] tags;
  ExternalDocumentation externalDocs;
}

struct Info {
  string title;
  string description;
  string termsOfService;
  Contact contact;
  License license;
  string ver;
}

struct Contact {
  string name;
  string url;
  string email;
}

struct License {
  string name;
  string url;
}

enum OperationsType: string {
  get = "get",
  put = "put",
  post = "post",
  delete_ = "delete",
  options = "options",
  head = "head",
  patch = "patch"
}

struct Path {
  string _ref;

  Operation[OperationsType] operations;
  Parameter[] parameters;

  Operation opIndex(string key) {
    return operations[key.to!OperationsType];
  }

  Operation opDispatch(string key)() {
    return operations[key.to!OperationsType];
  }
}

struct Operation {
  string[] tags;
  string summary;
  string description;
  ExternalDocumentation externalDocs;
  string operationId;
  string[] consumes;
  string[] produces;
  Parameter[] parameters;
  Response[string] responses;
  Schema[] schemes;
  bool isDeprecated;
  string[string] security;
}

struct ExternalDocumentation {
  string description;
  string url;
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
  immutable In in_;
  string description;
  bool required;

  Schema schema;

  mixin SchemaFields;
}


mixin template SchemaFields() {
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

  ParameterType type;
  string format;
  bool allowEmptyValue;
  Schema[] items;
  CollectionFormat collectionFormat = collectionFormat.csv;
  string default_;

  double maximum;
  bool exclusiveMaximum;
  double minimum;
  bool maxLength;

  long minLength;
  string pattern;

  size_t maxItems;
  size_t minItems;
  bool uniqueItems;
  string[] enum_;
  double multipleOf;
}

struct Schema {
  mixin SchemaFields;
}

struct Response {
  string description;
  Schema schema;
  string[string] headers;
  string[string] examples;
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

  Type type;
  string description;
  string name;
  In in_;
  Flow flow;
  string authorizationUrl;
  string tokenUrl;
  string[string] scopes;
}

struct Tag {
  string name;
  string description;
  ExternalDocumentation externalDocs;
}
