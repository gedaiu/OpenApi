/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.test.parse;

import swaggerize.parser;
import vibe.data.json;
import std.stdio;

@("Check if the definitions are imported from uber definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/uber.json");

  assert(definitions.swagger == "2.0");
  assert(definitions.info.title == "Uber API");
  assert(definitions.schemes[0] == "https");
  assert(definitions.paths["/products"]["get"].summary == "Product Types");
  assert(definitions.paths["/products"].get.summary == "Product Types");

  assert(definitions.paths["/products"].get.parameters[0].name == "latitude");
  assert(definitions.paths["/products"].get.tags[0] == "Products");
  assert(definitions.paths["/products"].get.responses["default"].schema.type == "object");
}

@("Check if the definitions are imported from instagram definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/instagram.json");

  assert(definitions.info.title == "Instagram API");
  assert(definitions.paths["/users/{user-id}"].parameters[0].name == "user-id");
}

@("Check if the definitions are imported from basic auth definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/basic_auth.json");

  assert(definitions.info.title == "Basic Auth Example");
}

@("Check if the definitions are imported from minimal definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/minimal.json");

  assert(definitions.info.title == "Simple API");
}

@("Check if the definitions are imported from pet store definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/petstore.json");

  assert(definitions.info.title == "PetStore on Heroku");
}

@("Check if the definitions are imported from pet store full definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/petstore_full.json");

  assert(definitions.info.title == "Swagger Petstore");
}

@("Check if the definitions are imported from security definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/security.json");

  assert(definitions.info.title == "Swagger Sample API");
  assert(definitions.paths["/pets/{id}"].get.responses["200"].schema.items["type"] == "object");
}

@("Check if the definitions are imported from twitter definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/twitter.json");

  assert(definitions.info.title == "Twitter REST API");
}

// Same as above but parse yaml files

@("Check if the definitions are imported from uber definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/uber.json");

  assert(definitions.swagger == "2.0");
  assert(definitions.info.title == "Uber API");
  assert(definitions.schemes[0] == "https");
  assert(definitions.paths["/products"]["get"].summary == "Product Types");
  assert(definitions.paths["/products"].get.summary == "Product Types");

  assert(definitions.paths["/products"].get.parameters[0].name == "latitude");
  assert(definitions.paths["/products"].get.tags[0] == "Products");
  assert(definitions.paths["/products"].get.responses["default"].schema.type == "object");
}

@("Check if the definitions are imported from instagram definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/instagram.json");

  assert(definitions.info.title == "Instagram API");
  assert(definitions.paths["/users/{user-id}"].parameters[0].name == "user-id");
}

@("Check if the definitions are imported from basic auth definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/basic_auth.json");

  assert(definitions.info.title == "Basic Auth Example");
}

@("Check if the definitions are imported from minimal definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/minimal.json");

  assert(definitions.info.title == "Simple API");
}

@("Check if the definitions are imported from pet store definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/petstore.json");

  assert(definitions.info.title == "PetStore on Heroku");
}

@("Check if the definitions are imported from pet store full definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/petstore_full.json");

  assert(definitions.info.title == "Swagger Petstore");
}

@("Check if the definitions are imported from security definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/security.json");

  assert(definitions.info.title == "Swagger Sample API");
  assert(definitions.paths["/pets/{id}"].get.responses["200"].schema.items["type"] == "object");
}

@("Check if the definitions are imported from twitter definitions")
unittest {
  const auto definitions = swaggerizeJson("./source/test/examples/twitter.json");

  assert(definitions.info.title == "Twitter REST API");
}
