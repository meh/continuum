defmodule Time do
  @type hour   :: 0 .. 23
  @type minute :: 0 .. 59
  @type second :: 0 .. 59

  @type t :: { hour, minute, second }

  def now do
    :calendar.now_to_datetime(:erlang.now) |> elem(1)
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(1)
  end
end
