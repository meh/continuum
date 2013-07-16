Nonterminals
  format.

Terminals
  part raw.

Rootsymbol
  format.

format ->
  part : [content('$1')].

format ->
  raw : [content('$1')].

format ->
  part format : [content('$1') | '$2'].

format ->
  raw format : [content('$1') | '$2'].

Erlang code.

content({ _, _, Content }) ->
  Content.
