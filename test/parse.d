/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2018
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.test.parse;

import std.file;
import swaggerize.parser;
import fluent.asserts;

import vibe.data.json;

/// Check if the definitions from api-with-examples.yaml
unittest {
  auto definitions = openApiFromJson("test/examples/callback-example.json");

  readText("test/examples/callback-example.json")
    .parseJsonString
    .toPrettyString
      .should
      .equal(definitions.serializeToJson.toPrettyString);
}