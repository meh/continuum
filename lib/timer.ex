#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Timer do
  defmacro __using__(_opts) do
    quote do
      import Timer, only: [once: 2, every: 2]
    end
  end

  @type t    :: :timer.tref
  @type time :: integer | float | Keyword.t | :infinity

  @spec sleep(time) :: none
  def sleep(time \\ :infinity) do
    :timer.sleep(convert(time))
  end

  @spec cancel(t) :: none
  def cancel(ref) do
    :timer.cancel(ref)
  end

  @spec once(time, do: term) :: t
  defmacro once(time, do: block) do
    quote do
      { :ok, ref } = :timer.apply_after unquote(convert(time)),
        unquote(__MODULE__), :call, [fn -> unquote(block) end]

      ref
    end
  end

  @spec every(time, do: term) :: t
  defmacro every(time, do: block) do
    quote do
      { :ok, ref }  = :timer.apply_interval unquote(convert(time)),
        unquote(__MODULE__), :call, [fn -> unquote(block) end]

      ref
    end
  end

  @spec measure(function, list) :: { time, term }
  def measure(fun, args \\ []) do
    :timer.tc(fun, args)
  end

  @doc false
  def call(fun) do
    fun.()
  end

  @doc false
  def convert(time) when time |> is_number do
    time * 1000
  end

  def convert(:infinity) do
    :infinity
  end

  def convert(time) do
    DateTime.to_seconds(time) * 1000
  end
end
