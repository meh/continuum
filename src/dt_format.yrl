Nonterminals
  format.

Terminals
  part raw.

Rootsymbol
  format.

format ->
  part : [content('$1')].

format ->
  raw : [char(content('$1'))].

format ->
  part format : [content('$1') | '$2'].

format ->
  raw format : [char(content('$1')) | '$2'].

Erlang code.

content({ _, _, Content }) ->
  Content.

char([Char]) ->
  << Char/utf8 >>.
