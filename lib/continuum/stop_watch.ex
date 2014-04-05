#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Continuum.StopWatch do
  defrecord Elapsed, microseconds: nil do
    def at(time) do
      Elapsed[microseconds: time]
    end

    def seconds(Elapsed[microseconds: number]) do
      rem(trunc(number / 1_000_000), 60)
    end

    def to_integer(Elapsed[microseconds: number]) do
      number
    end

    defimpl Inspect do
      use Continuum

      def inspect(StopWatch.Elapsed[microseconds: mcs], _opts) do
        cond do
          mcs >= 1_000_000 ->
            to_string :io_lib.format("~p seconds", [mcs / 1_000_000])

          mcs >= 1_000 ->
            to_string :io_lib.format("~p milliseconds", [mcs / 1_000])

          true ->
            to_string :io_lib.format("~p microseconds", [mcs])
        end
      end
    end
  end

  defrecordp :watch, start: nil

  def start do
    watch(start: :erlang.now)
  end

  def elapsed(watch(start: { _, start_s, start_m })) do
    { _, stop_s, stop_m } = :erlang.now

    Elapsed.at((stop_s * 1_000_000 + stop_m) - (start_s * 1_000_000 + start_m))
  end
end
