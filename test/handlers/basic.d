/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 13, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.test.handlers.basic;

import vibe.d;
import openapi.composites;

struct other {}

@swaggerPath("/test", OperationsType.get)
void testGet(HTTPServerRequest /*req*/, HTTPServerResponse /*res*/) {
  throw new Exception("Not implemented.");
}

@other()
void testInvalid(HTTPServerRequest /*req*/, HTTPServerResponse /*res*/) {
  throw new Exception("Not implemented.");
}
