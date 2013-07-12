defmodule DateTime do
  use Date
  use Time

  @type t :: { Date.t, Time.t } | { Timezone.t, { Date.t, Time.t } }

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

  def new({ zone, date }) do
    { zone, { date, { 0, 0, 0 } } }
  end

  def new({ _, _, _ } = date) do
    { date, { 0, 0, 0 } }
  end

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

  def now do
    :calendar.now_to_datetime(:erlang.now)
  end

  def date({ zone, { date, _ } }) do
    { zone, date }
  end

  def date({ date, _ }) do
    date
  end

  def time({ zone, { _, time } }) do
    { zone, time }
  end

  def time({ _, time }) do
    time
  end

  def timezone({ _, { _, _ } }) do
    "UTC"
  end

  def timezone({ zone, _ }) do
    zone
  end

  # TODO: actually change the date and time
  def timezone({ old, { _, _ } = datetime }, new) do
    { new, datetime }
  end

  def timezone(datetime, new) do
    { new, datetime }
  end

  def epoch do
    { { 1970, 1, 1 }, { 0, 0, 0 } }
  end

  def to_epoch(datetime) do
    zone     = timezone(datetime)
    datetime = timezone(datetime, "UTC")

    if datetime < epoch do
      raise ArgumentError, message: "cannot convert a datetime less than 1970-1-1 00:00:00"
    end

    :calendar.datetime_to_gregorian_seconds(datetime) -
      :calendar.datetime_to_gregorian_seconds(epoch)
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
  end

  defmacro __using__(_opts) do
    quote do
      use Date
      use Time

      import DateTime, only: [is_datetime: 1, sigil_t: 2, sigil_T: 2]
    end
  end

  defmacro is_datetime(var) do
    quote do
      (tuple_size(unquote(var)) == 2 and
        (is_date(elem(unquote(var), 0)) and is_time(elem(unquote(var), 1))) or
        (is_binary(elem(unquote(var), 0)) and
          is_date(elem(elem(unquote(var), 1), 0)) and
          is_time(elem(elem(unquote(var), 1), 1))))
    end
  end

  def sigil_t(string, options) do

  end

  def sigil_T(string, options) do
    sigil_t(string, options)
  end
end
