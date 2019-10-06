defmodule Pidex.PdxServer do
  require Logger
  use GenServer

  def set_time(pid, ts) when is_number(ts) do
    GenServer.call(pid, {:put, :ts, ts, nil})
  end

  def set_time(pid, ts, ts_unit) when not is_nil(ts_unit) do
    ts = if ts == nil, do: System.monotonic_time(ts_unit), else: ts
    GenServer.call(pid, {:put, :ts, ts, ts_unit})
  end

  def set(pid, opts) do
    pidex = GenServer.call(pid, {:get, :pidex})
    pidex = struct!(pidex, opts)
    GenServer.cast(pid, {:put, :pidex, pidex})
  end

  def settings(pid) do
    GenServer.call(pid, {:get, :pidex})
  end

  def state(pid) do
    GenServer.call(pid, {:get, :state})
  end

  def reset(pid, state \\ %Pidex.State{}) do
    GenServer.cast(pid, {:put, :state, state})
  end

  def output(pid) do
    GenServer.call(pid, {:get, :output})
  end

  def update_async(pid, process_value, ts \\ nil) when is_number(process_value) do
    GenServer.cast(pid, {:process_update, process_value, ts})
  end

  def update(pid, process_value, ts \\ nil) when is_number(process_value) do
    GenServer.call(pid, {:process_update, process_value, ts})
  end

  def start_link(args \\ [], opts \\ []) do
    IO.puts("pidex server args: #{inspect args}")
    IO.puts("pidex server opts: #{inspect opts}")
    GenServer.start_link(__MODULE__, args, opts ++ [name: __MODULE__])
  end

  def init(args) do
    IO.puts("pidex server args: #{inspect args}")
    {:ok, %{
      pidex: args[:pidex] || args[:settings] || %Pidex{},
      state: args[:state] || %Pidex.State{},
      ts_unit: args[:ts_unit] || :seconds,
      output: nil,
    }}
  end

  def handle_call({:get, key}, _from, proc_state) do
    {:reply, Map.get(proc_state, key), proc_state }
  end

  def handle_call({:process_update, process_value, ts}, _from, proc_state) do
    proc_state = process_update(proc_state, process_value, ts)
    {:reply, proc_state[:output], proc_state}
  end

  def handle_cast({:put, key, value}, proc_state) do
    {:noreply, Map.put(proc_state, key, value)}
  end

  def handle_cast({:process_update, process_value, ts}, proc_state) do
    {:noreply, process_update(proc_state, process_value, ts)}
  end

  def process_update(proc, process_value, _ts = nil) do
    ts = System.monotonic_time(proc.ts_unit)
    process_update(proc, process_value, ts)
  end

  def process_update(proc, process_value, ts) do
    {output, state} =
      {proc.pidex, proc.state, process_value, ts}
      |> Pidex.update()

    IO.puts "pid out: #{inspect output} <#{inspect state}>"
    %{ proc | state: state, output: output}
  end
end
