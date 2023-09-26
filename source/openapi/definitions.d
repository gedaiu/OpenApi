/**
 * Authors: Szabo Bogdan <szabobogdan@yahoo.com>
 * Date: 13 3, 2018
 * License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
 * Copyright: Public Domain
 */
module openapi.definitions;

import std.traits;
import std.array;
import std.algorithm;
import std.conv;
import std.typecons;
import std.stdio;
import std.math;

import vibe.data.json;
import vibe.data.serialization : SerializedName = name;

private string memberToKey(alias member)() pure {
  static if(member[$-1..$] == "_") {
    return member[0..$-1];
  } else {
    return member;
  }
}

///
Type toEnumValue(Type)(string value) {
  foreach(member; EnumMembers!Type) {{
    if((cast(OriginalType!Type) member).to!string == value) {
      return member;
    }
  }}

  throw new Exception("`" ~ value ~ "` is not a member in `" ~ Type.stringof ~ "`");
}

OriginalType!Type toOriginalEnumValue(Type)(Type value) {
  return cast(OriginalType!Type) value;
}

mixin template Serialization(T) {

  @trusted:
    Json[string] extensions;

    ///
    Json toJson() const {
      auto dest = Json.emptyObject;

      static if(__traits(hasMember, T, "_ref")) {
        if(_ref != "") {
          dest["$ref"] = _ref;
          return dest;
        }
      }

      static foreach (member; __traits(allMembers, T))
        static if(member != "extensions" && !isCallable!(__traits(getMember, T, member))) {{
          alias Type = typeof(__traits(getMember, this, member));


          auto tmp = __traits(getMember, this, member);

          static if(is(Type == class)) {
            Json value;

            if(tmp is null) {
              value = Json.undefined;
            } else {
              value = tmp.serializeToJson;
            }
          } else static if(!isSomeString!Type && (isArray!Type || isAssociativeArray!Type)) {
            auto value = tmp.serializeToJson;
          } else static if(is(Unqual!Type == bool)) {
            auto value = tmp ? Json(true) : Json.undefined;
          } else static if(isSomeString!Type || isBuiltinType!Type) {
            auto value = Json(tmp);
          } else {
            auto value = tmp.serializeToJson;
          }

          alias key = memberToKey!member;

          if(value.type == Json.Type.array && value.length == 0) {
            value = Json.undefined;
          }

          if(value.type == Json.Type.object && value.length == 0) {
            value = Json.undefined;
          }

          if(value.type == Json.Type.string && value == "") {
            value = Json.undefined;
          }

          if(value.type != Json.Type.undefined) {
            dest[key] = value;
          }
        }}

      foreach(string key, Json value; extensions) {
        dest[key] = value;
      }

      return dest;
    }

    ///
    static T fromJson(Json src) {
      T value;

      static if(__traits(hasMember, T, "_ref")) {
        if("$ref" in src) {
          value._ref = src["$ref"].to!string;
          return value;
        }
      }

      static foreach (member; __traits(allMembers, T))
        static if(member != "extensions" && !isCallable!(__traits(getMember, T, member))) {{
          alias Type = typeof(__traits(getMember, value, member));
          alias key = memberToKey!member;
          Type tmp;

          if(key in src) {
            static if(is(Type == enum)) {
              tmp = src[key].to!string.toEnumValue!Type;
            } else static if(isSomeString!Type) {
              tmp = src[key].to!Type;
            } else static if (isArray!Type) {
              tmp = src[key].deserializeJson!Type;
            } else static if(isAssociativeArray!Type) {
              tmp = src[key].deserializeJson!Type;
            } else static if(!isSomeString!Type && (isAggregateType!Type || isArray!Type || isAssociativeArray!Type)) {
              tmp = src[key].deserializeJson!Type;
            } else {
              tmp = src[key].to!Type;
            }

            __traits(getMember, value, member) = tmp;
          }
        }}

      value.extensions = src.byKeyValue.filter!(a => a.key.startsWith("x-")).assocArray;

      return value;
    }
}

///
enum Schemes: string {
  http = "http",
  https = "https",
  ws = "ws",
  wss = "wss"
}

///
struct OpenApi {
  /// This string MUST be the semantic version number of the OpenApi Specification
  /// version that the OpenApi document uses. The openapi field SHOULD be used by
  /// tooling specifications and clients to interpret the OpenApi document. This
  /// is not related to the API info.version string
  string openapi = "3.0.1";

  /// Provides metadata about the API. The metadata MAY be used by tooling as required
  Info info;

  /// The available paths and operations for the API
  Path[string] paths;

  @optional {
    /// An array of Server Objects, which provide connectivity information to a
    /// target server. If the servers property is not provided, or is an empty
    /// array, the default value would be a Server Object with a url value of /
    Server[] servers;

    /// An element to hold various schemas for the specification
    Components components;

    /// A declaration of which security mechanisms can be used across the API.
    /// The list of values includes alternative security requirement objects
    /// that can be used. Only one of the security requirement objects need
    /// to be satisfied to authorize a request. Individual operations can
    /// override this definition
    SecurityRequirement security;

    /// A list of tags used by the specification with additional metadata.
    /// The order of the tags can be used to reflect on their order by
    /// the parsing tools. Not all tags that are used by the Operation
    /// Object must be declared. The tags that are not declared MAY be organized
    /// randomly or based on the tools' logic. Each tag name in the list MUST be unique.
    Tag[] tags;

    /// Additional external documentation.
    ExternalDocumentation externalDocs;
  }

  mixin Serialization!OpenApi;
}

/// The object provides metadata about the API. The metadata MAY
/// be used by the clients if needed, and MAY be presented in editing
/// or documentation generation tools for convenience.
struct Info {
  /// The title of the application.
  string title;

  /// The version of the OpenApi document (which is distinct from the
  /// OpenApi Specification version or the API implementation version).
  @SerializedName("version") string version_;

