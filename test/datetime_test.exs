Code.require_file "test_helper.exs", __DIR__

defmodule DateTimeTest do
  use ExUnit.Case
  use Continuum
  use DateTime

  test "is_datetime works" do
    assert is_datetime({ { 1, 2, 3 }, { 1, 2, 3 } })
    refute is_datetime({ { 1, 2, 3 }, { 1, 2, 70 } })

    assert is_datetime({ { { 1, 2, 3 }, { 1, 2, 3 } }, "EST" })
    refute is_datetime({ { { 1, 2, 3 }, { 1, 2, 3 } }, "HUE" })
  end

  test "returns a proper datetime" do
    assert match?({ { _, _, _ }, { _, _, _ } }, DateTime.now)
    assert match?({ { { _, _, _ }, { _, _, _ } }, "EST" }, DateTime.now("EST"))
  end

  test "gets the proper timezone" do
    assert DateTime.timezone(DateTime.now) == "UTC"
    assert DateTime.timezone(DateTime.now("EST")) == "EST"
  end

  test "gets the proper date" do
    assert DateTime.new({ 0, 1, 2 }, { 1, 2, 3 }) |> DateTime.date == { 0, 1, 2 }
    assert DateTime.new({ 0, 1, 2 }) |> DateTime.date == { 0, 1, 2 }
    assert DateTime.new({ { 0, 1, 2 }, "EST" }) |> DateTime.date == { { 0, 1, 2 }, "EST" }
  end

  test "gets the proper time" do
    assert DateTime.new({ 0, 1, 2 }, { 1, 2, 3 }) |> DateTime.time == { 1, 2, 3 }
    assert DateTime.new({ 0, 1, 2 }) |> DateTime.time == { 0, 0, 0 }
    assert DateTime.new({ { 0, 1, 2 }, "EST" }, { { 1, 2, 3 }, "EST" }) |> DateTime.time == { { 1, 2, 3 }, "EST" }
  end

  test "the sigil works" do
    assert ~t"2013-10-23" == { 2013, 10, 23 }
    assert ~t"2013-10-23 EST" == { { 2013, 10, 23 }, "EST" }

    assert ~t"10:30:15" == { 10, 30, 15 }
    assert ~t"10:30:15 EST" == { { 10, 30, 15 }, "EST" }

    assert ~t"2013-10-23 10:30:15" == { { 2013, 10, 23 }, { 10, 30, 15 } }
    assert ~t"2013-10-23 10:30:15 EST" == { { { 2013, 10, 23 }, { 10, 30, 15 } }, "EST" }

    assert ~t"2013-10-23 10:30:15"d == { 2013, 10, 23 }
    assert ~t"2013-10-23 10:30:15"t == { 10, 30, 15 }
    assert ~t"2013-10-23 10:30:15"dt == { { 2013, 10, 23 }, { 10, 30, 15 } }

    assert ~t"2013-10-23 10:30:15 EST"d == { { 2013, 10, 23 }, "EST" }
    assert ~t"2013-10-23 10:30:15 EST"t == { { 10, 30, 15 }, "EST" }
    assert ~t"2013-10-23 10:30:15 EST"dt == { { { 2013, 10, 23 }, { 10, 30, 15 } }, "EST" }
  end

  test "epoch works" do
    assert DateTime.to_epoch(DateTime.epoch) == 0
    assert DateTime.to_epoch(DateTime.epoch |> DateTime.+ seconds: 3) == 3
  end
end
