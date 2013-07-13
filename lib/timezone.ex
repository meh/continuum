#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Timezone do
  @type t :: String.t

  @db Path.join(["..", "..", "priv", "tzdata"]) |> Path.expand(__FILE__)

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

  Enum.each File.ls!(@db), fn path ->
    { :ok, lexed, _  } = Path.join(@db, path) |> File.read! |> binary_to_list |> :tzdata_lexer.string
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

  Enum.each @zones, fn zone ->
    name = zone.name
    zone = Macro.escape(zone)

    def :get,     [name],       [], do: quote(do: unquote(zone))
    def :exists?, [name],       [], do: true
    def :equal?,  [name, name], [], do: true
  end

  Enum.each @links, fn link ->
    def :get,     [link.to],            [], do: quote(do: get(unquote(link.from)))
    def :exists?, [link.to],            [], do: true
    def :equal?,  [link.to, link.from], [], do: true
    def :equal?,  [link.to, link.to],   [], do: true
    def :equal?,  [link.from, link.to], [], do: true
    def :link_to, [link.to],            [], do: quote(do: unquote(link.from))
    def :link?,   [link.to],            [], do: true
  end

  # define synonyms
  Enum.reduce(@links, HashDict.new, fn link, acc ->
    Dict.update(acc, link.from, [], [link.to | &1])
  end) |> Enum.each(fn { name, links } ->
    synonyms = [name | links]

    Enum.each synonyms, fn name ->
      def :synonyms_for, [name], [], do: synonyms
    end
  end)

  def exists?(_),         do: false
  def equal?(_, _),       do: false
  def link_to(_),         do: nil
  def link?(_),           do: false
  def synonyms_for(_, _), do: nil
end
