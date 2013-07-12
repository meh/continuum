defmodule Time do
  @type hour   :: 0 .. 23
  @type minute :: 0 .. 59
  @type second :: 0 .. 59

  @type t :: { hour, minute, second } | { Timezone.t, { hour, minute, second } }

  def valid?({ hour, minute, second }) when hour   in 0 .. 23 and
                                            minute in 0 .. 59 and
                                            second in 0 .. 59 do
    true
  end

  def valid?({ zone, time }) do
    Timezone.exists?(zone) and valid?(time)
  end

  def valid?(_) do
    false
  end

  def now do
    :calendar.now_to_datetime(:erlang.now) |> elem(1)
  end

  def from_epoch(seconds) do
    (:calendar.datetime_to_gregorian_seconds(DateTime.epoch) + seconds)
      |> :calendar.gregorian_seconds_to_datetime
      |> elem(1)
  end
end
