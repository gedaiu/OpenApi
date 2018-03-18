/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 13, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.test.composites;

import openapi.composites;
import openapi.definitions;
import std.stdio;
import vibe.http.router;
static import openapi.test.handlers.basic;

@("It should find the handlers")
unittest {
  const auto composites = findComposites!(openapi.test.handlers.basic);

  assert(composites["/test"][OperationsType.get] == &openapi.test.handlers.basic.testGet);
}

@("It should register the routes")
unittest {
  URLRouter router = new URLRouter;
/*
  router.register!(openapi.test.handlers.basic);

  const auto routes = router.getAllRoutes;

  assert(routes.length == 1);
  assert(routes[0].pattern == "/test");
  assert(routes[0].method == HTTPMethod.GET);
  assert(routes[0].cb !is null);*/
}

@("It should register the parametrised routes")
unittest {
  URLRouter router = new URLRouter;

  router.register!(openapi.test.handlers.params);

  const auto routes = router.getAllRoutes;

  assert(routes.length == 1);
  assert(routes[0].pattern == "/test/:param");
  assert(routes[0].method == HTTPMethod.GET);
  assert(routes[0].cb !is null);
}
