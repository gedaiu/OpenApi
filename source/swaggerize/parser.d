/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 8, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.parser;

import swaggerize.definitions;
import vibe.data.json;
import std.file, std.traits, std.stdio;

Swagger updateReferences(Swagger definition) {
  foreach(name, schema; definition.definitions) {
    schema.updateReference(definition);
  }

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
