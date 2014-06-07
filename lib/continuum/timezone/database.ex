#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

alias Continuum.Timezone.Database

defmodule Database.Zone do
  defstruct name: nil, rules: []

  defmodule Rule do
    defstruct format: nil, offset: nil, during: nil, references: nil

    # TODO: implement this
    def name_for(date, %Rule{format: format}) do
      format
    end
  end
end

defmodule Database.Rule do
  defstruct name: nil, for: nil, month: nil, day: nil, time: nil, save: nil, type: nil

  def letter(%__MODULE__{type: :standard}),        do: "S"
  def letter(%__MODULE__{type: :daylight_saving}), do: "D"
  def letter(%__MODULE__{type: :war}),             do: "W"
  def letter(%__MODULE__{type: :peace}),           do: "P"
  def letter(_),                                   do: "-"
end

defmodule Database.Link do
  defstruct from: nil, to: nil
end

defmodule Database.Leap do
  defstruct at: nil, correction: nil, type: nil
end

# FIXME: bug in Elixir?
defmodule Continuum.Timezone.Database do
  @path Path.join(["..", "..", "..", "priv", "tzdata"]) |> Path.expand(__DIR__)

  Module.register_attribute __MODULE__, :links, accumulate: true
  Module.register_attribute __MODULE__, :zones, accumulate: true
  Module.register_attribute __MODULE__, :rules, accumulate: true
  Module.register_attribute __MODULE__, :leaps, accumulate: true

  require Database.Zone
  require Database.Zone.Rule
  require Database.Rule
  require Database.Leap
  require Database.Link

  alias Database.Zone
  alias Database.Rule
  alias Database.Leap
  alias Database.Link

  Enum.each File.ls!(@path), fn path ->
    { :ok, lexed, _  } = Path.join(@path, path) |> File.read! |> String.to_char_list |> :tzdata_lexer.string
    { :ok, parsed }    = :tzdata_parser.parse(lexed)

    Enum.each parsed, fn
      { :link, from, to } ->
        @links %Link{from: from, to: to}

      { :zone, name, rules } ->
        { rules, _ } = Enum.reduce rules, { [], { :local, {{0,1,1},{0,0,0}} } }, fn
          { offset, rules, format, until }, { result, last } ->
            rules = cond do
              rules |> is_binary ->
                Enum.filter @rules, fn rule ->
                  rule.name == rules
                end

              rules |> is_tuple ->
                rules

              true ->
                nil
            end

            rule = %Zone.Rule{format: format, offset: offset, during: until, references: rules}

            { [rule | result], until }
        end

        @zones %Zone{name: name, rules: Enum.reverse(rules)}

      { :rule, name, for, { month, day, at }, save, type } ->
        @rules %Rule{name: name, for: for, month: month, day: day, time: at, save: save, type: type}

      { :leap, at, correction, type } ->
        @leaps %Leap{at: at, correction: correction, type: type}
    end
  end

  @names Enum.map(@zones, &(&1.name)) ++ Enum.map(@links, &(&1.to))

  @spec names :: [Continuum.Timezone.t]
  def names do
    @names
  end

  @spec contains?(Continuum.Timezone.t) :: boolean
  defmacro contains?(name) do
    quote do
      unquote(name) in unquote(@names)
    end
  end

  Enum.each @zones, fn zone ->
    name = zone.name

    def get(unquote(name)), do: unquote(Macro.escape(zone))
    def exists?(unquote(name)), do: true
    def equals?(unquote(name), unquote(name)), do: true
  end

  Enum.each @links, fn link ->
    def get(unquote(link.to)), do: unquote(link.from) |> get
    def exists?(unquote(link.to)), do: true
    def equals?(unquote(link.to), unquote(link.to)), do: true
    def equals?(unquote(link.to), unquote(link.from)), do: true
    def equals?(unquote(link.from), unquote(link.to)), do: true
    def link_to(unquote(link.to)), do: unquote(link.from)
    def link?(unquote(link.to)), do: true
  end

  # define synonyms
  linked_names = Enum.reduce @links, HashDict.new, fn link, acc ->
    Dict.update(acc, link.from, [], &[link.to | &1])
  end

  Enum.each linked_names, fn { name, links } ->
    synonyms = [name | links]

    Enum.each synonyms, fn name ->
      def synonyms_for(unquote(name)), do: unquote(synonyms)
    end
  end

  Enum.each @zones, fn zone ->
    unless Dict.has_key?(linked_names, zone.name) do
      def synonyms_for(unquote(zone.name)), do: [unquote(zone.name)]
    end
  end

  def exists?(_),      do: false
  def equals?(_, _),   do: false
  def link_to(_),      do: nil
  def link?(_),        do: false
  def synonyms_for(_), do: nil
end
