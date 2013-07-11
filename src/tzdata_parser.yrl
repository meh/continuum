%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Nonterminals
  definitions definition string year month day time
  correction rs year_range type on at save letter zone_lines
  offset rules until newline.

Terminals
  rule link zone leap elem break.

Rootsymbol
  definitions.

definitions -> definition : ['$1'].
definitions -> definition definitions : ['$1' | '$2'].

definition ->
  rule string year_range type month on at save letter newline :
    { rule, '$2', '$3', { '$5', '$6', '$7' }, '$8', '$9' }.

definition ->
  link string string newline : { link, '$2', '$3' }.

definition ->
  zone string zone_lines : { zone, '$2', '$3' }.

definition ->
  leap year month day time correction rs newline :
    { leap, { { '$2', '$3', '$4' }, '$5' }, '$6', '$7' }.

newline -> break.
newline -> break newline.

string ->
  elem : list_to_binary(content('$1')).

year ->
  elem : parse_year(content('$1')).

month ->
  elem : parse_month(content('$1')).

day ->
  elem : parse_day(content('$1')).

time ->
  elem : parse_time(content('$1')).

correction ->
  elem : parse_correction(content('$1')).

rs ->
  elem : parse_rs(content('$1')).

year_range ->
  elem elem : parse_year_range(content('$1'), content('$2')).

type ->
  elem : parse_type(content('$1')).

on ->
  elem : parse_on(content('$1')).

at ->
  elem : parse_at(content('$1')).

save ->
  elem : parse_save(content('$1')).

letter ->
  elem : parse_letter(content('$1')).

zone_lines ->
  offset rules string newline : [{ '$1', '$2', '$3', parse_until() }].
zone_lines ->
  offset rules string until newline zone_lines : [{ '$1', '$2', '$3', '$4' } | '$6'].

offset ->
  elem : parse_save(content('$1')).

rules ->
  elem : parse_rules(content('$1')).

until ->
  elem elem elem elem : parse_until(content('$1'), content('$2'), content('$3'), content('$4')).
until ->
  elem elem elem : parse_until(content('$1'), content('$2'), content('$3')).
until ->
  elem elem : parse_until(content('$1'), content('$2')).
until ->
  elem : parse_until(content('$1')).

Erlang code.

content({ elem, _, Content }) ->
  Content.

parse_year(Year) ->
  list_to_integer(Year).

parse_month("Jan") -> 1;
parse_month("Feb") -> 2;
parse_month("Mar") -> 3;
parse_month("Apr") -> 4;
parse_month("May") -> 5;
parse_month("Jun") -> 6;
parse_month("Jul") -> 7;
parse_month("Aug") -> 8;
parse_month("Sep") -> 9;
parse_month("Oct") -> 10;
parse_month("Nov") -> 11;
parse_month("Dec") -> 12.

parse_weekday("Mon") -> 1;
parse_weekday("Tue") -> 2;
parse_weekday("Wed") -> 3;
parse_weekday("Thu") -> 4;
parse_weekday("Fri") -> 5;
parse_weekday("Sat") -> 6;
parse_weekday("Sun") -> 7.

parse_day("lastSat") ->
  { last, saturday };
parse_day("lastSun") ->
  { last, sunday };
parse_day(Day) ->
  case string:to_integer(Day) of
    { error, _ } ->
      list_to_binary(Day);

    { Result, _ } ->
      Result
  end.

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

parse_correction("+") -> '+';
parse_correction("-") -> '-'.

parse_rs("S") -> stationary;
parse_rs("R") -> rolling.

parse_year_range(From, "only") ->
  list_to_integer(From);
parse_year_range(From, "max") ->
  { list_to_integer(From), infinity };
parse_year_range("min", To) ->
  { infinity, list_to_integer(To) };
parse_year_range(From, To) ->
  { list_to_integer(From), list_to_integer(To) }.

parse_type("-") ->
  nil.

parse_on(On) ->
  case string:to_integer(On) of
    { error, _ } ->
      list_to_binary(On);

    { Result, _ } ->
      Result
  end.

parse_at(<< Hour:16/binary-unit:1, $::8, Minute:16/binary-unit:1, $::8, Second:16/binary-unit:1, Rest/binary >>) ->
  { parse_at_type(binary_to_list(Rest)), { binary_to_integer(Hour), binary_to_integer(Minute), binary_to_integer(Second) } };
parse_at(<< Hour:16/binary-unit:1, $::8, Minute:16/binary-unit:1, Rest/binary >>) ->
  { parse_at_type(binary_to_list(Rest)), { binary_to_integer(Hour), binary_to_integer(Minute), 0 } };
parse_at(<< Hour:8/binary-unit:1, $::8, Minute:16/binary-unit:1, Rest/binary >>) ->
  { parse_at_type(binary_to_list(Rest)), { binary_to_integer(Hour), binary_to_integer(Minute), 0 } };
parse_at("0") ->
  { local, { 0, 0, 0 } };
parse_at(At) ->
  parse_at(list_to_binary(At)).

parse_at_type("")  -> local;
parse_at_type("w") -> local;
parse_at_type("u") -> universal;
parse_at_type("s") -> standard;
parse_at_type("g") -> greenwich;
parse_at_type("z") -> nautical.

parse_save("0") ->
  { '+', { 0, 0, 0 } };
parse_save("1") ->
  { '+', { 1, 0, 0 } };
parse_save([$- | Save]) ->
  { '-', parse_save_split(string:tokens(Save, ":")) };
parse_save(Save) ->
  { '+', parse_save_split(string:tokens(Save, ":")) }.

parse_save_split([Hours]) ->
  { list_to_integer(Hours), 0, 0 };
parse_save_split([Hours, Minutes]) ->
  { list_to_integer(Hours), list_to_integer(Minutes), 0 };
parse_save_split([Hours, Minutes, Seconds]) ->
  { list_to_integer(Hours), list_to_integer(Minutes), list_to_integer(Seconds) }.

parse_letter("S") -> standard;
parse_letter("D") -> daylight_saving;
parse_letter("W") -> war;
parse_letter("P") -> peace;
parse_letter("-") -> none;
parse_letter(_)   -> none.

parse_rules("-")   -> nil;
parse_rules(Rules) ->
  case string:to_integer(Rules) of
    { error, _ } ->
      list_to_binary(Rules);

    { _, _ } ->
      parse_time(Rules)
  end.

parse_until(Year, Month, Day, Time, Type) ->
  { parse_at_type(Type), { { parse_year(Year), parse_month(Month), parse_day(Day) },
                           parse_time(Time) } }.

parse_until(Year, Month, Day, Time) ->
  Type = [lists:last(Time)],

  case string:to_integer(Type) of
    { error, _ } ->
      parse_until(Year, Month, Day, lists:reverse(tl(lists:reverse(Time))), Type);

    _ ->
      parse_until(Year, Month, Day, Time, "")
  end.

parse_until(Year, Month, Day) ->
  { local, { { parse_year(Year), parse_month(Month), parse_day(Day) }, { 0, 0, 0 } } }.

parse_until(Year, Month) ->
  { local, { { parse_year(Year), parse_month(Month), 1 }, { 0, 0, 0 } } }.

parse_until(Year) ->
  { local, { { parse_year(Year), 1, 1 }, { 0, 0, 0 } } }.

parse_until() ->
  infinity.
