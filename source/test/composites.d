/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 13, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.test.composites;

import swaggerize.composites;
import std.stdio;
import vibe.http.router;

//@testName("It should find the handlers")
unittest {
  const auto composites = findComposites!(swaggerize.test.handlers.basic);

  assert(composites["/test"][OperationsType.get] == &swaggerize.test.handlers.basic.testGet);
}

//@testName("It should register the routes")
unittest {
  URLRouter router = new URLRouter;
/*
  router.register!(swaggerize.test.handlers.basic);

  const auto routes = router.getAllRoutes;

  assert(routes.length == 1);
  assert(routes[0].pattern == "/test");
  assert(routes[0].method == HTTPMethod.GET);
  assert(routes[0].cb !is null);*/
}

//@testName("It should register the parametrised routes")
unittest {
  URLRouter router = new URLRouter;

  router.register!(swaggerize.test.handlers.params);

  const auto routes = router.getAllRoutes;

  assert(routes.length == 1);
  assert(routes[0].pattern == "/test/:param");
  assert(routes[0].method == HTTPMethod.GET);
  assert(routes[0].cb !is null);
}
