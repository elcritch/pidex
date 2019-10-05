defmodule PidexTest do
  use ExUnit.Case
  doctest Pidex

  test "greets the world" do
    assert Pidex.hello() == :world
  end
end
