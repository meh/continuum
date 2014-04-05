defmodule Continuum do
  defmacro __using__(_opts) do
    quote do
      alias Continuum.Date
      alias Continuum.Time
      alias Continuum.DateTime
      alias Continuum.Timezone
      alias Continuum.Timer
      alias Continuum.StopWatch
    end
  end
end
