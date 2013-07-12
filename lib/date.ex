defmodule Date do
  @type year  :: non_neg_integer
  @type month :: 1 .. 12
  @type day   :: 1 .. 31
  @type week  :: 1 .. 53

  @type t :: { year, month, day } | { Timezone.t, { year, month, day } }

  def valid?({ year, month, day }) do
    :calendar.valid_date(year, month, day)
  end

  def valid?({ zone, { year, month, day } }) do
    Timezone.exists?(zone) and :calendar.valid_date(year, month, day)
  end

  def now do
    :calendar.now_to_datetime(:erlang.now) |> elem(0)
  end

  def timezone({ _, _, _ }) do
    "UTC"
  end

  def timezone({ zone, _ }) do
    zone
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(0)
  end

  def to_epoch(date) do
    zone = timezone(date)
    date = timezone(date, "UTC")

    if date < (DateTime.epoch |> DateTime.date) do
      raise ArgumentError, message: "cannot convert a date less than 1970-1-1"
    end

    :calendar.datetime_to_gregorian_seconds({ date, { 0, 0, 0 } }) -
      :calendar.datetime_to_gregorian_seconds(DataTime.epoch)
  end

  defmacro __using__(_opts) do
    quote do
      import Date, only: [is_date: 1]
    end
  end

  defmacro is_date(var) do
    quote do
      ((tuple_size(unquote(var)) == 3 and elem(unquote(var), 0) > 0 and
                                          elem(unquote(var), 1) in 1 .. 12 and
                                          elem(unquote(var), 2) in 1 .. 32) or
       (tuple_size(unquote(var)) == 2 and is_binary(elem(unquote(var), 0)) and
         tuple_size(elem(unquote(var), 0)) == 3 and elem(elem(unquote(var), 1), 0) > 0 and
                                                    elem(elem(unquote(var), 1), 1) in 1 .. 12 and
                                                    elem(elem(unquote(var), 1), 2) in 1 .. 31))
    end
  end
end
