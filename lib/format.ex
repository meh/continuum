defexception DateTime.ParseError, message: nil

defmodule DateTime.Format do
  @type t :: :php | :icu

  def compile(string, type \\ :php) do
    if string |> is_binary do
      string = String.to_char_list!(string)
    end

    { :ok, lexed, _ } = case type do
      :php ->
        :dt_format_php.string(string)

      :icu ->
        :dt_format_icu.string(string)
    end

    { :ok, parsed } = :dt_format.parse(lexed)

    parsed
  end

  def format(datetime, format) when format |> is_list do
    format([], datetime, format)
  end

  def format(datetime, { :day, :number, :padded }) do
    datetime |> DateTime.date |> Date.day |> pad
  end

  def format(datetime, { :weekday, :name, :short }) do
    case datetime |> DateTime.date |> Date.day_of_the_week do
      1 -> "Mon"
      2 -> "Tue"
      3 -> "Wed"
      4 -> "Thu"
      5 -> "Fri"
      6 -> "Sat"
      7 -> "Sun"
    end
  end

  def format(datetime, { :day, :number }) do
    datetime |> DateTime.date |> Date.day |> integer_to_binary
  end

  def format(datetime, { :weekday, :name, :long }) do
    case datetime |> DateTime.date |> Date.day_of_the_week do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
    end
  end

  def format(datetime, { :weekday, :number, :iso8601 }) do
    datetime |> DateTime.date |> Date.day_of_the_week |> integer_to_binary
  end

  def format(datetime, :suffix) do
    case datetime |> DateTime.date |> Date.day |> rem(10) do
      1 -> "st"
      2 -> "nd"
      3 -> "rd"
      _ -> "th"
    end
  end

  def format(datetime, { :weekday, :number }) do
    case datetime |> DateTime.date |> Date.day_of_the_week do
      7 -> "0"
      n -> integer_to_binary(n)
    end
  end

  def format(datetime, :yearday) do
    datetime |> DateTime.date |> Date.day_of_the_year |> integer_to_binary
  end

  def format(datetime, { :week, :number, :iso8601 }) do
    datetime |> DateTime.date |> Date.week_number |> integer_to_binary
  end

  def format(datetime, { :month, :name, :long }) do
    case datetime |> DateTime.date |> Date.month do
      1  -> "January"
      2  -> "February"
      3  -> "March"
      4  -> "April"
      5  -> "May"
      6  -> "June"
      7  -> "July"
      8  -> "August"
      9  -> "September"
      10 -> "October"
      11 -> "November"
      12 -> "December"
    end
  end

  def format(datetime, { :month, :number, :padded }) do
    datetime |> DateTime.date |> Date.month |> pad
  end

  def format(datetime, { :month, :name, :short }) do
    case datetime |> DateTime.date |> Date.month do
      1  -> "Jan"
      2  -> "Feb"
      3  -> "Mar"
      4  -> "Apr"
      5  -> "May"
      6  -> "Jun"
      7  -> "Jul"
      8  -> "Aug"
      9  -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  def format(datetime, { :month, :number }) do
    datetime |> DateTime.date |> Date.month |> integer_to_binary
  end

  def format(datetime, { :month, :days }) do
    datetime |> DateTime.date |> Date.month_days |> integer_to_binary
  end

  def format(datetime, { :year, :leap }) do
    case datetime |> DateTime.date |> Date.leap? do
      true  -> "1"
      false -> "0"
    end
  end

  def format(datetime, { :year, :number, :iso8601 }) do
    datetime |> DateTime.date |> Date.year |> integer_to_binary
  end

  def format(datetime, { :year, :number, :long }) do
    datetime |> DateTime.date |> Date.year |> integer_to_binary
  end

  def format(datetime, { :year, :number, :short }) do
    datetime |> DateTime.date |> Date.year |> rem(100) |> integer_to_binary
  end

  def format(datetime, { :noon, :lowercase }) do
    case datetime |> DateTime.time |> Time.hour do
      hour when hour > 12  -> "pm"
      hour when hour <= 12 -> "am"
    end
  end

  def format(datetime, { :noon, :uppercase }) do
    case datetime |> DateTime.time |> Time.hour do
      hour when hour > 12  -> "PM"
      hour when hour <= 12 -> "AM"
    end
  end

  def format(datetime, { :hour, 12 }) do
    datetime |> DateTime.time |> Time.hour |> rem(12) |> integer_to_binary
  end

  def format(datetime, { :hour, 24 }) do
    datetime |> DateTime.time |> Time.hour |> integer_to_binary
  end

  def format(datetime, { :hour, 12, :padded }) do
    datetime |> DateTime.time |> Time.hour |> rem(12) |> pad
  end

  def format(datetime, { :hour, 24, :padded }) do
    datetime |> DateTime.time |> Time.hour |> pad
  end

  def format(datetime, { :minute, :padded }) do
    datetime |> DateTime.time |> Time.minute |> pad
  end

  def format(datetime, { :second, :padded }) do
    datetime |> DateTime.time |> Time.second |> pad
  end

  def format(datetime, { :timezone, :long }) do
    datetime |> DateTime.timezone
  end

  def format(datetime, :daylight) do
    case datetime |> DateTime.dst? do
      true  -> "1"
      false -> "0"
    end
  end

  def format(datetime, { :offset, :short }) do
    case Timezone.offset("UTC", datetime) do
      { sign, { hours, minutes, _ } } ->
        atom_to_binary(sign) <> (hours |> pad) <> (minutes |> pad)
    end
  end

  def format(datetime, { :offset, :long }) do
    case Timezone.offset("UTC", datetime) do
      { sign, { hours, minutes, _ } } ->
        atom_to_binary(sign) <> (hours |> pad) <> ":" <>  (minutes |> pad)
    end
  end

  def format(datetime, { :timezone, :short }) do
    datetime |> DateTime.timezone
  end

  def format(datetime, { :offset, :seconds }) do
    case Timezone.offset("UTC", datetime) do
      { sign, time } ->
        atom_to_binary(sign) <> (Time.to_seconds(time) |> integer_to_binary)
    end
  end

  def format(datetime, { :datetime, :iso8601 }) do
    datetime |> format(compile("o-m-d\TH:i:sP"))
  end

  def format(datetime, { :datetime, :rfc2882 }) do
    datetime |> format(compile("D, j M Y H:i:s O"))
  end

  def format(datetime, :epoch) do
    datetime |> DateTime.to_epoch |> integer_to_binary
  end

  def format(_, char) when is_integer(char) do
    [char] |> iolist_to_binary
  end

  defp format(acc, datetime, [format | rest]) do
    [format(datetime, format) | acc] |> format(datetime, rest)
  end

  defp format(acc, _, []) do
    Enum.reverse(acc) |> iolist_to_binary
  end

  defp pad(number) when number < 10 do
    "0" <> integer_to_binary(number)
  end

  defp pad(number) do
    integer_to_binary(number)
  end

  def parse(string, format) when format |> is_list do
    try do
      result = Enum.reduce format, { { { 1, 1, 0 }, { 0, 0, 0 } }, string }, fn
        format, { current, rest } ->
          case parse(rest, format) do
            { parsed, rest } ->
              { into(current, parsed, format), rest }
          end
      end

      { :ok, result }
    catch
      { :error, reason } ->
        { :error, reason }
    end
  end

  def parse(string, { :day, :number, :padded }) do
    part = String.slice(string, 0 .. 1)
    rest = String.slice(string, 2 .. -1) || ""

    case Integer.parse(part) do
      { integer, "" } when integer <= 31 ->
        { integer, rest }

      _ ->
        throw { :error, "#{part} is not a padded day number" }
    end
  end

  def parse(string, { :weekday, :name, :short }) do
    part = String.slice(string, 0 .. 2)
    rest = String.slice(string, 3 .. -1) || ""

    case String.upcase(part) do
      "MON" -> { 1, rest }
      "TUE" -> { 2, rest }
      "WED" -> { 3, rest }
      "THU" -> { 4, rest }
      "FRI" -> { 5, rest }
      "SAT" -> { 6, rest }
      "SUN" -> { 7, rest }

      _ ->
        throw { :error, "#{part} is not a weekday name" }
    end
  end

  def parse(string, { :day, :number }) do
    case string do
      << a :: utf8, b :: utf8, rest :: binary >> when b in ?0 .. ?9 ->
        case Integer.parse(<< a :: utf8, b :: utf8 >>) do
          { integer, "" } when integer <= 31 ->
            { integer, rest }

          _ ->
            throw { :error, "#{<< a :: utf8, b :: utf8 >>} is not a valid day number" }
        end

      << a :: utf8, rest :: binary >> ->
        case Integer.parse(<< a :: utf8 >>) do
          { integer, "" } ->
            { integer, rest }

          _ ->
            throw { :error, "#{<< a :: utf8 >>} is not a valid day number" }
        end
    end
  end

  @spec into(DateTime.t, term, term) :: DateTime.t
  def into(result, part, format) when elem(format, 0) == :day do
    result |> DateTime.date(DateTime.date(result) |> Date.day(part))
  end

  def into(result, _, { :weekday, _, _ }), do: result
  def into(result, _, :suffix), do: result
  def into(result, part, :yearday), do: result
end
