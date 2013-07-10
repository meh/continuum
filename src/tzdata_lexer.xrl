%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Definitions.

WS   = [\t\s]
C    = [a-zA-Z0-9\_\->=:/%+]
CR   = [\r]
LF   = [\n]

Rules.

{WS}+#.*({CR}?{LF})+ : { token, { break, TokenLine } }.
#.*({CR}?{LF})+     : skip_token.
({CR}?{LF})+         : { token, { break, TokenLine } }.
{WS}+                : skip_token.

Rule : { token, { rule, TokenLine } }.
Zone : { token, { zone, TokenLine } }.
Link : { token, { link, TokenLine } }.
Leap : { token, { leap, TokenLine } }.

{C}+ : { token, { elem, TokenLine, TokenChars } }.

Erlang code.
