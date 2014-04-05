#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Continuum.Date do
  use Continuum
  use Timezone

  @type year    :: non_neg_integer
  @type month   :: 1 .. 12
  @type day     :: 1 .. 31
  @type week    :: 1 .. 53
  @type weekday :: 1 .. 7
  @type yearday :: 1 .. 366

  @type t :: { year, month, day } | { { year, month, day }, Timezone.t }

  @doc """
  Using Date will import the `is_date` guards.
  """
  defmacro __using__(_opts) do
    quote do
      use Continuum.Timezone

      import Continuum.Date, only: [is_date: 1, is_date: 2]
    end
  end

  @spec is_date(term) :: boolean
  defmacro is_date(var) do
    quote do
      (is_tuple(unquote(var)) and tuple_size(unquote(var)) == 3 and
        elem(unquote(var), 0) > 0 and
        elem(unquote(var), 1) in 1 .. 12 and
        elem(unquote(var), 2) in 1 .. 32) or
      (is_tuple(unquote(var)) and tuple_size(unquote(var)) == 2 and is_timezone(elem(unquote(var), 1)) and
        is_tuple(elem(unquote(var), 0)) and tuple_size(elem(unquote(var), 0)) == 3 and
          elem(elem(unquote(var), 0), 0) > 0 and
          elem(elem(unquote(var), 0), 1) in 1 .. 12 and
          elem(elem(unquote(var), 0), 2) in 1 .. 31)
    end
  end

  @spec is_date(term, Timezone.t) :: boolean
  defmacro is_date(var, zone) do
    if zone |> Timezone.== "UTC" do
      quote do
        is_tuple(unquote(var)) and tuple_size(unquote(var)) == 3 and
          elem(unquote(var), 0) > 0 and
          elem(unquote(var), 1) in 1 .. 12 and
          elem(unquote(var), 2) in 1 .. 32
      end
    else
      quote do
        is_tuple(unquote(var)) and tuple_size(unquote(var)) == 2 and is_timezone(elem(unquote(var), 1), unquote(zone)) and
          is_tuple(elem(unquote(var), 0)) and tuple_size(elem(unquote(var), 0)) == 3 and
            elem(elem(unquote(var), 0), 0) > 0 and
            elem(elem(unquote(var), 0), 1) in 1 .. 12 and
            elem(elem(unquote(var), 0), 2) in 1 .. 31
      end
    end
  end

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone \\ "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> elem(0) |> timezone(zone)
  end

  @spec year(t) :: year
  def year({ year, _, _ }), do: year
  def year({ { year, _, _ }, _ }), do: year

  @spec year(t, year) :: t
  def year({ _, month, day }, year), do: { year, month, day }

  @spec month(t) :: month
  def month({ _, month, _ }), do: month
  def month({ { _, month, _ }, _ }), do: month

  @spec month(t, month) :: t
  def month({ year, _, day }, month), do: { year, month, day }

  @spec day(t) :: day
  def day({ _, _, day }), do: day
  def day({ { _, _, day }, _ }), do: day

  @spec day(t, day) :: t
  def day({ year, month, _ }, day), do: { year, month, day }

  @spec timezone(t) :: Timezone.t
  def timezone({ _, _, _ }) do
    "UTC"
  end

  def timezone({ _, zone }) do
    zone
  end

  # TODO: actually do the date change
  @spec timezone(t, Timezone.t) :: t
  def timezone({ date, _old }, new) do
    if new |> Timezone.== "UTC" do
      date
    else
      { new, date }
    end
  end

  def timezone(date, new) do
    if new |> Timezone.== "UTC" do
      date
    else
      { date, new }
    end
  end

  @spec day_of_the_year(t) :: yearday
  def day_of_the_year({ date, _ }) do
    day_of_the_year(date)
  end

  def day_of_the_year({ year, month, day }) do
    begins = :calendar.date_to_gregorian_days(year, 1, 1)
    ends   = :calendar.date_to_gregorian_days(year, month, day)

    ends - begins
  end

  @spec day_of_the_week(t) :: weekday
  def day_of_the_week({ date, _ }) do
    day_of_the_week(date)
  end

  def day_of_the_week({ year, month, day }) do
    :calendar.day_of_the_week(year, month, day)
  end

  @spec week_number(t) :: week
  def week_number({ date, _ }) do
    week_number(date)
  end

  def week_number(date) do
    :calendar.iso_week_number(date) |> elem(1)
  end

  @spec month_days(t) :: day
  def month_days({ date, _ }) do
    month_days(date)
  end

  def month_days({ year, month, _ }) do
    :calendar.last_day_of_the_month(year, month)
  end

  @spec month_days(year, month) :: day
  def month_days(year, month) do
    :calendar.last_day_of_the_month(year, month)
  end

  @spec leap?(t | year) :: boolean
  def leap?({ date, _ }) do
    leap?(date)
  end

  def leap?({ year, _, _ }) do
    leap?(year)
  end

  def leap?(year) do
    :calendar.is_leap_year(year)
  end

  @spec from_epoch(non_neg_integer) :: t
  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(0)
  end

  @spec to_epoch(t) :: non_neg_integer
  def to_epoch(date) do
    zone = timezone(date)
    date = timezone(date, "UTC")

    if date < (DateTime.epoch |> DateTime.date) do
      raise ArgumentError, message: "cannot convert a date less than 1970-1-1"
    end

    :calendar.datetime_to_gregorian_seconds({ date, { 0, 0, 0 } }) -
      :calendar.datetime_to_gregorian_seconds(DateTime.epoch)
  end

  @spec format(t, String.t | list | tuple)           :: String.t
  @spec format(t, String.t | list | tuple, Format.t) :: String.t
  def format(date, format, type \\ :php) do
    DateTime.new(date) |> DateTime.format(format, type)
  end

  @spec parse(String.t, String.t | list | tuple)           :: { :ok, t } | { :error, term }
  @spec parse(String.t, String.t | list | tuple, Format.t) :: { :ok, t } | { :error, term }
  def parse(string, format, type \\ :php) do
    case DateTime.parse(string, format, type) do
      { :ok, { datetime, rest } } ->
        { :ok, { datetime |> DateTime.date, rest } }

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
