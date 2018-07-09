/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 9, 2018
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.test.parse;

import std.file;
import openapi.definitions;
import openapi.parser;
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

    it("should parse the countries `path` section", {
      string key = "/api/v1/system/countries";

      Path.fromJson(document["paths"][key])
        .serializeToJson
        .should
        .equal(document["paths"][key]);
    });

    it("should parse the dataset `path` section", {
      string key = "/api/v1/company/{id}/{dataset}";

      Path.fromJson(document["paths"][key])
        .serializeToJson
        .should
        .equal(document["paths"][key]);
    });

    it("should parse the announcements `path` section", {
      string key = "/api/v1/company/{id}/announcements";

      Path.fromJson(document["paths"][key])
        .serializeToJson
        .should
        .equal(document["paths"][key]);
    });

    it("should parse the availability `path` section", {
      string key = "/api/v1/product/availability/{sku}/{subjectId}";

      Path.fromJson(document["paths"][key])
        .serializeToJson
        .should
        .equal(document["paths"][key]);
    });

    it("should parse the retreive `path` section", {
      string key = "/api/v1/pepsanction/retrieve/{id}";

      Path.fromJson(document["paths"][key])
        .serializeToJson.should
        .equal(document["paths"][key]);
    });

    it("should parse a `path` section", {
      foreach(item; document["paths"].byKeyValue) {
        auto val = item.value;

        Path.fromJson(val).serializeToJson
          .should.equal(val).because(item.key);
      }
    });

    it("should parse the `paths` section", {
      document["paths"]
        .deserializeJson!(Path[string])
        .serializeToJson
        .should
        .equal(document["paths"]);
    });

    it("should parse the `components` section", {
      document["components"].deserializeJson!Components
        .serializeToJson
        .should
        .equal(document["components"]);
    });

    it("should parse the `schema` section", {
      document["paths"]["/api/v1/system/countries"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]
        .deserializeJson!Schema
        .serializeToJson
        .should
        .equal(document["paths"]["/api/v1/system/countries"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]);
    });

    it("should be the same document after serialization", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("api with examples", {
    Json document;

    before({
      document = readText("test/examples/api-with-examples.json").parseJsonString;
    });

    it("should parse the 200 response example", {
      document["paths"]["/"]["get"]["responses"]["200"]["content"]["application/json"]["examples"]["foo"]
        .deserializeJson!Example
        .serializeToJson
        .should
        .equal(document["paths"]["/"]["get"]["responses"]["200"]["content"]["application/json"]["examples"]["foo"]);
    });

    it("should parse the 300 response example", {
      document["paths"]["/"]["get"]["responses"]["300"]["content"]["application/json"]["examples"]["foo"]
        .deserializeJson!Example
        .serializeToJson
        .should
        .equal(document["paths"]["/"]["get"]["responses"]["300"]["content"]["application/json"]["examples"]["foo"]);
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("callback examples", {
    Json document;

    before({
      document = readText("test/examples/callback-example.json").parseJsonString;
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("link examples", {
    Json document;

    before({
      document = readText("test/examples/link-example.json").parseJsonString;
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("openTargets api", {
    Json document;

    before({
      document = readText("test/examples/openTargets.json").parseJsonString;
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("pet store expanded examples", {
    Json document;

    before({
      document = readText("test/examples/petstore-expanded.json").parseJsonString;
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("pet store examples", {
    Json document;

    before({
      document = readText("test/examples/petstore.json").parseJsonString;
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("uspto examples", {
    Json document;

    before({
      document = readText("test/examples/uspto.json").parseJsonString;
    });

    it("should parse the / 200 MediaType example", {
      document["paths"]["/"]["get"]["responses"]["200"]["content"]["application/json"]
        .deserializeJson!MediaType
        .serializeToJson
        .should
        .equal(document["paths"]["/"]["get"]["responses"]["200"]["content"]["application/json"]);
    });

    it("should parse the json", {
      document.deserializeJson!OpenApi;

      document.deserializeJson!OpenApi.serializeToJson
        .should
        .equal(document);
    });
  });

  describe("openapiJson should update the references", {
    it("should update the references from link examples", {
      auto api = openApiFromJson("test/examples/link-example.json");

      api.paths["/2.0/users/{username}"][OperationsType.get]
        .responses["200"].content["application/json"]
        .schema.type
        .should.equal(SchemaType.object);
    });
  });
});