  @optional {
    /// A short description of the application. CommonMark syntax MAY be used
    /// for rich text representation.
    string description;

    /// A URL to the Terms of Service for the API. MUST be in the format of a URL.
    string termsOfService;

    /// The contact information for the exposed API.
    Contact contact;

    /// The license information for the exposed API.
    License license;
  }

  mixin Serialization!Info;
}

/// Contact information for the exposed API.
struct Contact {
  @optional {
    /// The identifying name of the contact person/organization.
    string name;

    /// The URL pointing to the contact information. MUST be in the format of a URL.
    string url;

    /// The email address of the contact person/organization. MUST be in the format of an email address.
    string email;
  }

  mixin Serialization!Contact;
}

/// License information for the exposed API.
struct License {
  /// The license name used for the API.
  string name;

  /// A URL to the license used for the API. MUST be in the format of a URL.
  @optional string url;

  mixin Serialization!License;
}

// An object representing a Server.
struct Server {

  /// A URL to the target host. This URL supports Server Variables and MAY
  /// be relative, to indicate that the host location is relative to the location
  /// where the OpenApi document is being served. Variable substitutions will be
  /// made when a variable is named in {brackets}.
  string url;

  @optional {
    /// An optional string describing the host designated by the URL. CommonMark syntax
    /// MAY be used for rich text representation.
    string description;

    /// A map between a variable name and its value. The value is used for substitution
    /// in the server's URL template.
    ServerVariable[string] variables;
  }

  @safe:
    ///
    Json toJson() const {
      auto dest = Json.emptyObject;

      if(url != "") {
        dest["url"] = url;
      }

      if(description != "") {
        dest["description"] = description;
      }

      if(variables.length > 0) {
        dest["variables"] = variables.serializeToJson;
      }

      return dest;
    }

    ///
    static Server fromJson(Json src) {
      Server server;

      server.url = src["url"].to!string;

      if("description" in src) {
        server.description = src["description"].to!string;
      }

      if("variables" in src && src["variables"].length > 0) {
        server.variables = src["variables"].deserializeJson!(ServerVariable[string]);
      }

      return server;
    }
}

/// An object representing a Server Variable for server URL template substitution.
struct ServerVariable {

  /// The default value to use for substitution, and to send, if an alternate value is not
  /// supplied. Unlike the Schema Object's default, this value MUST be provided by the consumer.
  @SerializedName("default") string default_;

  @optional {
    /// An enumeration of string values to be used if the substitution options are from a limited set.
    @SerializedName("enum") string[] enum_;

    /// An optional description for the server variable. CommonMark syntax MAY be used for
    /// rich text representation.
    string description;
  }
}

/// Holds a set of reusable objects for different aspects of the OAS. All objects defined within
/// the components object will have no effect on the API unless they are explicitly referenced from
/// properties outside the components object.
struct Components {

  @optional {
    ///An object to hold reusable Schema Objects.
    Schema[string] schemas;

    ///An object to hold reusable Response Objects.
    Response[string] responses;

    ///An object to hold reusable Parameter Objects.
    Parameter[string] parameters;

    ///An object to hold reusable Example Objects.
    Example[string] examples;

    ///An object to hold reusable Request Body Objects.
    RequestBody[string] requestBodies;

    ///An object to hold reusable Header Objects.
    Header[string] headers;

    ///An object to hold reusable Security Scheme Objects.
    SecurityScheme[string] securitySchemes;

    ///An object to hold reusable Link Objects.
    Link[string] links;

    ///An object to hold reusable Callback Objects.
    Callback[string] callbacks;
  }

  mixin Serialization!Components;
}

alias Callback = Path[string];

enum OperationsType : string {
  get = "get",
  put = "put",
  post = "post",
  delete_ = "delete",
  options = "options",
  head = "head",
  patch = "patch",
  trace = "trace"
}

/// Describes the operations available on a single path. A Path Item MAY be empty, due to ACL constraints. The path
/// itself is still exposed to the documentation viewer but they will not know which operations and parameters are available.
struct Path {
  alias operations this;

  @optional {
    /// Allows for an external definition of this path item. The referenced structure MUST be in the format of
    /// a Path Item Object. If there are conflicts between the referenced definition and this Path Item's
    /// definition, the behavior is undefined.
    @SerializedName("$ref") string _ref;

    /// An optional, string summary, intended to apply to all operations in this path.
    string summary;

    /// An optional, string description, intended to apply to all operations in this path.
    /// CommonMark syntax MAY be used for rich text representation.
    string description;

    /// Defined operations
    Operation[OperationsType] operations;

    /// An alternative server array to service all operations in this path.
    Server[] servers;

    /// A list of parameters that are applicable for all the operations described under this path.
    /// These parameters can be overridden at the operation level, but cannot be removed there.
    /// The list MUST NOT include duplicated parameters. A unique parameter is defined by
    /// a combination of a name and location. The list can use the Reference Object to link
    /// to parameters that are defined at the OpenApi Object's components/parameters.
    Parameter[] parameters;
  }

 @trusted:
    ///
    Json toJson() const {
      auto dest = Json.emptyObject;

      if(_ref != "") {
        dest["$ref"] = _ref;
        return dest;
      }

      if(summary != "") {
        dest["summary"] = summary;
      }

      if(description != "") {
        dest["description"] = description;
      }

      if(servers.length > 0) {
        dest["servers"] = servers.serializeToJson;
      }

      if(parameters.length > 0) {
        dest["parameters"] = parameters.serializeToJson;
      }

      foreach(string key, operation; operations) {
        dest[key] = operation.serializeToJson;
      }

      return dest;
    }

