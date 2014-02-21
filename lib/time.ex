defmodule Time do
  @type hour   :: 0 .. 23
  @type minute :: 0 .. 59
  @type second :: 0 .. 59

  @type t :: { hour, minute, second } | { { hour, minute, second }, Timezone.t }

  defmacro __using__(_opts) do
    quote do
      use Timezone

      import Time, only: [is_time: 1, is_time: 2]
    end
  end

  @spec is_time(term) :: boolean
  defmacro is_time(var) do
    quote do
      ((tuple_size(unquote(var)) == 3 and elem(unquote(var), 0) in 0 .. 23 and
                                          elem(unquote(var), 1) in 0 .. 59 and
                                          elem(unquote(var), 2) in 0 .. 59) or
       (tuple_size(unquote(var)) == 2 and is_timezone(elem(unquote(var), 1)) and
         tuple_size(elem(unquote(var), 0)) == 3 and elem(elem(unquote(var), 0), 0) in 0 .. 23 and
                                                    elem(elem(unquote(var), 0), 1) in 0 .. 59 and
                                                    elem(elem(unquote(var), 0), 2) in 0 .. 59))
    end
  end

  @spec is_time(term, Timezone.t) :: boolean
  defmacro is_time(var, zone) do
    if zone |> Timezone.== "UTC" do
      quote do
        (tuple_size(unquote(var)) == 3 and elem(unquote(var), 0) in 0 .. 23 and
                                           elem(unquote(var), 1) in 0 .. 59 and
                                           elem(unquote(var), 2) in 0 .. 59)
      end
    else
      quote do
        (tuple_size(unquote(var)) == 2 and is_timezone(elem(unquote(var), 1), unquote(zone)) and
          tuple_size(elem(unquote(var), 0)) == 3 and elem(elem(unquote(var), 0), 0) in 0 .. 23 and
                                                     elem(elem(unquote(var), 0), 1) in 0 .. 59 and
                                                     elem(elem(unquote(var), 0), 2) in 0 .. 59)
      end
    end
  end

  def new(data, zone \\ "UTC") do
    seconds = Keyword.get(data, :seconds, 0)
    seconds = seconds + (Keyword.get(data, :minutes, 0) * 60)
    seconds = seconds + (Keyword.get(data, :hours, 0) * 60 * 60)

    time = { trunc(seconds / 60 / 60), trunc(rem(seconds, 60 * 60) / 60), rem(seconds, 60) }

    if zone |> Timezone.== "UTC" do
      time
    else
      { time, zone }
    end
  end

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone \\ "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> elem(1) |> timezone(zone)
  end

  @spec hour(t) :: hour
  def hour({ time, _ }),    do: hour(time)
  def hour({ hour, _, _ }), do: hour

  @spec minute(t) :: minute
  def minute({ time, _ }),      do: minute(time)
  def minute({ _, minute, _ }), do: minute

  @spec second(t) :: second
  def second({ time, _ }),      do: second(time)
  def second({ _, _, second }), do: second

  @spec timezone(t) :: Timezone.t
  def timezone({ _, _, _ }) do
    "UTC"
  end

  def timezone({ _, zone }) do
    zone
  end

  @spec timezone(t, Timezone.t) :: t
  def timezone({ time, _old }, new) do
    if new |> Timezone.== "UTC" do
      time
    else
      { time, new }
    end
  end

  def timezone(time, new) do
    if new |> Timezone.== "UTC" do
      time
    else
      { time, new }
    end
  end

  @spec seconds_from_midnight(t) :: non_neg_integer
  def seconds_from_midnight({ time, _ }) do
    seconds_from_midnight(time)
  end

  def seconds_from_midnight(time) do
    :calendar.datetime_to_gregorian_seconds({ { 0, 1, 1 }, time })
  end

  @spec to_seconds(t) :: non_neg_integer
  def to_seconds({ time, _ }) do
    to_seconds(time)
  end

  def to_seconds({ hour, minute, second }) do
    hour * 60 * 60 + minute * 60 + second
  end

  @spec from_epoch(non_neg_integer) :: t
  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(1)
  end

  @spec format(t, String.t | list | tuple)           :: String.t
  @spec format(t, String.t | list | tuple, Format.t) :: String.t
  def format(date, format, type \\ :php) do
    DateTime.new({ 1, 1, 0 }, date) |> DateTime.format(format, type)
  end

  @spec parse(String.t, String.t | list | tuple)           :: { :ok, t } | { :error, term }
  @spec parse(String.t, String.t | list | tuple, Format.t) :: { :ok, t } | { :error, term }
  def parse(string, format, type \\ :php) do
    case DateTime.parse(string, format, type) do
      { :ok, { datetime, rest } } ->
        { :ok, { datetime |> DateTime.time, rest } }

      result ->
        result
    end
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
end
