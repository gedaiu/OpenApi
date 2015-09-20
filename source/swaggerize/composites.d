/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 9 13, 2015
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module swaggerize.composites;

import std.stdio, std.traits, std.exception;
import vibe.http.server;
import vibe.http.router;
import swaggerize.definitions;

alias OperationsType = Path.OperationsType;
alias VibeHandler = void function(HTTPServerRequest, HTTPServerResponse);

struct swaggerPath {
	string path;
	OperationsType type;

	@property string vibePath() {
		import std.array : replace;
		return path.replace("{", ":").replace("}", "");
	}
}

template Alias(alias S)
{
	alias Alias = S;
}

VibeHandler[string][OperationsType] findComposites(BaseModule...)() {
  VibeHandler[string][OperationsType] list;

	static if(__traits(allMembers, BaseModule).length > 0) {
		pragma(msg, "\nMap Swagger Paths:");

		foreach(symbol_name; __traits(allMembers, BaseModule))
		{
			static if(symbol_name.length < 12 || symbol_name[0..12] != "D51TypeInfo_") {
				alias symbol = Alias!(__traits(getMember, BaseModule, symbol_name));
				static if (isSomeFunction!symbol) {
					foreach(attr; __traits(getAttributes, symbol)) {
						static if(attr.stringof.length > 12 && attr.stringof[0..12] == "swaggerPath(") {
							pragma(msg, symbol_name, " => ", attr.type, " ", attr.path);
							list[attr.vibePath][attr.type] = &symbol;
						}
					}
				}
			}
	  }
		pragma(msg, "\n");
	}

	return list;
}

void register(BaseModule...)(URLRouter router) {
	const auto handlers = findComposites!BaseModule;

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