    ///
    static Path fromJson(Json src) {
      Path path;

      if("$ref" in src) {
        path._ref = "";
        return path;
      }

      if("summary" in src) {
        path.summary = src["summary"].to!string;
      }

      if("description" in src) {
        path.description = src["description"].to!string;
      }

      if("servers" in src) {
        path.servers = src["servers"].deserializeJson!(Server[]);
      }

      if("parameters" in src) {
        path.parameters = src["parameters"].deserializeJson!(Parameter[]);
      }

      static foreach(value; EnumMembers!OperationsType) {
        if(value in src) {
          path.operations[value] = src[value].deserializeJson!Operation;
        }
      }

      return path;
    }
}

/// Describes a single API operation on a path.
struct Operation {

  /// The list of possible responses as they are returned from executing this operation.
  Response[string] responses;

  @optional {
    /// A list of tags for API documentation control. Tags can be used for logical
    /// grouping of operations by resources or any other qualifier.
    string[] tags;

    /// A short summary of what the operation does.
    string summary;

    /// A verbose explanation of the operation behavior. CommonMark syntax MAY be used for rich text representation.
    string description;

    /// Additional external documentation for this operation.
    ExternalDocumentation externalDocs;

    /// Unique string used to identify the operation. The id MUST be unique among all operations described
    /// in the API. Tools and libraries MAY use the operationId to uniquely identify an operation, therefore,
    /// it is RECOMMENDED to follow common programming naming conventions.
    string operationId;

    /// A list of parameters that are applicable for this operation. If a parameter is already defined at the
    /// Path Item, the new definition will override it but can never remove it. The list MUST NOT include
    /// duplicated parameters. A unique parameter is defined by a combination of a name and location.
    /// The list can use the Reference Object to link to parameters that are defined at the OpenApi
    /// Object's components/parameters.
    Parameter[] parameters;

    /// The request body applicable for this operation. The requestBody is only supported in HTTP methods
    /// where the HTTP 1.1 specification RFC7231 has explicitly defined semantics for request bodies. In
    /// other cases where the HTTP spec is vague, requestBody SHALL be ignored by consumers.
    RequestBody requestBody;

    /// A map of possible out-of band callbacks related to the parent operation. The key is a unique identifier
    /// for the Callback Object. Each value in the map is a Callback Object that describes a request that may
    /// be initiated by the API provider and the expected responses. The key value used to identify the callback
    /// object is an expression, evaluated at runtime, that identifies a URL to use for the callback operation.
    Callback[string] callbacks;

    /// Declares this operation to be deprecated. Consumers SHOULD refrain from usage of the declared operation.
    /// Default value is false.
    @SerializedName("deprecated") bool deprecated_;

    /// A declaration of which security mechanisms can be used for this operation. The list of values
    /// includes alternative security requirement objects that can be used. Only one of the security
    /// requirement objects need to be satisfied to authorize a request. This definition overrides any
    /// declared top-level security. To remove a top-level security declaration, an empty array can be used.
    SecurityRequirement[] security;

    /// An alternative server array to service this operation. If an alternative server object is specified
    /// at the Path Item Object or Root level, it will be overridden by this value.
    Server[] servers;
  }

  @trusted:
    ///
    Json toJson() const {
      Json data = Json.emptyObject;
      data["responses"] = responses.serializeToJson;

      if(tags.length > 0) {
        data["tags"] = tags.serializeToJson;
      }

      if(summary != "") {
        data["summary"] = summary;
      }

      if(description != "") {
        data["description"] = description;
      }

      if(operationId != "") {
        data["operationId"] = operationId;
      }

      if(parameters.length > 0) {
        data["parameters"] = parameters.serializeToJson;
      }

      if(deprecated_) {
        data["deprecated"] = deprecated_;
      }

      if(security.length > 0) {
        data["security"] = security.serializeToJson;
      }

      if(servers.length > 0) {
        data["servers"] = servers.serializeToJson;
      }

      auto externalDocsJson = externalDocs.serializeToJson;
      if(externalDocsJson.length > 0) {
        data["externalDocs"] = externalDocs.serializeToJson;
      }

      auto requestBodyJson = requestBody.serializeToJson;
      if(requestBodyJson.length > 0) {
        data["requestBody"] = requestBodyJson;
      }

      auto callbacksJson = callbacks.serializeToJson;
      if(callbacksJson.length > 0) {
        data["callbacks"] = callbacks.serializeToJson;
      }

      return data;
    }

    ///
    static Operation fromJson(Json src) {
      auto operation = Operation();

      if("responses" in src) {
        operation.responses = src["responses"].deserializeJson!(Response[string]);
      }

      if("tags" in src) {
        operation.tags = src["tags"].deserializeJson!(string[]);
      }

      if("summary" in src) {
        operation.summary = src["summary"].to!string;
      }

      if("description" in src) {
        operation.description = src["description"].to!string;
      }

      if("operationId" in src) {
        operation.operationId = src["operationId"].to!string;
      }

      if("externalDocs" in src) {
        operation.externalDocs = src["externalDocs"].deserializeJson!ExternalDocumentation;
      }

      if("parameters" in src) {
        operation.parameters = src["parameters"].deserializeJson!(Parameter[]);
      }

      if("requestBody" in src) {
        operation.requestBody = src["requestBody"].deserializeJson!RequestBody;
      }

      if("deprecated" in src) {
        operation.deprecated_ = src["deprecated"].to!bool;
      }

      if("security" in src) {
        operation.security = src["security"].deserializeJson!(SecurityRequirement[]);
      }

      if("servers" in src) {
        operation.servers = src["servers"].deserializeJson!(Server[]);
      }

      if("callbacks" in src) {
        operation.callbacks = src["callbacks"].deserializeJson  !(Callback[string]);
      }

      return operation;
    }
}

/// Allows referencing an external resource for extended documentation.
struct ExternalDocumentation {

  /// The URL for the target documentation. Value MUST be in the format of a URL.
  string url;

