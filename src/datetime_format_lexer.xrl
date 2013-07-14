%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Definitions.

Rules.

\\. : { token, { raw, TokenLine, tl(TokenChars) } }.

% day
d : { token, { part, TokenLine, { day, number, padded } } }.
D : { token, { part, TokenLine, { weekday, name, short } } }.
j : { token, { part, TokenLine, { day, number } } }.
l : { token, { part, TokenLine, { weekday, name, long } } }.
N : { token, { part, TokenLine, { weekday, number, iso8601 } } }.
S : { token, { part, TokenLine, suffix } }.
w : { token, { part, TokenLine, { weekday, number } } }.
z : { token, { part, TokenLine, yearday } }.

% week
W : { token, { part, TokenLine, { week, number, iso8601 } } }.

% month
F : { token, { part, TokenLine, { month, name, long } } }.
m : { token, { part, TokenLine, { month, number, padded } } }.
M : { token, { part, TokenLine, { month, name, short } } }.
n : { token, { part, TokenLine, { month, number } } }.
t : { token, { part, TokenLine, { month, days } } }.

% year
L : { token, { part, TokenLine, { year, leap } } }.
o : { token, { part, TokenLine, { year, number, iso8601 } } }.
Y : { token, { part, TokenLine, { year, number, long } } }.
y : { token, { part, TokenLine, { year, number, short } } }.

% time
a : { token, { part, TokenLine, { noon, lowercase } } }.
A : { token, { part, TokenLine, { noon, uppercase } } }.
B : { token, { part, TokenLine, { time, swatch } } }.
g : { token, { part, TokenLine, { hour, 12 } } }.
G : { token, { part, TokenLine, { hour, 24 } } }.
h : { token, { part, TokenLine, { hour, 12, padded } } }.
H : { token, { part, TokenLine, { hour, 24, padded } } }.
i : { token, { part, TokenLine, { minute, padded } } }.
s : { token, { part, TokenLine, { second, padded } } }.
u : { token, { part, TokenLine, { microsecond, padded } } }.

% timezone
e : { token, { part, TokenLine, { timezone, long } } }.
I : { token, { part, TokenLine, daylight } }.
O : { token, { part, TokenLine, { offset, short } } }.
P : { token, { part, TokenLine, { offset, long } } }.
T : { token, { part, TokenLine, { timezone, short } } }.
Z : { token, { part, TokenLine, { offset, seconds } } }.

% full date/time
c : { token, { part, TokenLine, { datetime, iso8601 } } }.
r : { token, { part, TokenLine, { datetime, rfc2882 } } }.
U : { token, { part, TokenLine, epoch } }.

. : { token, { raw, TokenLine, TokenChars } }.

Erlang code.
