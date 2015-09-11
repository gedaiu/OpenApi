/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 8, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.parser;

import swaggerize.definitions;
import vibe.data.json;
import std.file;

Swagger swaggerizeJson(string path) {
  auto definitions = readText(path).deserializeJson!Swagger;

  foreach(url, path; definitions.paths) {
    foreach(operationName, operation; path) {
      foreach(responseCode, response; operation.responses) {
        std.stdio.writeln(url, " ", operationName, " ", responseCode);
        definitions.paths[url][operationName].responses[responseCode].schema.updateReference(definitions);
      }
    }

    foreach(i, parameter; path.parameters) {
      definitions.paths[url].parameters[i].updateReference(definitions);
    }
  }

  return definitions;
}
