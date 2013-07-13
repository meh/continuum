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

  def valid?({ zone, { date, time } }) do
    Timezone.exists?(zone) and Date.valid?(date) and Time.valid?(time)
  end

  def valid?({ date, time }) do
    Date.valid?(date) and Time.valid?(time)
  end

  @spec new(Date.t) :: t
  def new({ zone, date }) do
    { zone, { date, { 0, 0, 0 } } }
  end

  def new({ _, _, _ } = date) do
    { date, { 0, 0, 0 } }
  end

  @spec new(Date.t, Time.t) :: t
  def new({ _, _, _ } = date, { _, _, _ } = time) do
    { date, time }
  end

  def new({ zone_a, date }, { zone_b, time }) do
    unless Timezone.equal?(zone_a, zone_b) do
      raise ArgumentError, message: "timezone mismatch between date and time"
    end

    { zone_a, { date, time } }
  end

  def new({ zone, date }, { _, _, _ } = time) do
    { zone, { date, time } }
  end

  def new({ _, _, _ } = date, { zone, time }) do
    { zone, { date, time } }
  end

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone // "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> timezone(zone)
  end

  @spec date(t) :: Date.t
  def date({ zone, { date, _ } }) do
    { zone, date }
  end

  def date({ date, _ }) do
    date
  end

  @spec date(t, Date.t) :: t
  def date({ zone, { _old, time } }, new) do
    { zone, { new, time } }
  end

  def date({ _old, time }, new) when is_date(new, "UTC") do
    { new, time }
  end

  def time({ zone, { _, time } }) do
    { zone, time }
  end

  def time({ _, time }) do
    time
  end

  @spec timezone(t) :: Timezone.t
  def timezone({ _, { _, _ } }) do
    "UTC"
  end

  def timezone({ zone, _ }) do
    zone
  end

  # TODO: actually change the date and time
  @spec timezone(t, Timezone.t) :: t
  def timezone({ _old, { _, _ } = datetime }, new) do
    if Timezone.equal? new, "UTC" do
      datetime
    else
      { new, datetime }
    end
  end

  def timezone(datetime, new) do
    if Timezone.equal? new, "UTC" do
      datetime
    else
      { new, datetime }
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
        (is_binary(elem(unquote(var), 0)) and
          is_date(elem(elem(unquote(var), 1), 0)) and
          is_time(elem(elem(unquote(var), 1), 1))))
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
        (is_timezone(elem(unquote(var), 0), unquote(zone)) and
          is_date(elem(elem(unquote(var), 1), 0)) and
          is_time(elem(elem(unquote(var), 1), 1)))
      end
    end
  end

  @spec sigil_t(String.t, [?d | ?t]) :: t
  def sigil_t(string, options) do
    { :ok, lexed, _  } = binary_to_list(string) |> :datetime_lexer.string
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

  @spec sigil_T(String.t, [?d | ?t]) :: t
  def sigil_T(string, options) do
    sigil_t(string, options)
  end
end
