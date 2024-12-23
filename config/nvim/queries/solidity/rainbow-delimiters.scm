(function_body
  "{" @delimiter
  "}" @delimiter @sentinel) @container

(contract_body
  "{" @delimiter
  "}" @delimiter @sentinel) @container

(call_expression
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(array_access
  "[" @delimiter
  "]" @delimiter @sentinel) @container

(type_name
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(event_definition
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(constructor_definition
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(function_definition
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(emit_statement
  "(" @delimiter
  ")" @delimiter @sentinel) @container

