Code.require_file "test_helper.exs", __DIR__

defmodule TimeTest do
  use ExUnit.Case
  use DateTime

  test "returns a proper time" do
    assert match?({ _, _, _ }, Time.now)
    assert match?({ { _, _, _ }, "EST" }, Time.now("EST"))
  end

  test "gets the proper hour" do
    assert ~t"10:30:15" |> Time.hour == 10
    assert ~t"10:30:15 EST" |> Time.hour == 10
  end

  test "gets the proper minute" do
    assert ~t"10:30:15" |> Time.minute == 30
    assert ~t"10:30:15 EST" |> Time.minute == 30
  end

  test "gets the proper second" do
    assert ~t"10:30:15" |> Time.second == 15
    assert ~t"10:30:15 EST" |> Time.second == 15
  end
end