  /// A short description of the target documentation. CommonMark syntax MAY be used for rich text representation.
  @optional string description;

  mixin Serialization!ExternalDocumentation;
}

///
enum ParameterIn : string {
  ///
  query = "query",

  ///
  header = "header",

  ///
  path = "path",

  ///
  cookie = "cookie",

  ///
  body_ = "body"
}

mixin template ParameterOptions() {

  @optional:
    /// Determines whether this parameter is mandatory. If the parameter location is "path", this property is REQUIRED
    /// and its value MUST be true. Otherwise, the property MAY be included and its default value is false.
    bool required;

    /// A brief description of the parameter. This could contain examples of use. CommonMark syntax MAY be used
    /// for rich text representation.
    string description;

    /// Specifies that a parameter is deprecated and SHOULD be transitioned out of usage.
    @SerializedName("deprecated") bool deprecated_;

    /// Sets the ability to pass empty-valued parameters. This is valid only for query parameters and allows
    /// sending a parameter with an empty value. Default value is false. If style is used, and if behavior
    /// is n/a (cannot be serialized), the value of allowEmptyValue SHALL be ignored.
    bool allowEmptyValue;

    /// Describes how the parameter value will be serialized depending on the type of the parameter value.
    /// Default values (based on value of in): for query - form; for path - simple;
    /// for header - simple; for cookie - form.
    Style style;

    /// When this is true, parameter values of type array or object generate separate parameters for each
    /// value of the array or key-value pair of the map. For other types of parameters this property has no effect.
    /// When style is form, the default value is true. For all other styles, the default value is false.
    bool explode;

    /// Determines whether the parameter value SHOULD allow reserved characters, as defined by
    /// RFC3986 :/?#[]@!$&'()*+,;= to be included without percent-encoding. This property only applies to
    /// parameters with an in value of query. The default value is false.
    bool allowReserved;

    /// The schema defining the type used for the parameter.
    Schema schema;

    /// Example of the media type. The example SHOULD match the specified schema andencoding properties
    /// if present. The example field is mutually exclusive of the examples field. Furthermore, if
    /// referencing a schema which contains an example, the example value SHALL override the example provided
    /// by the schema. To represent examples of media types that cannot naturally be represented in JSON or
    /// YAML, a string value can contain the example with escaping where necessary.
    string example;

    /// Examples of the media type. Each example SHOULD contain a value in the correct format as specified in
    /// the parameter encoding. The examples field is mutually exclusive of the example field. Furthermore,
    /// if referencing a schema which contains an example, the examples value SHALL override the example
    /// provided by the schema.
    Example[string] examples;

    /// A map containing the representations for the parameter. The key is the media type and the value
    /// describes it. The map MUST only contain one entry.
    MediaType[string] content;
}

/// Describes a single operation parameter. A unique parameter is defined by a
/// combination of a name and location.
struct Parameter {
  /***
    The name of the parameter. Parameter names are case sensitive.

      - If in is "path", the name field MUST correspond to the associated path segment from the path field
        in the Paths Object. See Path Templating for further information.

      - If in is "header" and the name field is "Accept", "Content-Type" or "Authorization",
        the parameter definition SHALL be ignored.

      - For all other cases, the name corresponds to the parameter name used by the in property.
  */
  string name;

  /// The location of the parameter.
  @SerializedName("in") ParameterIn in_;

  mixin ParameterOptions;

  mixin Serialization!Parameter;
}

/// The Header Object follows the structure of the Parameter Object
struct Header {
  mixin ParameterOptions;

  mixin Serialization!Header;
}

/// In order to support common ways of serializing simple parameters, a set of style values are defined.
enum Style : string {
  ///
  undefined = "",

  /// Path-style parameters defined by RFC6570
  matrix = "matrix",

  /// Label style parameters defined by RFC6570
  label = "label",

  /// Form style parameters defined by RFC6570. This option replaces collectionFormat with a csv (when explode is false) or multi
  /// (when explode is true) value from OpenApi 2.0.
  form = "form",

  /// Simple style parameters defined by RFC6570. This option replaces collectionFormat with a csv value from OpenApi 2.0.
  simple = "simple",

  /// Space separated array values. This option replaces collectionFormat equal to ssv from OpenApi 2.0.
  spaceDelimited = "spaceDelimited",

  /// Pipe separated array values. This option replaces collectionFormat equal to pipes from OpenApi 2.0.
  pipeDelimited = "pipeDelimited",

  /// Provides a simple way of rendering nested objects using form parameters.
  deepObject = "deepObject",
}

/// Describes a single request body.
struct RequestBody {
  /// The content of the request body. The key is a media type or media type range and the value
  /// describes it. For requests that match multiple keys, only the most specific key is applicable.
  /// e.g. text/plain overrides text/*
  MediaType[string] content;

  @optional {
    /// A brief description of the request body. This could contain examples of use.
    /// CommonMark syntax MAY be used for rich text representation.
    string description;

    /// Determines if the request body is required in the request. Defaults to false.
    bool required;
  }

  mixin Serialization!RequestBody;
}

/// Each Media Type Object provides schema and examples for the media type identified by its key.
struct MediaType {
  @optional {
    /// The schema defining the type used for the request body.
    Schema schema;

    /// The example object SHOULD be in the correct format as specified by the media type. The example
    /// field is mutually exclusive of the examples field. Furthermore, if referencing a schema which contains an
    /// example, the example value SHALL override the example provided by the schema.
    string example;

    /// True if the example is a Json object or array. This flag is used for serialization.
    bool parseJsonExample;

    /// Examples of the media type. Each example object SHOULD match the media type and specified schema if present.
    /// The examples field is mutually exclusive of the example field. Furthermore, if referencing a schema which
    /// contains an example, the examples value SHALL override the example provided by the schema.
    Example[string] examples;

    /// A map between a property name and its encoding information. The key, being the property name, MUST exist in
    /// the schema as a property. The encoding object SHALL only apply to requestBody objects when the media type is
    /// multipart or application/x-www-form-urlencoded.
    Encoding[string] encoding;
  }

