%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Definitions.

WS = [\t\s]
D  = [0-9]
C  = [A-Za-z]

Rules.

% spaces
{WS}+ : skip_token.

% time
{D}{D}?:{D}{D}(:{D}{D})? : { token, { time, TokenLine, TokenChars } }.

% AM or PM
[Pp][Mm] : { token, { noon, TokenLine, 'after' } }.
[Aa][Mm] : { token, { noon, TokenLine, before } }.

% week days
[Ss][Uu][Nn]([Dd][Aa][Yy])?             : { token, { weekday, TokenLine, sunday } }.
[Ss][Aa][Tt]([Uu][Rr][Dd][Aa][Yy])?     : { token, { weekday, TokenLine, saturday } }.
[Ff][Rr][Ii]([Dd][Aa][Yy])?             : { token, { weekday, TokenLine, friday } }.
[Tt][Hh][Uu]([Rr][Ss][Dd][Aa][Yy])?     : { token, { weekday, TokenLine, thursday } }.
[We][Ee][Dd]([Nn][Ee][Ss][Dd][Aa][Yy])? : { token, { weekday, TokenLine, wednesday } }.
[Tt][Uu][Ee]([Ss][Dd][Aa][Yy])?         : { token, { weekday, TokenLine, tuesday } }.
[Mm][Oo][Nn]([Dd][Aa][Yy])?             : { token, { weekday, TokenLine, monday } }.

% months
[Jj][Aa][Nn]([Uu][Aa][Rr][Yy])?         : { token, { month, TokenLine, january } }.
[Ff][Ee][Bb]([Rr][Uu][Aa][Rr][Yy])?     : { token, { month, TokenLine, february } }.
[Mm][Aa][Rr]([Cc][Hh])?                 : { token, { month, TokenLine, march } }.
[Aa][Pp][Rr]([Ii][Ll])?                 : { token, { month, TokenLine, april } }.
[Mm][Aa][Yy]                            : { token, { month, TokenLine, may } }.
[Jj][Uu][Nn][Ee]?                       : { token, { month, TokenLine, june } }.
[Jj][Uu][Ll][Yy]?                       : { token, { month, TokenLine, july } }.
[Aa][Uu][Gg]([Uu][Ss][Tt])?             : { token, { month, TokenLine, august } }.
[Ss][Ee][Pp]([Tt][Ee][Mm][Bb][Ee][Rr])? : { token, { month, TokenLine, september } }.
[Oo][Cc][Tt]([Oo][Bb][Ee][Rr])?         : { token, { month, TokenLine, october } }.
[Nn][Oo][Vv]([Ee][Mm][Bb][Ee][Rr])?     : { token, { month, TokenLine, november } }.
[Dd][Ee][Cc]([Ee][Mm][Bb][Ee][Rr])?     : { token, { month, TokenLine, december } }.

% day number
{D}*1[Ss][Tt] : { token, { day, TokenLine, extract_day(TokenChars) } }.
{D}*2[Nn][Dd] : { token, { day, TokenLine, extract_day(TokenChars) } }.
{D}*3[Rr][Dd] : { token, { day, TokenLine, extract_day(TokenChars) } }.
{D}+[Tt][Hh]  : { token, { day, TokenLine, extract_day(TokenChars) } }.

/        : { token, { slash, TokenLine } }.
-        : { token, { dash, TokenLine } }.
,        : { token, { comma, TokenLine } }.
[Oo][Ff] : { token, { 'of', TokenLine } }.

{D}+ : { token, { number, TokenLine, list_to_integer(TokenChars) } }.
{C}+ : { token, { string, TokenLine, list_to_binary(TokenChars) } }.

Erlang code.

extract_day(Chars) ->
  case string:to_integer(Chars) of
    { Result, End } when End == "st" orelse End == "nd" orelse End == "rd" orelse End == "th" ->
      Result
  end.
