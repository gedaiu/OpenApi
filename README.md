# Swaggarize
[![Build Status](https://travis-ci.org/gedaiu/swaggarize.svg?branch=master)](https://travis-ci.org/gedaiu/swaggarize)

Swagger library for D programming language

## How to use it

### Create handlers
```
module myapp.handlers;

import vibe.d;
import swaggerize.composites;

@swaggerPath("/hello", OperationsType.options)
void optionsList(string name)(HTTPServerRequest /*req*/, HTTPServerResponse res) {
  res.writeBody("hello world!");
}
```
### Create vibe.d instance

```
import vibe.d;
import swaggerize.parser;
import swaggerize.composites;
import myapp.handlers;

MongoClient client;

shared static this()
{
  auto definitions = swaggerizeJson("./api.json");

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.options = HTTPServerOption.parseQueryString | HTTPServerOption.parseJsonBody;

  client = connectMongoDB("127.0.0.1");

  auto router = new URLRouter;
  router.register!(myapp.handlers)(definitions);

  listenHTTP(settings, router);
}

```