  @trusted:
    Json toJson() const {
      Json value = Json.emptyObject;

      if(schema !is null) {
        value["schema"] = schema.toJson;
      }

      if(example != "") {
        if(parseJsonExample) {
          value["example"] = example.parseJsonString;
        } else {
          value["example"] = example;
        }
      }

      if(examples.length > 0) {
        value["examples"] = examples.serializeToJson;
      }

      if(encoding.length > 0) {
        value["encoding"] = encoding.serializeToJson;
      }

      return value;
    }

    static MediaType fromJson(Json src) {
      MediaType value;

      if("schema" in src) {
        value.schema = Schema.fromJson(src["schema"]);
      }

      if("example" in src) {
        value.parseJsonExample = src["example"].type == Json.Type.array || src["example"].type == Json.Type.object;
        value.example = src["example"].to!string;
      }

      if("examples" in src) {
        value.examples = src["examples"].deserializeJson!(Example[string]);
      }

      if("encoding" in src) {
        value.encoding = src["encoding"].deserializeJson!(Encoding[string]);
      }

      return value;
    }
}

/// A single encoding definition applied to a single schema property.
struct Encoding {
  @optional:
    /// The Content-Type for encoding a specific property. Default value depends on the property type: for string with
    /// format being binary – application/octet-stream; for other primitive types – text/plain; for object - application/json;
    /// for array – the default is defined based on the inner type. The value can be a specific media type (e.g. application/json),
    /// a wildcard media type (e.g. image/*), or a comma-separated list of the two types.
    string contentType;

    /// A map allowing additional information to be provided as headers, for example Content-Disposition. Content-Type is
    /// described separately and SHALL be ignored in this section. This property SHALL be ignored if the request body media
    /// type is not a multipart.
    Header[string] headers;

    /// Describes how a specific property value will be serialized depending on its type. See Parameter Object for details on the style
    /// property. The behavior follows the same values as query parameters, including default values. This property SHALL be ignored
    /// if the request body media type is not application/x-www-form-urlencoded.
    Style style;

    /// When this is true, property values of type array or object generate separate parameters for each value of the array, or
    /// key-value-pair of the map. For other types of properties this property has no effect. When style is form, the default value is
    /// true. For all other styles, the default value is false. This property SHALL be ignored if the request body media type is not
    /// application/x-www-form-urlencoded.
    bool explode;

    /// Determines whether the parameter value SHOULD allow reserved characters, as defined by RFC3986 :/?#[]@!$&'()*+,;= to be included
    /// without percent-encoding. The default value is false. This property SHALL be ignored if the request body media type is not
    /// application/x-www-form-urlencoded.
    bool allowReserved;
}

/// Describes a single response from an API Operation, including design-time, static links to operations based on the response.
struct Response {
  /// A short description of the response. CommonMark syntax MAY be used for rich text representation.
  string description;

  @optional {
    /// Maps a header name to its definition. RFC7230 states header names are case insensitive. If a response header is
    /// defined with the name "Content-Type", it SHALL be ignored.
    Header[string] headers;

    /// A map containing descriptions of potential response payloads. The key is a media type or media type range and the value
    /// describes it. For responses that match multiple keys, only the most specific key is applicable. e.g. text/plain overrides text/*
    MediaType[string] content;

    /// A map of operations links that can be followed from the response. The key of the map is a short name for the link,
    /// following the naming constraints of the names for Component Objects.
    Link[string] links;
  }

  mixin Serialization!Response;
}

/***
  The Link object represents a possible design-time link for a response. The presence of a link does not guarantee the caller's ability
  to successfully invoke it, rather it provides a known relationship and traversal mechanism between responses and other operations.

  Unlike dynamic links (i.e. links provided in the response payload), the OAS linking mechanism does not require link information in
  the runtime response.

  For computing links, and providing instructions to execute them, a runtime expression is used for accessing values in an operation
  and using them as parameters while invoking the linked operation.
*/
struct Link {
  @optional:
    /// A relative or absolute reference to an OAS operation. This field is mutually exclusive of the operationId field, and MUST point to an
    /// Operation Object. Relative operationRef values MAY be used to locate an existing Operation Object in the OpenApi definition.
    string operationRef;

    /// The name of an existing, resolvable OAS operation, as defined with a unique operationId. This field is mutually exclusive of the operationRef field.
    string operationId;

    /// A map representing parameters to pass to an operation as specified with operationId or identified via operationRef. The key is the parameter
    /// name to be used, whereas the value can be a constant or an expression to be evaluated and passed to the linked operation. The parameter
    /// name can be qualified using the parameter location [{in}.]{name} for operations that use the same parameter name in different locations (e.g. path.id).
    string[string] parameters;

    /// A literal value or {expression} to use as a request body when calling the target operation.
    string requestBody;

    /// A description of the link. CommonMark syntax MAY be used for rich text representation.
    string description;

    /// A server object to be used by the target operation.
    Server server;

    /// The reference string.
    @SerializedName("$ref") string _ref;

  mixin Serialization!Link;
}

enum SchemaType : string {
  null_ = "null",
  boolean = "boolean",
  object = "object",
  array = "array",
  number = "number",
  integer = "integer",
  string = "string"
}

enum SchemaFormat : string {
  ///
  undefined = "undefined",

  ///
  string = "string",

  /// signed 32 bits
  int32 = "int32",

  /// signed 64 bits
  int64 = "int64",

  ///
  float_ = "float",

  /// base64 encoded characters
  byte_ = "byte",

  /// any sequence of octets
  binary = "binary",

  /// As defined by full-date - RFC3339
  date = "date",

