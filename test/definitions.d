module openapi.test.definitions;

import openapi.definitions;

@("Parameter opEquals returns true for identical parameters")
unittest {
  Parameter a;
  a.name = "id";
  a.in_ = ParameterIn.query;
  a.required = true;
  a.description = "desc";
  a.example = "ex";

  Parameter b = a;
  assert(a == b);
}

@("Parameter opEquals returns false when name differs")
unittest {
  Parameter a;
  a.name = "id";
  a.in_ = ParameterIn.query;

  Parameter b = a;
  b.name = "other";
  assert(a != b);
}

@("Parameter opEquals returns false when in_ differs")
unittest {
  Parameter a;
  a.name = "id";
  a.in_ = ParameterIn.query;

  Parameter b = a;
  b.in_ = ParameterIn.path;
  assert(a != b);
}

@("Parameter opEquals returns false when ParameterOptions field differs")
unittest {
  Parameter a;
  a.name = "id";
  a.in_ = ParameterIn.query;
  a.required = true;

  Parameter b = a;
  b.required = false;
  assert(a != b);
}

@("Parameter opEquals returns false when description differs")
unittest {
  Parameter a;
  a.name = "id";
  a.description = "first";

  Parameter b = a;
  b.description = "second";
  assert(a != b);
}

@("Header opEquals returns true for identical headers")
unittest {
  Header a;
  a.required = true;
  a.description = "desc";
  a.example = "ex";

  Header b = a;
  assert(a == b);
}

@("Header opEquals returns false when required differs")
unittest {
  Header a;
  a.required = true;

  Header b = a;
  b.required = false;
  assert(a != b);
}

@("Header opEquals returns false when description differs")
unittest {
  Header a;
  a.description = "first";

  Header b = a;
  b.description = "second";
  assert(a != b);
}

@("Header opEquals returns false when style differs")
unittest {
  Header a;
  a.style = Style.simple;

  Header b = a;
  b.style = Style.form;
  assert(a != b);
}
