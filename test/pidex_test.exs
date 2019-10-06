defmodule PidexTest do
  use ExUnit.Case
  doctest Pidex

  test "basic pid" do
    pid = %Pidex{set_point: 10.0, kP: 3.0, kI: 2.0, kD: 1.0 }
    state = %Pidex.State{}

    {out1, state!} = {pid, state, 5.0, 1} |> Pidex.update()

    IO.puts "pid out: #{inspect out1} <#{inspect state!}>"
  end

  test "error pid" do
    pid = %Pidex{set_point: 10.0, kP: 3.0, kI: 2.0, kD: 1.0 }
    state = %Pidex.State{}

    assert_raise ArgumentError, fn ->
      {pid, state, 5.0, 0} |> Pidex.update()
    end

  end


  test "test pid" do
    # compare sample and constants to https://github.com/ivmech/ivPID/blob/master/test_pid.py
    sample_time = 0.02
    pid = %Pidex{kP: 1.2, kI: 1.0, kD: 0.001, min_point: -20.0, max_point: 20.0}
    state = %Pidex.State{ts: 0.00}

    Process.put(:feedback, 0)
    Process.put(:pid, pid)
    Process.put(:state, state)

    results =
      for i <- 1..50, into: [] do
          pid = Process.get(:pid)
          state = Process.get(:state)
          feedback = Process.get(:feedback)

          {output, state} =
            {pid, state, feedback, sample_time*i}
            |> Pidex.update()

          IO.puts "pid out: #{inspect output} <#{inspect state}>"

          feedback =
            if pid.set_point > 0.0 do
              feedback + (output - 1.0/i)
            else
              feedback
            end

          pid = if i > 9, do: %{ pid | set_point: 1}, else: pid

          Process.put(:pid, pid)
          Process.put(:feedback, feedback)
          Process.put(:state, state)

          [ time: i,
            feedback: feedback,
            output: output,
            set_point: pid.set_point ]
      end

      IO.puts "\n\ntime, feedback, output, set_point"
      results
      |> Enum.each(& IO.puts "#{&1|>Keyword.values()|>Enum.join(",")}" )
  end

end