  /// As defined by date-time - RFC3339
  dateTime = "date-time",

  /// A hint to UIs to obscure input.
  password = "password",

  ///
  uri = "uri",

  ///
  uriref = "uriref"
}

/***
  The Schema Object allows the definition of input and output data types. These types can be objects, but also primitives and arrays.
  This object is an extended subset of the JSON Schema Specification Wright Draft 00.

  For more information about the properties, see JSON Schema Core and JSON Schema Validation. Unless stated otherwise, the property definitions
  follow the JSON Schema.
*/
class Schema {
  @optional {
    /++ The following properties are taken directly from the JSON Schema definition and follow the same specifications: +/

    /// A title will preferrably be short
    string title;

    /// A numeric instance is only valid if division by this keyword's value results in an integer.
    ulong multipleOf;

    /// An upper limit for a numeric instance.
    /// If the instance is a number, then this keyword validates if "exclusiveMaximum" is true and instance is less than the provided
    /// value, or else if the instance is less than or exactly equal to the
    /// provided value.
    double maximum;

    /// ditto
    bool exclusiveMaximum;

    /// A lower limit for a numeric instance.
    /// If the instance is a number, then this keyword validates if "exclusiveMinimum" is true and instance is greater than the provided
    /// value, or else if the instance is greater than or exactly equal to the provided value.
    double minimum;

    /// ditto
    bool exclusiveMinimum;

    /// A string instance is valid against this keyword if its length is less than, or equal to, the value of this keyword.
    ulong maxLength;

    /// A string instance is valid against this keyword if its length is greater than, or equal to, the value of this keyword.
    ulong minLength;

    /// This string SHOULD be a valid regular expression, according to the ECMA 262 regular expression dialect.
    string pattern;

    /// An array instance is valid against "maxItems" if its size is less than, or equal to.
    ulong maxItems;

    /// An array instance is valid against "minItems" if its size is greater than, or equal to.
    ulong minItems;

    /// If this keyword has boolean value false, the instance validates successfully.  If it has boolean value true, the instance validates
    /// successfully if all of its elements are unique.
    bool uniqueItems;

    /// An object instance is valid against "maxProperties" if its number of properties is less than, or equal to, the value of this keyword.
    ulong maxProperties;

    /// An object instance is valid against "minProperties" if its number of properties is greater than, or equal to, the value of this keyword.
    ulong minProperties;

    /// An object instance is valid against this keyword if its property set contains all elements in this keyword's array value.
    string[] required;

    ///
    @SerializedName("enum") string[] enum_;
  }

  /++
    The following properties are taken from the JSON Schema definition but their definitions were adjusted to the OpenApi Specification.
  +/
  @optional {
    /// An instance validates successfully against this keyword if its value is equal to one of the elements in this keyword's array value.
    SchemaType type;

    /// An instance validates successfully against this keyword if it validates successfully against all schemas defined by this keyword's
    /// value.
    Schema[] allOf;

    /// An instance validates successfully against this keyword if it validates successfully against exactly one schema defined by this
    /// keyword's value.
    Schema[] oneOf;

    /// An instance validates successfully against this keyword if it validates successfully against at least one schema defined by this
    /// keyword's value.
    Schema[] anyOf;

    /// An instance is valid against this keyword if it fails to validate successfully against the schema defined by this keyword.
    Schema[] not;

    /***
      MUST be present if the type is array.

      Successful validation of an array instance with regards to these two keywords is determined as follows:

      If either keyword is absent, it may be considered present with an empty schema.
    */
    Schema items;

    /// Using properties, we can define a known set of properties, however if we
    /// wish to use any other hash/map where we can't specify how many keys
    /// there are nor what they are in advance, we should use additionalProperties.
    Schema[string] properties;


    /// It will match any property name (that will act as the dict's key, and the $ref or
    /// type will be the schema of the dict's value, and since there should not be more than
    /// one properties with the same name for every given object, we will get the enforcement
    /// of unique keys.
    Schema additionalProperties;

    /// CommonMark syntax MAY be used for rich text representation.
    string description;

    ///
    SchemaFormat format;

    /// The default value
    @SerializedName("default") string default_;

    /+ Other than the JSON Schema subset fields, the following fields MAY be used for further schema documentation: +/

    /// Allows sending a null value for the defined schema.
    bool nullable;

    /// Adds support for polymorphism. The discriminator is an object name that is used to differentiate between
    /// other schemas which may satisfy the payload description. See Composition and Inheritance for more details.
    Discriminator discriminator;

    /// Relevant only for Schema "properties" definitions. Declares the property as "read only". This means that it MAY be sent as part of a response but
    /// SHOULD NOT be sent as part of the request. If the property is marked as readOnly being true and is in the required list, the required will take
    /// effect on the response only. A property MUST NOT be marked as both readOnly and writeOnly being true. Default value is false.
    bool readOnly;

    /// Relevant only for Schema "properties" definitions. Declares the property as "write only". Therefore, it MAY be sent as part of a
    /// request but SHOULD NOT be sent as part of the response. If the property is marked as writeOnly being true and is in the required
    ///  list, the required will take effect on the request only. A property MUST NOT be marked as both readOnly and writeOnly being
    /// true. Default value is false.
    bool writeOnly;

    /// This MAY be used only on properties schemas. It has no effect on root schemas. Adds additional metadata to describe
    /// the XML representation of this property.
    XML xml;

    /// Additional external documentation for this schema.
    ExternalDocumentation externalDocs;

    /// A free-form property to include an example of an instance for this schema. To represent examples that cannot
    /// be naturally represented in JSON or YAML, a string value can be used to contain the example with escaping where necessary.
    string example;

    /// Specifies that a schema is deprecated and SHOULD be transitioned out of usage. Default value is false.
    @SerializedName("deprecated") bool deprecated_;

    /// The reference string.
    @SerializedName("$ref") string _ref;
  }

