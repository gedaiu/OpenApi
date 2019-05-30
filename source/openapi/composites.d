/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 13, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.composites;

import std.stdio, std.traits, std.exception, std.conv;
import vibe.http.server;
import vibe.http.router;
import openapi.definitions;
import openapi.exceptions;

alias VibeHandler = void function(HTTPServerRequest, HTTPServerResponse);

struct swaggerPath {
  string path;
  OperationsType type;

  @property string vibePath() {
    import std.array : replace;
    return path.replace("{", ":").replace("}", "");
  }
}

struct ErrorOutput {
  string[] errors;

  this(Throwable e) {
    errors ~= e.msg;
  }
}

template Alias(alias S)
{
  alias Alias = S;
}

private string alignString(string path, int max = 30) {
  if(path.length < max) {
    foreach(i; path.length..max) {
      path ~= ' ';
    }
  }

  return path;
}

VibeHandler[string][OperationsType] findComposites(BaseModule...)() {
  import std.uni: toUpper;

  VibeHandler[string][OperationsType] list;

  static if(__traits(allMembers, BaseModule).length > 0) {
    pragma(msg, "\nMap OpenApi Paths:");

    foreach(symbol_name; __traits(allMembers, BaseModule))
    {
      static if(symbol_name.length < 12 || symbol_name[3..12] != "TypeInfo_") {
        static if(__traits(compiles, typeof(Alias!(__traits(getMember, BaseModule, symbol_name))))) {
          alias symbol = Alias!(__traits(getMember, BaseModule, symbol_name));
          static if(__traits(compiles, typeof(symbol)) && isSomeFunction!symbol) {
            foreach(attr; __traits(getAttributes, symbol)) {
              static if(attr.stringof.length > 12 && attr.stringof[0..12] == "swaggerPath(") {
                pragma(msg, alignString(attr.type, 8), alignString(attr.path), " => ", symbol_name);
                list[attr.vibePath][attr.type] = &symbol;
              }
            }
          }
        }
      }
    }
    pragma(msg, "\n");
  }

  return list;
}

auto validation(VibeHandler handler, OpenApi definitions) {
  import openapi.validation;

  void doValidation(HTTPServerRequest req, HTTPServerResponse res) {
    writeln(req.method.to!string ~ " " ~ req.path);
    try {
      req.validate!(ParameterIn.path)(definitions);
      req.validate!(ParameterIn.query)(definitions);
      req.validate!(ParameterIn.header)(definitions);
      req.validateBody(definitions);

      handler(req, res);
    } catch(OpenApiValidationException e) {
      res.writeJsonBody(ErrorOutput(e), HTTPStatus.badRequest);
      debug {
        writeln(e);
      }
    } catch(OpenApiParameterException e) {
      res.writeJsonBody(ErrorOutput(e), HTTPStatus.badRequest);
      debug {
        writeln(e);
      }
    } catch(OpenApiNotFoundException e) {
      res.writeJsonBody(ErrorOutput(e), HTTPStatus.notFound);
      debug {
        writeln(e);
      }
    } catch(Throwable e) {
      res.writeJsonBody(ErrorOutput(e), HTTPStatus.internalServerError);

      debug {
        writeln(e);
        res.writeJsonBody(ErrorOutput(e));
      } else {
        res.writeBody("{ errors: [\"Internal server error\"] }");
      }
    }
  }

  return &doValidation;
}

void register(BaseModule...)(URLRouter router) {
  enum auto handlers = findComposites!BaseModule;

  foreach(path, methods; handlers) {
    with (router.route(path)) {
      foreach(method, handler; methods) {
        switch(method) {
          case OperationsType.get:
            get(handler);
            break;
          case OperationsType.put:
            put(handler);
            break;
          case OperationsType.post:
            post(handler);
            break;
          case OperationsType.delete_:
            delete_(handler);
            break;
          case OperationsType.patch:
            patch(handler);
            break;
          default:
            enforce("method `" ~ method ~ "` not found");
        }
      }
    }
  }
}

void register(BaseModule...)(URLRouter router, OpenApi definitions) {
  const auto handlers = findComposites!BaseModule;

  auto basePath = definitions.basePath == "/" ? "" : definitions.basePath;

  foreach(path, methods; handlers) {
    with (router.route(basePath ~ path)) {
      foreach(method, handler; methods) {
        switch(method) {
          case OperationsType.get:
            get(handler.validation(definitions));
            break;
          case OperationsType.put:
            put(handler.validation(definitions));
            break;
          case OperationsType.post:
            post(handler.validation(definitions));
            break;
          case OperationsType.delete_:
            delete_(handler.validation(definitions));
            break;
          case OperationsType.patch:
            patch(handler.validation(definitions));
            break;
          case OperationsType.options:
            match(HTTPMethod.OPTIONS, handler.validation(definitions));
            break;
          default:
            enforce("method `" ~ method ~ "` not found");
        }
      }
    }
  }
}
