defmodule Time do
  @type hour   :: 0 .. 23
  @type minute :: 0 .. 59
  @type second :: 0 .. 59

  @type t :: { hour, minute, second } | { Timezone.t, { hour, minute, second } }

  @spec valid?(t) :: boolean
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

  @spec now             :: t
  @spec now(Timezone.t) :: t
  def now(zone // "UTC") do
    :calendar.now_to_datetime(:erlang.now) |> elem(1) |> timezone(zone)
  end

  @spec hour(t) :: hour
  def hour({ _, time }),    do: hour(time)
  def hour({ hour, _, _ }), do: hour

  @spec minute(t) :: minute
  def minute({ _, time }),      do: minute(time)
  def minute({ _, minute, _ }), do: minute

  @spec second(t) :: second
  def second({ _, time }),      do: second(time)
  def second({ _, _, second }), do: second

  @spec timezone(t) :: Timezone.t
  def timezone({ _, _, _ }) do
    "UTC"
  end

  def timezone({ zone, _ }) do
    zone
  end

  @spec timezone(t, Timezone.t) :: t
  def timezone({ _old, time }, new) do
    if Timezone.equal? new, "UTC" do
      time
    else
      { new, time }
    end
  end

  def timezone(time, new) do
    if Timezone.equal? new, "UTC" do
      time
    else
      { new, time }
    end
  end

  @spec from_epoch(non_neg_integer) :: t
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

  @spec is_time(term) :: boolean
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

  @spec is_time(term, Timezone.t) :: boolean
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
