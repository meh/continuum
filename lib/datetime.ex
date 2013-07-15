defmodule DateTime do
  use Date
  use Time

  @type t :: { Date.t, Time.t } | { Timezone.t, { Date.t, Time.t } }

  @spec valid?(t) :: boolean
  def valid?({ { _, _ }, { _, _, _ } }) do
    false
  end

  def valid?({ { _, _, _ }, { _, _ } }) do
    false
  end

  def valid?({ { date, time }, zone }) do
    Timezone.exists?(zone) and Date.valid?(date) and Time.valid?(time)
  end

  def valid?({ date, time }) do
    Date.valid?(date) and Time.valid?(time)
  end

  @spec new(Date.t) :: t
  def new({ date, zone }) do
    { { date, { 0, 0, 0 } }, zone }
  end

  def new({ _, _, _ } = date) do
    { date, { 0, 0, 0 } }
  end

  @spec new(Date.t, Time.t) :: t
  def new({ _, _, _ } = date, { _, _, _ } = time) do
    { date, time }
  end

  def new({ date, zone_a }, { time, zone_b }) do
    unless Timezone.equal?(zone_a, zone_b) do
      raise ArgumentError, message: "timezone mismatch between date and time"
    end

    { { date, time }, zone_a }
  end

  def new({ date, zone }, { _, _, _ } = time) do
    { { date, time }, zone }
  end

  def new({ _, _, _ } = date, { time, zone }) do
    { { date, time }, zone }
  end

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone // "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> timezone(zone)
  end

  @spec date(t) :: Date.t
  def date({ { date, _ }, zone }) do
    { date, zone }
  end

  def date({ date, _ }) do
    date
  end

  @spec date(t, Date.t) :: t
  def date({ { _old, time }, zone }, new) do
    { { new, time }, zone }
  end

  def date({ _old, time }, new) when is_date(new, "UTC") do
    { new, time }
  end

  def time({ { _, time }, zone }) do
    { time, zone }
  end

  def time({ _, time }) do
    time
  end

  @spec timezone(t) :: Timezone.t
  def timezone({ { _, _ }, zone }) do
    zone
  end

  def timezone(_) do
    "UTC"
  end

  # TODO: actually change the date and time
  @spec timezone(t, Timezone.t) :: t
  def timezone({ { _, _ } = datetime, _old }, new) do
    if Timezone.equal? new, "UTC" do
      datetime
    else
      { datetime, new }
    end
  end

  def timezone(datetime, new) do
    if Timezone.equal? new, "UTC" do
      datetime
    else
      { datetime, new }
    end
  end

  @spec dst?(t) :: boolean
  def dst?(datetime) do
    zone = timezone(datetime)

    false
  end

  def format(datetime, { :parsed, format }) do
    do_format(datetime, format) |> iolist_to_binary
  end

  def format(datetime, format) do
    format(datetime, parse_format(format))
  end

  @spec epoch :: t
  def epoch do
    { { 1970, 1, 1 }, { 0, 0, 0 } }
  end

  @spec to_epoch(t) :: non_neg_integer
  def to_epoch(datetime) do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    if datetime < epoch do
      raise ArgumentError, message: "cannot convert a datetime less than 1970-1-1 00:00:00"
    end

    :calendar.datetime_to_gregorian_seconds(datetime) -
      :calendar.datetime_to_gregorian_seconds(epoch)
  end

  @spec from_epoch(non_neg_integer) :: t
  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
  end

  defmacro __using__(_opts) do
    quote do
      use Date
      use Time

      import DateTime, only: [is_datetime: 1, is_datetime: 2, sigil_t: 2, sigil_T: 2]
    end
  end

  @spec is_datetime(term) :: boolean
  defmacro is_datetime(var) do
    quote do
      (tuple_size(unquote(var)) == 2 and
        (is_date(elem(unquote(var), 0)) and is_time(elem(unquote(var), 1))) or
        (is_binary(elem(unquote(var), 1)) and
          is_date(elem(elem(unquote(var), 0), 0)) and
          is_time(elem(elem(unquote(var), 0), 1))))
    end
  end

  @spec is_datetime(term, Timezone.t) :: boolean
  defmacro is_datetime(var, zone) when is_binary(zone) do
    if Timezone.equal? zone, "UTC" do
      quote do
        (tuple_size(unquote(var)) == 2 and
          (is_date(elem(unquote(var), 0), unquote(zone)) and
          is_time(elem(unquote(var), 1), unquote(zone))))
      end
    else
      quote do
        (is_timezone(elem(unquote(var), 1), unquote(zone)) and
          is_date(elem(elem(unquote(var), 0), 0)) and
          is_time(elem(elem(unquote(var), 0), 1)))
      end
    end
  end

  @spec sigil_t(String.t, [?d | ?t | ?f]) :: t
  defmacro sigil_t({ _, _, [string] }, 'f') when is_binary(string) do
    Macro.escape parse_format(string)
  end

  defmacro sigil_t(string, 'f') do
    quote do
      DateTime.parse_format(unquote(string))
    end
  end

  defmacro sigil_t({ _, _, [string] }, options) when is_binary(string) do
    Macro.escape parse_datetime(string, options)
  end

  defmacro sigil_t(string, options) do
    quote do
      DateTime.parse_datetime(unquote(string), unquote(options))
    end
  end

  @spec sigil_T(String.t, [?d | ?t | ?f]) :: t
  defmacro sigil_T({ _, _, [string] }, 'f') when is_binary(string) do
    Macro.escape parse_format(string)
  end

  defmacro sigil_T({ _, _, [string] }, options) when is_binary(string) do
    Macro.escape parse_datetime(string, options)
  end

  @doc false
  def parse_datetime(string, options) do
    if string |> is_binary do
      string = binary_to_list(string)
    end

    { :ok, lexed, _  } = :datetime_lexer.string(string)
    { :ok, parsed }    = :datetime_parser.parse(lexed)

    cond do
      Enum.empty?(options) or (Enum.member?(options, ?d) and Enum.member?(options, ?t)) ->
        parsed

      Enum.member?(options, ?d) ->
        if DateTime.valid?(parsed) do
          DateTime.date(parsed)
        else
          parsed
        end

      Enum.member?(options, ?t) ->
        if DateTime.valid?(parsed) do
          DateTime.time(parsed)
        else
          parsed
        end

      true ->
        raise ArgumentError, message: "#{inspect options} is not supported"
    end
  end

  @doc false
  def parse_format(string) do
    if string |> is_binary do
      string = binary_to_list(string)
    end

    { :ok, lexed, _ } = :datetime_format_lexer.string(string)
    { :ok, parsed }   = :datetime_format_parser.parse(lexed)

    { :parsed, parsed }
  end

  defp do_format(datetime, [list | rest]) when is_list(list) do
    list ++ do_format(datetime, rest)
  end

  # day
  defp do_format(datetime, [{ :day, :number, :padded } | rest]) do
    formatted = datetime |> date |> Date.day |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :weekday, :name, :short } | rest]) do
    formatted = datetime |> date
      |> Date.day_of_the_week
      |> weekday(:short)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :day, :number } | rest]) do
    formatted = datetime |> date |> Date.day |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :weekday, :name, :long } | rest]) do
    formatted = datetime |> date
      |> Date.day_of_the_week
      |> weekday

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :weekday, :number, :iso8601 } | rest]) do
    formatted = datetime |> date
      |> Date.day_of_the_week
      |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [:suffix | rest]) do
    formatted = case rem(datetime |> date |> Date.day, 10) do
      1 -> "st"
      2 -> "nd"
      3 -> "rd"
      _ -> "th"
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :weekday, :number } | rest]) do
    formatted = case datetime |> date |> Date.day_of_the_week do
      7 -> 0
      n -> n
    end |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [:yearday | rest]) do
    formatted = datetime |> date |> Date.day_of_the_year |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  # week
  defp do_format(datetime, [{ :week, :number, :iso8601 } | rest]) do
    formatted = datetime |> date |> Date.week_number |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  # month
  defp do_format(datetime, [{ :month, :name, :long } | rest]) do
    formatted = datetime |> date |> Date.month |> month

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :month, :number, :padded } | rest]) do
    formatted = datetime |> date |> Date.month |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :month, :name, :short } | rest]) do
    formatted = datetime |> date |> Date.month |> month(:short)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :month, :number } | rest]) do
    formatted = datetime |> date |> Date.month |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :month, :days } | rest]) do
    formatted = datetime |> date |> Date.month_days |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  # year
  defp do_format(datetime, [{ :year, :leap } | rest]) do
    formatted = case datetime |> date |> Date.leap? do
      true  -> "1"
      false -> "0"
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :year, :number, :iso8601 } | rest]) do
    formatted = datetime |> date |> Date.year |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :year, :number, :long } | rest]) do
    formatted = datetime |> date |> Date.year |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :year, :number, :short } | rest]) do
    formatted = datetime |> date |> Date.year |> rem(100) |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  # time
  defp do_format(datetime, [{ :noon, :lowercase } | rest]) do
    formatted = case datetime |> time |> Time.hour do
      hour when hour >  12 -> "pm"
      hour when hour <= 12 -> "am"
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :noon, :uppercase } | rest]) do
    formatted = case datetime |> time |> Time.hour do
      hour when hour >  12 -> "PM"
      hour when hour <= 12 -> "AM"
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :hour, 12 } | rest]) do
    formatted = datetime |> time |> Time.hour |> rem(12) |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :hour, 24 } | rest]) do
    formatted = datetime |> time |> Time.hour |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :hour, 12, :padded } | rest]) do
    formatted = datetime |> time |> Time.hour |> rem(12) |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :hour, 24, :padded } | rest]) do
    formatted = datetime |> time |> Time.hour |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :minute, :padded } | rest]) do
    formatted = datetime |> time |> Time.minute |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :second, :padded } | rest]) do
    formatted = datetime |> time |> Time.minute |> pad

    [formatted] ++ do_format(datetime, rest)
  end

  # timezone
  defp do_format(datetime, [{ :timezone, :long } | rest]) do
    formatted  = timezone(datetime)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [:daylight | rest]) do
    formatted = case datetime |> dst? do
      true  -> "1"
      false -> "0"
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :offset, :short } | rest]) do
    formatted = case Timezone.offset("UTC", datetime) do
      { sign, { hours, minutes, _ } } ->
        atom_to_binary(sign) <> (hours |> pad) <> (minutes |> pad)
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :offset, :long } | rest]) do
    formatted = case Timezone.offset("UTC", datetime) do
      { sign, { hours, minutes, _ } } ->
        atom_to_binary(sign) <> (hours |> pad) <> ":" <> (minutes |> pad)
    end

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :timezone, :short } | rest]) do
    formatted = timezone(datetime)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :offset, :seconds } | rest]) do
    formatted = case Timezone.offset("UTC", datetime) do
      { sign, time } ->
        atom_to_binary(sign) <> (Time.to_seconds(time) |> integer_to_binary)
    end

    [formatted] ++ do_format(datetime, rest)
  end

  # full date/time
  defp do_format(datetime, [{ :datetime, :iso8601 } | rest]) do
    formatted = format(datetime, %t"o-m-d\TH:i:sP"f)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [{ :datetime, :rfc2882 } | rest]) do
    formatted = format(datetime, %t"D, j M Y H:i:s O"f)

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, [:epoch | rest]) do
    formatted = datetime |> to_epoch |> integer_to_binary

    [formatted] ++ do_format(datetime, rest)
  end

  defp do_format(datetime, []) do
    []
  end

  defp weekday(1), do: "Monday"
  defp weekday(2), do: "Tuesday"
  defp weekday(3), do: "Wednesday"
  defp weekday(4), do: "Thursday"
  defp weekday(5), do: "Friday"
  defp weekday(6), do: "Saturday"
  defp weekday(7), do: "Sunday"

  defp weekday(1, :short), do: "Mon"
  defp weekday(2, :short), do: "Tue"
  defp weekday(3, :short), do: "Wed"
  defp weekday(4, :short), do: "Thu"
  defp weekday(5, :short), do: "Fri"
  defp weekday(6, :short), do: "Sat"
  defp weekday(7, :short), do: "Sun"

  defp month(1),  do: "January"
  defp month(2),  do: "February"
  defp month(3),  do: "March"
  defp month(4),  do: "April"
  defp month(5),  do: "May"
  defp month(6),  do: "June"
  defp month(7),  do: "July"
  defp month(8),  do: "August"
  defp month(9),  do: "September"
  defp month(10), do: "October"
  defp month(11), do: "November"
  defp month(12), do: "December"

  defp month(1, :short),  do: "Jan"
  defp month(2, :short),  do: "Feb"
  defp month(3, :short),  do: "Mar"
  defp month(4, :short),  do: "Apr"
  defp month(5, :short),  do: "May"
  defp month(6, :short),  do: "Jun"
  defp month(7, :short),  do: "Jul"
  defp month(8, :short),  do: "Aug"
  defp month(9, :short),  do: "Sep"
  defp month(10, :short), do: "Oct"
  defp month(11, :short), do: "Nov"
  defp month(12, :short), do: "Dec"

  defp pad(number) when number < 10 do
    "0" <> integer_to_binary(number)
  end

  defp pad(number) do
    integer_to_binary(number)
  end
end
