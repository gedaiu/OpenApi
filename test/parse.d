/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2018
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.test.parse;

import std.file;
import openapi.definitions;
import fluent.asserts;

import vibe.data.json;

import trial.discovery.spec;

private alias suite = Spec!({
  describe("brex.io api", {
    Json document;

    before({
      document = readText("test/examples/brex-io.json").parseJsonString;
    });

    it("should parse the `servers` section", {
      document["servers"].deserializeJson!(Server[]).serializeToJson
        .should
        .equal(document["servers"]);
    });

    it("should parse the `info` section", {
      document["info"].deserializeJson!Info.serializeToJson
        .should
        .equal(document["info"]);
    });
    
    /*
    it("should be the same document after serialization", {
      document.deserializeJson!OpenApi.serializeToJson.toPrettyString
        .should
        .equal(document.toPrettyString);
    });
    */
  });
});
