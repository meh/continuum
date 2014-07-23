%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Nonterminals
  datetime time_noon day_name date.

Terminals
  day weekday month number 'of' slash dash comma noon time string.

Rootsymbol
  datetime.

datetime ->
  day_name date time_noon string : { { '$2', '$3' }, content('$4') }.

datetime ->
  day_name date string : { '$2', content('$3') }.

datetime ->
  day_name time_noon string : { '$2', content('$3') }.

datetime ->
  day_name date : '$2'.

datetime ->
  day_name time_noon : '$2'.

datetime ->
  date time_noon string : { { '$1', '$2' }, content('$3') }.

datetime ->
  date string : { '$1', content('$2') }.

datetime ->
  time_noon string : { '$1', content('$2') }.

datetime ->
  date time_noon : { '$1', '$2' }.

datetime ->
  date : '$1'.

datetime ->
  time_noon : '$1'.

date ->
  day 'of' month number : { content('$4'), parse_month('$3'), content('$1') }.

date ->
  number month number : { content('$3'), parse_month('$2'), content('$1') }.

date ->
  number dash month dash number :
    consider_date({ content('$1'), parse_month('$3'), content('$5') }).

date ->
  number dash number dash number :
    consider_date({ content('$1'), content('$3'), content('$5') }).

date ->
  number slash month slash number :
    { content('$5'), parse_month('$3'), content('$1') }.

date ->
  number slash number slash number :
    consider_date({ content('$1'), content('$3'), content('$5') }).

time_noon ->
  time noon : parse_time(content('$1'), content('$2')).

time_noon ->
  time : parse_time(content('$1')).

day_name ->
  weekday comma.

day_name ->
  weekday.

Erlang code.

content({ _, _, Content }) ->
  Content.

parse_month({ month, _, january })   -> 1;
parse_month({ month, _, february })  -> 2;
parse_month({ month, _, march })     -> 3;
parse_month({ month, _, april })     -> 4;
parse_month({ month, _, may })       -> 5;
parse_month({ month, _, june })      -> 6;
parse_month({ month, _, july })      -> 7;
parse_month({ month, _, august })    -> 8;
parse_month({ month, _, september }) -> 9;
parse_month({ month, _, october })   -> 10;
parse_month({ month, _, november })  -> 11;
parse_month({ month, _, december })  -> 12.

parse_time(Time) when is_list(Time) ->
  parse_time(list_to_binary(Time));
parse_time(<< Hour:16/binary-unit:1, $::8, Minute:16/binary-unit:1, $::8, Second:16/binary-unit:1 >>) ->
  { binary_to_integer(Hour), binary_to_integer(Minute), binary_to_integer(Second) };
parse_time(<< Hour:8/binary-unit:1, $::8, Minute:16/binary-unit:1, $::8, Second:16/binary-unit:1 >>) ->
  { binary_to_integer(Hour), binary_to_integer(Minute), binary_to_integer(Second) };
parse_time(<< Hour:16/binary-unit:1, $::8, Minute:16/binary-unit:1 >>) ->
  { binary_to_integer(Hour), binary_to_integer(Minute), 0 };
parse_time(<< Hour:8/binary-unit:1, $::8, Minute:16/binary-unit:1 >>) ->
  { binary_to_integer(Hour), binary_to_integer(Minute), 0 }.

parse_time(Time, before) ->
  parse_time(Time);
parse_time(Time, 'after') ->
  case parse_time(Time) of
    { Hour, Minute, Second } ->
      { Hour + 12, Minute, Second }
  end.

consider_date({ A, B, C }) when B > 12 andalso C > 31 ->
  { C, A, B };
consider_date(Date) ->
  Date.
