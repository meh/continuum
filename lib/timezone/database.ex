defmodule Timezone.Database do
  @path Path.join(["..", "..", "priv", "tzdata"]) |> Path.expand(__DIR__)

  defrecord Zone, name: nil, rules: [] do
    defrecord Rule, format: nil, offset: nil, during: nil, references: nil do
      @moduledoc """
      Herp derp.
      """

      # TODO: implement this
      def name_for(date, Rule[format: format]) do
        format
      end
    end

    @moduledoc """
    Herp derp.
    """
  end

  defrecord Rule, name: nil, for: nil, month: nil, day: nil, time: nil, save: nil, type: nil do
    @moduledoc """
    Herp derp.
    """

    def letter(Rule[type: :standard]),        do: "S"
    def letter(Rule[type: :daylight_saving]), do: "D"
    def letter(Rule[type: :war]),             do: "W"
    def letter(Rule[type: :peace]),           do: "P"
    def letter(_),                            do: "-"
  end

  defrecord Link, from: nil, to: nil do
    @moduledoc """
    Herp depr.
    """
  end

  defrecord Leap, at: nil, correction: nil, type: nil do
    @moduledoc """
    Herp derp.
    """
  end

  Module.register_attribute __MODULE__, :links, accumulate: true
  Module.register_attribute __MODULE__, :zones, accumulate: true
  Module.register_attribute __MODULE__, :rules, accumulate: true
  Module.register_attribute __MODULE__, :leaps, accumulate: true

  Enum.each File.ls!(@path), fn path ->
    { :ok, lexed, _  } = Path.join(@path, path) |> File.read! |> String.to_char_list! |> :tzdata_lexer.string
    { :ok, parsed }    = :tzdata_parser.parse(lexed)

    Enum.each parsed, fn
      { :link, from, to } ->
        @links Link.new from: from, to: to

      { :zone, name, rules } ->
        { rules, _ } = Enum.reduce rules, { [], { :local, {{0,1,1},{0,0,0}} } }, fn
          { offset, rules, format, until }, { result, last } ->
            rules = cond do
              is_binary(rules) ->
                Enum.filter @rules, fn rule ->
                  rule.name == rules
                end

              is_tuple(rules) ->
                rules

              true ->
                nil
            end

            rule = Zone.Rule.new(format: format, offset: offset, until: until, references: rules)

            { [rule | result], until }
        end

        @zones Zone.new name: name, rules: Enum.reverse(rules)

      { :rule, name, for, { month, day, at }, save, type } ->
        @rules Rule.new name: name, for: for, month: month, day: day, time: at, save: save, type: type

      { :leap, at, correction, type } ->
        @leaps Leap.new at: at, correction: correction, type: type
    end
  end

  @names Enum.map(@zones, fn z -> z.name end) ++ Enum.map(@links, fn l -> l.to end)

  @spec names :: [Timezone.t]
  def names do
    @names
  end

  @spec contains?(Timezone.t) :: boolean
  defmacro contains?(name) do
    quote do
      unquote(name) in unquote(@names)
    end
  end

  Enum.each @zones, fn zone ->
    name = zone.name

    def get(unquote(name)), do: unquote(Macro.escape(zone))
    def exists?(unquote(name)), do: true
    def equal?(unquote(name), unquote(name)), do: true
  end

  Enum.each @links, fn link ->
    def get(unquote(link.to)), do: unquote(link.from) |> get
    def exists?(unquote(link.to)), do: true
    def equal?(unquote(link.to), unquote(link.to)), do: true
    def equal?(unquote(link.to), unquote(link.from)), do: true
    def equal?(unquote(link.from), unquote(link.to)), do: true
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
  def equal?(_, _),    do: false
  def link_to(_),      do: nil
  def link?(_),        do: false
  def synonyms_for(_), do: nil
end
