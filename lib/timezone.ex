defmodule Timezone do
  defrecord Zone, offset: 0, rule: nil, format: nil, time: nil
  defrecord Rule, year: nil, month: nil, day: nil, time: nil, save: nil, letters: nil
  defrecord Rules, name: nil, rules: []
end