  @trusted:

  enum toFields = [
    "title", "multipleOf", "maximum", "exclusiveMaximum",
    "minimum", "exclusiveMinimum", "maxLength", "minLength",
    "pattern", "maxItems", "minItems", "uniqueItems",
    "maxProperties", "minProperties", "description",
    "nullable", "readOnly", "writeOnly"];

  enum enumField = [
    "type", "format"
  ];

  enum aFields = [
    "allOf", "oneOf", "anyOf", "not"
  ];

  enum aaFields = [
    "properties"
  ];

  enum deserializableFields = [
    "discriminator", "xml", "externalDocs", "required"
  ];

  Json toJson() const {
    Json value = Json.emptyObject;
    Schema defaultSchema = new Schema;

    if(_ref != "") {
      value["$ref"] = _ref;

      return value;
    }

    if(default_ != "") {
      try {
        value["default"] = default_.parseJsonString;
      } catch(JSONException) {
        value["default"] = default_;
      }
    }

    if(deprecated_) {
      value["deprecated"] = true;
    }

    if(enum_.length > 0) {
      value["enum"] = enum_.serializeToJson;
    }

    if(example != "") {
      value["example"] = example.parseJsonString;
    }

    /// to fields
    static foreach(field; toFields) {{
      alias Type = typeof(__traits(getMember, Schema, field));

      auto tmp = __traits(getMember, this, field);
      auto defaultValue = __traits(getMember, defaultSchema, field);

      static if(is(Type == double)) {
        if(!isNaN(tmp)) {
          value[field] = tmp;
        }
      } else if(tmp != defaultValue) {
        value[field] = tmp;
      }
    }}

    /// enum fields
    static foreach(field; enumField) {{
      auto tmp = __traits(getMember, this, field);
      auto defaultValue = __traits(getMember, defaultSchema, field);

      if(tmp != defaultValue) {
        value[field] = tmp.toOriginalEnumValue;
      }
    }}

    /// array fields
    static foreach(field; aFields) {{
      auto tmp = __traits(getMember, this, field);

      if(tmp.length > 0) {
        value[field] = tmp.serializeToJson;
      }
    }}

    /// assoc array fields
    static foreach(field; aaFields) {{
      auto tmp = __traits(getMember, this, field);

      if(tmp.length > 0) {
        value[field] = tmp.serializeToJson;
      }
    }}

    if(items !is null) {
      value["items"] = items.toJson;
    }

    /// deserializable fields
    static foreach(field; deserializableFields) {{
      alias Type = typeof(__traits(getMember, Schema, field));

      Json tmp = __traits(getMember, this, field).serializeToJson;

      if(tmp.length > 0) {
        value[field] = tmp;
      }
    }}

    if(additionalProperties !is null) {
      value["additionalProperties"] = additionalProperties.toJson;
    }

    return value;
  }

  ///
  static Schema fromJson(Json src) {
    Schema schema = new Schema;

    if("$ref" in src) {
      schema._ref = src["$ref"].to!string;
      return schema;
    }

    if("default" in src) {
      schema.default_ = src["default"].to!string;
    }

    if("deprecated" in src) {
      schema.deprecated_ = src["deprecated"].to!bool;
    }

    if("enum" in src) {
      schema.enum_ = src["enum"].deserializeJson!(string[]);
    }

    if("items" in src) {
      schema.items = src["items"].deserializeJson!Schema;
    }

    if("example" in src) {
      schema.example = src["example"].toString;
    }

    /// to fields
    static foreach(field; toFields) {{
      alias Type = typeof(__traits(getMember, Schema, field));

      if(field in src) {
        auto value = src[field].to!Type;
        if(__traits(getMember, schema, field) != value) {
          __traits(getMember, schema, field) = value;
        }
      }
    }}

    /// enum fields
    static foreach(field; enumField) {{
      alias Type = typeof(__traits(getMember, Schema, field));

      if(field in src) {
        Type value;

        try {
          value = src[field].to!string.toEnumValue!Type;

          if(__traits(getMember, schema, field) != value) {
            __traits(getMember, schema, field) = value;
          }
        } catch(Exception e) {
          writeln(e.msg);
        }
      }
    }}

    /// array fields
    static foreach(field; aFields) {{
      if(field in src && src[field].length > 0) {
        auto value = src[field].byValue.map!(a => Schema.fromJson(a)).array;
        __traits(getMember, schema, field) = value;
      }
    }}

    /// assoc array fields
    static foreach(field; aaFields) {{
      if(field in src && src[field].length > 0) {
        try {
          auto value = src[field].byKeyValue.map!(a => tuple(a.key, Schema.fromJson(a.value))).assocArray;
          __traits(getMember, schema, field) = value;
        } catch(Exception e) {
          writeln("Error: ", e.msg);
        }
      }
    }}

    /// deserializable fields
    static foreach(field; deserializableFields) {{
      alias Type = typeof(__traits(getMember, Schema, field));

      if(field in src && src[field].length > 0) {
        try {
          auto value = src[field].deserializeJson!Type;
          __traits(getMember, schema, field) = value;
        } catch(Exception e) {
          writeln("`", field, "` error: ", e.msg);
        }
      }
    }}

    if("additionalProperties" in src && src["additionalProperties"].type == Json.Type.object) {
      schema.additionalProperties = Schema.fromJson(src["additionalProperties"]);
    }

    return schema;
  }
}

/***
When request bodies or response payloads may be one of a number of different schemas, a discriminator object can be used
to aid in serialization, deserialization, and validation. The discriminator is a specific object in a schema which is used
to inform the consumer of the specification of an alternative schema based on the value associated with it.

When using the discriminator, inline schemas will not be considered.
*/
struct Discriminator {
  /// The name of the property in the payload that will hold the discriminator value.
  string propertyName;

