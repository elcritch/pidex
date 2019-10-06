defmodule PidexTest do
  use ExUnit.Case
  doctest Pidex

  @example_targets [
    [1,0,0.0,0.0 ],
    [2,0,0.0,0.0 ],
    [3,0,0.0,0.0 ],
    [4,0,0.0,0.0 ],
    [5,0,0.0,0.0 ],
    [6,0,0.0,0.0 ],
    [7,0,0.0,0.0 ],
    [8,0,0.0,0.0 ],
    [9,0,0.0,0.0 ],
    [10,0,0.0,1 ],
    [11,1.1790909090909092,1.27,1 ],
    [12,0.8383121212121212,-0.2574454545454547,1 ],
    [13,0.9921053776223776,0.23071633333333336,1 ],
    [14,0.942270522067932,0.0215937158741259,1 ],
    [15,0.9683353930976024,0.092731537696337,1 ],
    [16,0.9641273913671772,0.05829199826957473,1 ],
    [17,0.9708765581121587,0.06557269615674624,1 ],
    [18,0.9728293090333581,0.05750830647675494,1 ],
    [19,0.9761459700678272,0.05594823998183761,1 ],
    [20,0.9785231019012818,0.052377131833454604,1 ],
    [21,0.9809051423375684,0.05000108805533422,1 ],
    [22,0.9829748881379202,0.04752429125489727,1 ],
    [23,0.9848933405318685,0.04539671326351345,1 ],
    [24,0.9866309421156602,0.04340426825045833,1 ],
    [25,0.9882265121637631,0.041595570048102964,1 ],
    [26,0.9896884310261133,0.03992345732388859,1 ],
    [27,0.99103346261691,0.03838206862783379,1 ],
    [28,0.9922723827327414,0.03695320583011711,1 ],
    [29,0.9934159837222647,0.0356263596102129,1 ],
    [30,0.9944731350935865,0.0343904847046551,1 ],
    [31,0.9954518334155648,0.033236762838107295,1 ],
    [32,0.996359044251454,0.032157210835889245,1 ],
    [33,0.9972009652705212,0.031144951322097457,1 ],
    [34,0.9979830918492865,0.03019389128464762,1 ],
    [35,0.9987103305530165,0.029298667275158608,1 ],
    [36,0.9993870713886127,0.028454518613373996,1 ],
    [37,1.0000172574378787,0.02765721307629298,1 ],
    [38,1.0006044403719272,0.0269029724077327,1 ],
    [39,1.0011518289660983,0.02618841423519687,1 ],
    [40,1.0016623300259617,0.025510501059863404,1 ],
    [41,1.002138583687746,0.02486649756422349,1 ],
    [42,1.0025829937444535,0.024253933866231255,1 ],
    [43,1.0029977538945123,0.023670574103547195,1 ],
    [44,1.0033848705081583,0.0231143893409188,1 ],
    [45,1.0037461824571372,0.02258353417120109,1 ],
    [46,1.0040833784388716,0.022076326416516988,1 ],
    [47,1.0043980121622111,0.021591229468020466,1 ],
    [48,1.0046915156985663,0.02112683686968858,1 ],
    [49,1.0049652112547005,0.020681858821440285,1 ],
    [50,1.0052203215826967,0.020255110327996265,1 ],
  ]

  test "basic pid" do
    pid = %Pidex{set_point: 10.0, kP: 3.0, kI: 2.0, kD: 1.0 }
    state = %Pidex.State{}

    {out1, state} = {pid, state, 5.0, 1} |> Pidex.update()

    # IO.puts "pid out: #{inspect out1} <#{inspect state}>"
    assert_in_delta out1, 30.0, 1.0e-6
    assert_in_delta state.bias, 0.0, 1.0e-6
    assert_in_delta state.error, 5.0, 1.0e-6
    assert_in_delta state.integral, 5.0, 1.0e-6
    assert_in_delta state.ts, 1.0, 1.0e-6

    #assert_ out1 == 30.0
    # out: 30.0 <%Pidex.State{bias: 0.0, error: 5.0, integral: 5.0, ts: 1}>
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

          # IO.puts "pid out: #{inspect output} <#{inspect state}>"

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

      results! = results |> Enum.map(& &1 |> Keyword.values())
      check_results(results!, @example_targets)
      # IO.puts "\n\ntime, feedback, output, set_point"
      # results |> Enum.each(& IO.puts "#{&1|>Keyword.values()|>Enum.join(",")}" )
  end

  test "test pid server" do
    alias Pidex.PdxServer

    settings = %Pidex{kP: 1.2, kI: 1.0, kD: 0.001,
                      min_point: -20.0, max_point: 20.0, ts_factor: 1_000.0}
    {:ok, pid} = PdxServer.start_link(settings: settings, ts_unit: :millisecond)

    # IO.puts "Started PdxServer "
    Process.put(:feedback, 0.0)

    pid |> PdxServer.set_time(nil, :millisecond)
    results =
      for i <- 1..50, into: [] do
          Process.sleep(20)
          feedback = Process.get(:feedback)
          # output = pid |> PdxServer.update(feedback, sample_time*i)
          output = pid |> PdxServer.update(feedback)

          feedback =
            if i > 10 do
              feedback + (output - 1.0/i)
            else
              feedback
            end

          if i > 9 do
            pid |> PdxServer.set(set_point: 1.0)
          end

          Process.put(:feedback, feedback)

          # ts = PdxServer.state(pid).ts
          [ time: i,
            feedback: feedback,
            output: output,
            set_point: PdxServer.settings(pid).set_point ]
      end

      results! = results |> Enum.map(& &1 |> Keyword.values())
      check_results(results!, @example_targets, 0.01)
      # IO.puts "\n\ntime, feedback, output, set_point"
      # results |> Enum.each(& IO.puts "#{&1|>Keyword.values()|>Enum.join(",")}" )
  end

  defp check_results(results, example_targets, delta \\ 1.0e-6) do
      for {xi, yi} <- Enum.zip(results, example_targets) do
        # _diffs = Enum.zip(xi, yi) |> Enum.map(fn {x,y} -> 1.0*(x-y) end)
        # IO.puts "xi, yi: #{inspect diffs}"
        for {x,y} <- Enum.zip(xi, yi) do
          assert_in_delta(x,y,delta)
        end
      end
  end

  test "test other example" do
    # test_print()
  end

  def test_print() do
    # compare sample and constants to https://github.com/ivmech/ivPID/blob/master/test_pid.py
    sample_time = 0.02
    pid = %Pidex{kP: 0.8, kI: 0.1, kD: 0.0001, min_point: -20.0, max_point: 20.0}
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

          # IO.puts "pid out: #{inspect output} <#{inspect state}>"

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
      results |> Enum.each(& IO.puts "#{&1|>Keyword.values()|>Enum.join(",")}" )
  end

end
