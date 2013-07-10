defmodule Date do
  @type year  :: non_neg_integer
  @type month :: 1 .. 12
  @type day   :: 1 .. 31
  @type week  :: 1 .. 53

  @type t :: { year, month, day }

  def now do
    :calendar.now_to_datetime(:erlang.now) |> elem(0)
  end

  def valid?({ year, month, day }) do
    :calendar.valid_date(year, month, day)
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(0)
  end

  def to_epoch(date) do
    :calendar.datetime_to_gregorian_seconds({ date, { 0, 0, 0 } }) -
      :calendar.datetime_to_gregorian_seconds(DataTime.epoch)
  end
end
