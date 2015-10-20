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
import std.datetime;
import std.stdio;

import tested: testName = name;

@testName("it should raise exception when path validation fails")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test/asd";
  request.params["id"] = "asd";
  request.headers["Content-Type"] = "application/json";

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
  request.headers["Content-Type"] = "application/json";

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
  request.headers["Content-Type"] = "application/json";

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
  request.headers["Content-Type"] = "application/json";

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

  request.validate!(Parameter.In.query)(definition);
}

@testName("it should raise exception when query parameter is missing")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.headers["Content-Type"] = "application/json";

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
  request.headers["Content-Type"] = "application/json";

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

@testName("it should not raise exception when there is an extra header parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.headers["id"] = "123";
  request.headers["Content-Type"] = "application/json";

  Operation operation;
  operation.responses["200"] = Response();

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  request.validateExistence!(Parameter.In.header)(definition);
}

@testName("it should raise exception when there is an extra required header parameter")
unittest {
  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/api/test";
  request.headers["id"] = "123";
  request.headers["Content-Type"] = "application/json";

  Parameter parameter;
  parameter.in_ = Parameter.In.header;
  parameter.name = "id";
  parameter.required = true;
  parameter.other = Json.emptyObject;
  parameter.other["type"] = "integer";

  Operation operation;
  operation.responses["200"] = Response();

  Swagger definition;
  definition.basePath = "/api";
  definition.paths["/test"] = Path();
  definition.paths["/test"].operations[Path.OperationsType.get] = operation;

  bool exceptionRaised = false;

  try {
    request.validateExistence!(Parameter.In.header)(definition);
  } catch(SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(!exceptionRaised);
}

@testName("it should raise exception when required body root property is missing")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should raise exception when body type is invalid")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ "department": "hello" }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (SwaggerValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should raise exception when required schema property is missing")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ "department": { } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}


@testName("it should raise exception when extra params are found")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ "department": { "number": "one", "name": "hello" } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised = false;

  try {
    request.validateBody(definition);
  } catch (SwaggerParameterException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should raise exception when schema type is invalid")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ "department": { "number": "one" }  }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  bool exceptionRaised;

  try {
    request.validateBody(definition);
  } catch (SwaggerValidationException e) {
    exceptionRaised = true;
  }

  assert(exceptionRaised);
}

@testName("it should not raise exception when body data is valid")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department";
  request.json = `{ "department": { "number": 1 }  }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  request.validateBody(definition);
}


@testName("it should not raise exception when nested body data is valid")
unittest {
  auto definition = swaggerizeYaml("./source/test/examples/bodyValidation.yaml");

  HTTPServerRequest request = new HTTPServerRequest(Clock.currTime, 8080);
  request.method = HTTPMethod.GET;
  request.path = "/department_deep";
  request.json = `{ "department": {"data": {"number": 1 } } }`.parseJsonString;
  request.headers["Content-Type"] = "application/json";

  request.validateBody(definition);
}
