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

    it("should parse the `tags` section", {
      document["tags"].deserializeJson!(Tag[]).serializeToJson
        .should
        .equal(document["tags"]);
    });

    it("should parse one `path` section", {
      string key = "/api/v1/system/countries";

      Path.fromJson(document["paths"][key])
        .serializeToJson
        .should
        .equal(document["paths"][key]);
    });

/*
    it("should parse the `paths` section", {
      document["paths"].deserializeJson!(Path[string]).serializeToJson
        .should
        .equal(document["paths"]);
    });
/*
    it("should parse the `components` section", {
      document["components"].deserializeJson!Components.serializeToJson
        .should
        .equal(document["components"]);
    });*/

    it("should parse the `schema` section", {
      document["paths"]["/api/v1/system/countries"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]
        .deserializeJson!Schema.toJson
        .should
        .equal(document["paths"]["/api/v1/system/countries"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]);
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
