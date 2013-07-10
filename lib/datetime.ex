defmodule DateTime do
  @type t :: { Date.t, Time.t }

  def now do
    :calendar.now_to_datetime(:erlang.now)
  end

  def date({ date, _ }) do
    date
  end

  def time({ _, time }) do
    time
  end

  def valid?({ date, time }) do
    Date.valid?(date) and Time.valid?(time)
  end

  def epoch do
    { { 1970, 1, 1 }, { 0, 0, 0 } }
  end

  def to_epoch(datetime) do
    :calendar.datetime_to_gregorian_seconds(datetime) -
      :calendar.datetime_to_gregorian_seconds(epoch)
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
  end
end
