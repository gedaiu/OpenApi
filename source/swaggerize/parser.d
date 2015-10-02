/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 8, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.parser;

import swaggerize.definitions;
import vibe.data.json;
import yaml;
import std.file, std.traits, std.stdio;

Json toJson(Node node) {
  Json item;

  if(node.isMapping) {
    item = Json.emptyObject;

    foreach(string key, Node value; node) {
      item[key] = value.toJson;
    }
  }

  if(node.isSequence) {
    item = Json.emptyArray;

    foreach(Node value; node) {
      item ~= value.toJson;
    }
  }

  if(node.isScalar) {
    if(node.isType!bool) {
      item = Json(node.as!bool);
    } else if(node.isType!long) {
      item = Json(node.as!long);
    } else {
      item = Json(node.as!string);
    }
  }

  return item;
}

Swagger updateReferences(Swagger definition) {
  foreach(url, path; definition.paths) {
    foreach(operationName, operation; path) {
      foreach(responseCode, response; operation.responses) {
        definition.paths[url][operationName].responses[responseCode].schema.updateReference(definition);
      }

      foreach(i, parameter; path[operationName].parameters) {
        definition.paths[url][operationName].parameters[i].updateReference(definition);
      }
    }

    foreach(i, parameter; path.parameters) {
      definition.paths[url].parameters[i].updateReference(definition);
    }
  }

  return definition;
}

Swagger swaggerizeJson(string path) {
  return readText(path).deserializeJson!Swagger.updateReferences;
}

Swagger swaggerizeYaml(string path) {
  return Loader(path).load.toJson.deserializeJson!Swagger.updateReferences;
}
