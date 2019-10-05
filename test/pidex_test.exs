defmodule PidexTest do
  use ExUnit.Case
  doctest Pidex

  test "basic pid" do
    pid = %Pidex{set_point: 10.0, kP: 3.0, kI: 2.0, kD: 1.0 }
    state = %Pidex.State{}

    {out1, state!} = {pid, state, 5.0, 1} |> Pidex.update()

    IO.puts "pid out: #{inspect out1} <#{inspect state!}>"
  end
end
