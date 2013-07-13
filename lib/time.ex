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

  defmacro __using__(_opts) do
    quote do
      import Time, only: [is_time: 1, is_time: 2]
    end
  end

  defmacro is_time(var) do
    quote do
      ((tuple_size(unquote(var)) == 3 and elem(unquote(var), 0) in 0 .. 23 and
                                          elem(unquote(var), 1) in 0 .. 59 and
                                          elem(unquote(var), 2) in 0 .. 59) or
       (tuple_size(unquote(var)) == 2 and is_binary(elem(unquote(var), 0)) and
         tuple_size(elem(unquote(var), 0)) == 3 and elem(elem(unquote(var), 1), 0) in 0 .. 23 and
                                                    elem(elem(unquote(var), 1), 1) in 0 .. 59 and
                                                    elem(elem(unquote(var), 1), 2) in 0 .. 59))
    end
  end

  defmacro is_time(var, zone) when is_binary(zone) do
    if Timezone.equal? zone, "UTC" do
      quote do
        (tuple_size(unquote(var)) == 3 and elem(unquote(var), 0) in 0 .. 23 and
                                           elem(unquote(var), 1) in 0 .. 59 and
                                           elem(unquote(var), 2) in 0 .. 59)
      end
    else
      quote do
        (tuple_size(unquote(var)) == 2 and is_timezone(elem(unquote(var), 0), unquote(zone)) and
          tuple_size(elem(unquote(var), 0)) == 3 and elem(elem(unquote(var), 1), 0) in 0 .. 23 and
                                                     elem(elem(unquote(var), 1), 1) in 0 .. 59 and
                                                     elem(elem(unquote(var), 1), 2) in 0 .. 59)
      end
    end
  end
end
