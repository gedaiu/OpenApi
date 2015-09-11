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

//@name("Check if the definitions are imported from uber definitions")
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

//@name("Check if the definitions are imported from instagram definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/instagram.json");

  assert(definitions.info.title == "Instagram API");
  assert(definitions.paths["/users/{user-id}"].parameters[0].name == "user-id");
}

//@name("Check if the definitions are imported from basic auth definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/basic_auth.json");

  assert(definitions.info.title == "Basic Auth Example");
}

//@name("Check if the definitions are imported from minimal definitions")
unittest {
  auto definitions = swaggerizeJson("./source/test/examples/minimal.json");

  assert(definitions.info.title == "Simple API");
}
