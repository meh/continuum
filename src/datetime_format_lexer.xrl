%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Definitions.

S = [,:\-\s]

Rules.

\\.  : { token, { raw, TokenLine, list_to_binary(tl(TokenChars)) } }.
{S}+ : { token, { raw, TokenLine, list_to_binary(TokenChars) } }.
YYYY : { token, { part, TokenLine, { year, long } } }.
YY   : { token, { part, TokenLine, { year, short } } }.
MMMM : { token, { part, TokenLine, { month, name, long } } }.
MMM  : { token, { part, TokenLine, { month, name, short } } }.
MM   : { token, { part, TokenLine, { month, number, padded } } }.
M    : { token, { part, TokenLine, { month, number } } }.
dd   : { token, { part, TokenLine, { day, number, padded } } }.
d    : { token, { part, TokenLine, { day, number } } }.
EEEE : { token, { part, TokenLine, { weekday, name, long } } }.
EE   : { token, { part, TokenLine, { weekday, name, short } } }.
hh   : { token, { part, TokenLine, { hour, 12, padded } } }.
h    : { token, { part, TokenLine, { hour, 12 } } }.
HH   : { token, { part, TokenLine, { hour, 24, padded } } }.
H    : { token, { part, TokenLine, { hour, 24 } } }.
a    : { token, { part, TokenLine, meridian } }.
mm   : { token, { part, TokenLine, { minute, padded } } }.
m    : { token, { part, TokenLine, minute } }.
ss   : { token, { part, TokenLine, { second, padded } } }.
s    : { token, { part, TokenLine, second } }.
ZZZ  : { token, { part, TokenLine, { timezone, zone } } }.
ZZ   : { token, { part, TokenLine, { timezone, offset, long } } }.
Z    : { token, { part, TokenLine, { timezone, offset, short } } }.
zz   : { token, { part, TokenLine, { timezone, id, long } } }.
z    : { token, { part, TokenLine, { timezone, id, short } } }.
.    : { token, { raw, TokenLine, list_to_binary(TokenChars) } }.

Erlang code.
