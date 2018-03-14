/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 29, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.test.validation;

import swaggerize.validation;
import swaggerize.definitions;
import swaggerize.parser;
import swaggerize.exceptions;

import vibe.http.server;
import vibe.data.json;
//import vibe.core.path : GenericPath;
import std.datetime;
import std.stdio;

//alias VibePath = GenericPath!(vibe.core.path.InetPathFormat);
/*
@("it should raise exception when path validation fails")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test/asd");
  request.params["id"] = "asd";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.path;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test/{id}"] = Path();
  definition.paths["/test/{id}"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(ParameterIn.path)(definition);
  } catch(OpenApiValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should not raise exception when path validation succedes")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test/1");
  request.params["id"] = "1";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.path;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test/{id}"] = Path();
  definition.paths["/test/{id}"].operations[Path.OperationsType.get] = operation;

  request.validate!(ParameterIn.path)(definition);
}

@("it should raise exception when query validation fails")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.query["id"] = "asd";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(ParameterIn.query)(definition);
  } catch(OpenApiValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should not raise exception when query succedes")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.query["id"] = "123";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  request.validate!(ParameterIn.query)(definition);
}

@("it should raise exception when query parameter is missing")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.query;
  parameter.name = "id";
  parameter.required = true;
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(ParameterIn.query)(definition);
  } catch(OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should raise exception when there is an extra query parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.query["id"] = "123";
  request.query["value"] = "123";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.query;
  parameter.name = "id";
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();
  operation.parameters ~= parameter;

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validate!(ParameterIn.query)(definition);
  } catch(OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should not raise exception when there is an extra header parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.headers["id"] = "123";
  request.headers["Content-Type"] = "application/json";

  Operation operation;
  operation.responses["200"] = Response();

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  request.validateExistence!(ParameterIn.header)(definition);
}

@("it should raise exception when there is an extra required header parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/api/test");
  request.headers["id"] = "123";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = ParameterIn.header;
  parameter.name = "id";
  parameter.required = true;
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();

  OpenApi definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validateExistence!(ParameterIn.header)(definition);
  } catch(OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(!exceptionRaised);
}

@("it should raise exception when required body root property is missing")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should raise exception when body type is invalid")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ "department": "hello" }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (OpenApiValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should raise exception when required schema property is missing")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ "department": { } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}


@("it should raise exception when extra params are found")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ "department": { "number": "one", "name": "hello" } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (OpenApiParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should raise exception when schema type is invalid")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ "department": { "number": "one" }  }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised;

  try {
    request.validateBody(definition);
  } catch (OpenApiValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@("it should not raise exception when body data is valid")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department");
  request.json = `{ "department": { "number": 1 }  }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  request.validateBody(definition);
}

@("it should not raise exception when nested body data is valid")
unittest {
  auto definition = swaggerizeJson("./source/test/examples/bodyValidation.json");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.requestPath = VibePath.fromString("/department_deep");
  request.json = `{ "department": {"data": {"number": 1 } } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  request.validateBody(definition);
}
*/