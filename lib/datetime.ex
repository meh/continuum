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
end
