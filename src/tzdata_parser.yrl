%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Nonterminals
  definitions definition elements element group.

Terminals
  rule link zone elem break.

Rootsymbol
  definitions.

definitions -> definition : ['$1'].
definitions -> definition definitions : [ '$1' | '$2'].

definition -> rule elements break        : { rule, '$2' }.
definition -> link element element break : { link, '$2', '$3' }.
definition -> zone element group         : { zone, '$2', '$3' }.

group -> elements : '$1'.
group -> elements break : '$1'.
group -> elements break group : ['$1' | '$3'].

elements -> element : ['$1'].
elements -> element elements : ['$1' | '$2'].

element -> elem : list_to_binary(element(3, '$1')).

Erlang code.
