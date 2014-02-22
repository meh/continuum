defmodule DateTime do
  use Date
  use Time

  alias DateTime.Format, as: Format

  @type t :: { date :: Date.t, time :: Time.t } |
             { timezone :: Timezone.t, { date :: Date.t, time :: Time.t } }

  import Kernel, except: [<: 2, <=: 2, >: 2, >=: 2, +: 2, -: 2]
  alias Kernel, as: K

  @doc """
  When using DateTime the guard macros and sigils will be imported.
  """
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
        (is_timezone(elem(unquote(var), 1)) and
          is_date(elem(elem(unquote(var), 0), 0)) and
          is_time(elem(elem(unquote(var), 0), 1))))
    end
  end

  @spec is_datetime(term, Timezone.t) :: boolean
  defmacro is_datetime(var, zone) do
    if zone |> Timezone.== "UTC" do
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
    Macro.escape Format.compile(string)
  end

  defmacro sigil_t(string, 'f') do
    quote do
      Format.compile(unquote(string))
    end
  end

  defmacro sigil_t({ _, _, [string] }, options) when is_binary(string) do
    Macro.escape parse(string, options)
  end

  defmacro sigil_t(string, options) do
    quote do
      DateTime.parse(unquote(string), unquote(options))
    end
  end

  @spec sigil_T(String.t, [?d | ?t | ?f]) :: t
  defmacro sigil_T({ _, _, [string] }, 'f') when is_binary(string) do
    Macro.escape Format.compile(string)
  end

  defmacro sigil_T({ _, _, [string] }, options) when is_binary(string) do
    Macro.escape parse(string, options)
  end

  @doc false
  def parse(string, options) do
    if string |> is_binary do
      string = String.to_char_list!(string)
    end

    { :ok, lexed, _  } = :datetime_lexer.string(string)
    { :ok, parsed }    = :datetime_parser.parse(lexed)

    cond do
      Enum.empty?(options) or (Enum.member?(options, ?d) and Enum.member?(options, ?t)) ->
        parsed

      Enum.member?(options, ?d) ->
        if parsed |> is_datetime do
          parsed |> DateTime.date
        else
          parsed
        end

      Enum.member?(options, ?t) ->
        if parsed |> is_datetime do
          parsed |> DateTime.time
        else
          parsed
        end

      true ->
        raise ArgumentError, message: "#{inspect options} is not supported"
    end
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
    unless zone_a |> Timezone.== zone_b do
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

  @spec from_local({ Date.t, Time.t }) :: t
  def from_local(datetime) do
    zone = Timezone.local

    if zone |> Timezone.== "UTC" do
      datetime
    else
      { datetime, zone }
    end
  end

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone \\ "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> timezone(zone)
  end

  @spec local :: t
  def local do
    now(Timezone.local)
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

  def date({ _old, time }, new) when new |> is_date("UTC") do
    { new, time }
  end

  def time({ { _, time }, zone }) do
    { time, zone }
  end

  def time({ _, time }) do
    time
  end

  @doc """
  Get the timezone.
  """
  @spec timezone(t) :: Timezone.t
  def timezone(self) when self |> is_datetime do
    case self do
      { { _, _ }, zone } ->
        zone

      _ ->
        "UTC"
    end
  end

  @doc """
  Change the timezone.

  TODO: actually do the date and time conversion
  """
  @spec timezone(t, Timezone.t) :: t
  def timezone(self, new) when self |> is_datetime do
    timezone = timezone(self)
    datetime = case self do
      { { _, _ } = datetime, _ } ->
        datetime

      datetime ->
        datetime
    end

    if new |> Timezone.== "UTC" do
      datetime
    else
      { datetime, new }
    end
  end

  @doc """
  Check if the DateTime is observing Daylight Saving Time.

  TODO: actually check it based on the timezone and time
  """
  @spec dst?(t) :: boolean
  def dst?(datetime) do
    zone = timezone(datetime)

    false
  end

  @doc """
  Format the date.
  """
  @spec format(t, String.t | list | tuple) :: String.t
  def format(datetime, format, type \\ :php)

  def format(datetime, format, type) when format |> is_binary do
    Format.format(datetime, Format.compile(format, type))
  end

  def format(datetime, format, _type) do
    Format.format(datetime, format)
  end

  @spec parse!(String.t, String.t | list | tuple)           :: t | no_return
  @spec parse!(String.t, String.t | list | tuple, Format.t) :: t | no_return
  def parse!(string, format, type \\ :php) do
    case parse(string, format, type) do
      { :ok, { result, _rest } } ->
        result

      { :error, message } ->
        raise DateTime.ParseError, message: message

      { result, _rest } ->
        result
    end
  end

  @spec parse(String.t, String.t | list | tuple)           :: { :ok, t } | { :error, term }
  @spec parse(String.t, String.t | list | tuple, Format.t) :: { :ok, t } | { :error, term }
  def parse(string, format, type \\ :php)

  def parse(string, format, type) when format |> is_binary do
    Format.parse(string, Format.compile(format, type))
  end

  def parse(string, format, _type) do
    Format.parse(string, format)
  end

  @doc """
  Subtract the descriptor or seconds from the DateTime.
  """
  @spec t - (integer | Keyword.t) :: t
  def datetime - seconds when seconds |> is_integer do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    from_seconds(to_seconds(datetime) |> K.- seconds)
  end

  def datetime - descriptor do
    datetime - to_seconds(descriptor)
  end

  @doc """
  Add the descriptor or seconds to the DateTime.
  """
  @spec t + (integer | Keyword.t) :: t
  def datetime + seconds when seconds |> is_integer do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    from_seconds(to_seconds(datetime) |> K.+ seconds)
  end

  def datetime + descriptor do
    datetime + to_seconds(descriptor)
  end

  @spec epoch :: t
  def epoch do
    { { 1970, 1, 1 }, { 0, 0, 0 } }
  end

  @doc """
  Convert the DateTime to UNIX epoch time.
  """
  @spec to_epoch(t) :: non_neg_integer
  def to_epoch(datetime) do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    if datetime |> K.< epoch do
      raise ArgumentError, message: "cannot convert a datetime less than 1970-1-1 00:00:00"
    end

    K.-(:calendar.datetime_to_gregorian_seconds(datetime),
      :calendar.datetime_to_gregorian_seconds(epoch))
  end

  @doc """
  Convert UNIX epoch time to DateTime.
  """
  @spec from_epoch(non_neg_integer) :: t
  def from_epoch(seconds) do
    K.+(:calendar.datetime_to_gregorian_seconds(DateTime.epoch), seconds)
      |> :calendar.gregorian_seconds_to_datetime
  end

  @doc """
  Convert a DateTime or a descriptor to seconds.
  """
  @spec to_seconds(Keyword.t | t) :: integer
  def to_seconds(descriptor) when is_list(descriptor) do
    result = 0

    if seconds = descriptor[:seconds] || descriptor[:second] do
      result = result |> K.+ seconds
    end

    if minutes = descriptor[:minutes] || descriptor[:minute] do
      result = result |> K.+ (minutes * 60)
    end

    if hours = descriptor[:hours] || descriptor[:hour] do
      result = result |> K.+ (hours * 60 * 60)
    end

    if days = descriptor[:days] || descriptor[:day] do
      result = result |> K.+ (days * 24 * 60 * 60)
    end

    if weeks = descriptor[:weeks] || descriptor[:week] do
      result = result |> K.+ (weeks * 7 * 24 * 60 * 60)
    end

    result
  end

  def to_seconds(datetime) do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    :calendar.datetime_to_gregorian_seconds(datetime)
  end

  @doc """
  Convert seconds to DateTime.
  """
  @spec from_seconds(integer) :: t
  def from_seconds(seconds, timezone \\ "UTC") do
    :calendar.gregorian_seconds_to_datetime(seconds)
  end

  def a < b do
    normalize(a) |> K.< normalize(b)
  end

  def a <= b do
    normalize(a) |> K.<= normalize(b)
  end

  def a > b do
    normalize(a) |> K.> normalize(b)
  end

  def a >= b do
    normalize(a) |> K.>= normalize(b)
  end

  defp normalize(value) when value |> is_integer do
    { { value, 1, 1 }, { 0, 0, 0 } }
  end

  defp normalize(value) when value |> is_date do
    { value, { 0, 0, 0 } }
  end

  defp normalize(value) when value |> is_datetime do
    value
  end
end