  /// An object to hold mappings between payload values and schema names or references.
  @optional string[string][string] mapping;

  mixin Serialization!Discriminator;
}

/***
A metadata object that allows for more fine-tuned XML model definitions.

When using arrays, XML element names are not inferred (for singular/plural forms) and the name property SHOULD
be used to add that information. See examples for expected behavior.
*/
struct XML {
  @optional {
    /// Replaces the name of the element/attribute used for the described schema property. When defined within items, it
    /// will affect the name of the individual XML elements within the list. When defined alongside type being array
    /// (outside the items), it will affect the wrapping element and only if wrapped is true. If wrapped is false, it will be ignored.
    string name;

    /// The URI of the namespace definition. Value MUST be in the form of an absolute URI.
    string namespace;

    /// The prefix to be used for the name.
    string prefix;

    /// Declares whether the property definition translates to an attribute instead of an element. Default value is false.
    bool attribute;

    /// MAY be used only for an array definition. Signifies whether the array is wrapped
    /// (for example, <books><book/><book/></books>) or unwrapped (<book/><book/>).
    /// Default value is false. The definition takes effect only when defined alongside type being array (outside the items).
    bool wrapped;
  }

  mixin Serialization!XML;
}

///
struct Example {
  @optional {
    /// Short description for the example.
    string summary;

    /// Long description for the example. CommonMark syntax MAY be used for rich text representation.
    string description;

    /// Embedded literal example. The value field and externalValue field are mutually exclusive. To represent examples
    /// of media types that cannot naturally represented in JSON or YAML, use a string value to contain the example, escaping where necessary.
    string value;

    /// A URL that points to the literal example. This provides the capability to reference examples that
    /// cannot easily be included in JSON or YAML documents. The value field and externalValue field are mutually exclusive.
    string externalValue;

    /// True if the value should be treated as a json object or array
    bool parseJsonValue;
  }

  Json toJson() const @safe {
    Json jsonValue = Json.emptyObject;

    if(summary != "") {
      jsonValue["summary"] = summary;
    }

    if(description != "") {
      jsonValue["description"] = description;
    }

    if(externalValue != "") {
      jsonValue["externalValue"] = externalValue;
    }

    if(value != "") {
      if(parseJsonValue) {
        jsonValue["value"] = value.parseJsonString;
      } else {
        jsonValue["value"] = value;
      }
    }

    return jsonValue;
  }

  ///
  static Example fromJson(Json src) @safe {
    Example example;

    if("summary" in src) {
      example.summary = src["summary"].to!string;
    }

    if("description" in src) {
      example.description = src["description"].to!string;
    }

    if("externalValue" in src) {
      example.externalValue = src["externalValue"].to!string;
    }

    if("value" in src) {
      example.parseJsonValue = src["value"].type == Json.Type.array || src["value"].type == Json.Type.object;
      example.value = src["value"].to!string;
    }

    return example;
  }
}

/// Adds metadata to a single tag that is used by the Operation Object. It is not mandatory to have a
/// Tag Object per tag defined in the Operation Object instances.
struct Tag {
  /// The name of the tag
  string name;

  @optional {
    /// A short description for the tag. CommonMark syntax MAY be used for rich text representation.
    string description;

    /// Additional external documentation for this tag.
    ExternalDocumentation externalDocs;
  }

  mixin Serialization!Tag;
}

///
enum SecurityType : string {
  apiKey = "apiKey",
  http = "http",
  oauth2 = "oauth2",
  openIdConnect = "openIdConnect"
}

/**
  Defines a security scheme that can be used by the operations. Supported schemes are HTTP authentication, an API key (either
  as a header or as a query parameter), OAuth2's common flows (implicit, password, application and access code) as defined
  in RFC6749, and OpenID Connect Discovery.
*/
struct SecurityScheme {
  ///
  SecurityType type;

  @optional {
    /// A hint to the client to identify how the bearer token is formatted. Bearer tokens are usually generated by an
    /// authorization server, so this information is primarily for documentation purposes.
    string bearerFormat;

    /// A short description for security scheme. CommonMark syntax MAY be used for rich text representation.
    string description;

    /// The name of the header, query or cookie parameter to be used.
    string name;

    /// The location of the API key
    @SerializedName("in") ParameterIn in_;

    /// The name of the HTTP Authorization scheme to be used in the Authorization header as defined in RFC7235.
    string scheme;

    /// An object containing configuration information for the flow types supported.
    OAuthFlows flows;

    /// OpenId Connect URL to discover OAuth2 configuration values. This MUST be in the form of a URL.
    string openIdConnectUrl;
  }

  mixin Serialization!SecurityScheme;
}

/// Allows configuration of the supported OAuth Flows.
struct OAuthFlows {
  @optional {
    /// Configuration for the OAuth Implicit flow
    OAuthFlow implicit;

    /// Configuration for the OAuth Resource Owner Password flow
    OAuthFlow password;

    /// Configuration for the OAuth Client Credentials flow. Previously called application in OpenApi 2.0.
    OAuthFlow clientCredentials;

    /// Configuration for the OAuth Authorization Code flow. Previously called accessCode in OpenApi 2.0.
    OAuthFlow authorizationCode;
  }

  mixin Serialization!OAuthFlows;
}

/// Configuration details for a supported OAuth Flow
struct OAuthFlow {

  /// The authorization URL to be used for this flow. This MUST be in the form of a URL.
  string authorizationUrl;

  /// The token URL to be used for this flow. This MUST be in the form of a URL.
  string tokenUrl;

  /// The available scopes for the OAuth2 security scheme. A map between the scope name and a short description for it.
  string[string] scopes;

  /// The URL to be used for obtaining refresh tokens. This MUST be in the form of a URL.
  @optional string oauth2;


  mixin Serialization!OAuthFlow;
}

///
alias SecurityRequirement = string[][string];
