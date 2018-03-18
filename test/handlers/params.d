/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 17, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.test.handlers.params;

import vibe.d;
import openapi.composites;
import openapi.definitions;

@swaggerPath("/test/{param}", OperationsType.get)
void testParam(HTTPServerRequest /*req*/, HTTPServerResponse /*res*/) {
  throw new Exception("Not implemented.");
}
