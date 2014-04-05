Code.require_file "test_helper.exs", __DIR__

defmodule DateTest do
  use ExUnit.Case
  use Continuum
  use DateTime

  test "returns a proper date" do
    assert match?({ _, _, _ }, Date.now)
    assert match?({ { _, _, _ }, "EST" }, Date.now("EST"))
  end

  test "gets the proper year" do
    assert ~t"2013-10-23" |> Date.year == 2013
    assert ~t"2013-10-23 EST" |> Date.year == 2013
  end

  test "gets the proper month" do
    assert ~t"2013-10-23" |> Date.month == 10
    assert ~t"2013-10-23 EST" |> Date.month == 10
  end

  test "gets the proper day" do
    assert ~t"2013-10-23" |> Date.day == 23
    assert ~t"2013-10-23 EST" |> Date.day == 23
  end

  test "gets the proper timezone" do
    assert ~t"2013-10-23" |> Date.timezone == "UTC"
    assert ~t"2013-10-23 EST" |> Date.timezone == "EST"
  end
end
