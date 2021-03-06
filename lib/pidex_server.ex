defmodule Pidex.PdxServer do
  require Logger
  use GenServer

  @type proc_state :: %{output: number, pidex: Pidex.t(), state: Pidex.State.t()}

  def set_time_units(pid, ts_unit) when is_atom(ts_unit) do
    GenServer.cast(pid, {:put_ts, nil, ts_unit})
  end

  @spec set_time(GenServer.server(), number) :: :ok
  def set_time(pid, ts) when is_number(ts) do
    GenServer.cast(pid, {:put_ts, ts, nil})
  end

  def set_time(pid) do
    GenServer.cast(pid, {:put_ts, nil, nil})
  end

  @spec set( GenServer.server(), Enum.t() ) :: :ok
  def set(pid, opts) do
    pidex = GenServer.call(pid, {:get, :pidex})
    pidex = struct!(pidex, opts)
    GenServer.cast(pid, {:put, :pidex, pidex})
  end

  @spec settings( GenServer.server() ) :: :ok
  def settings(pid) do
    GenServer.call(pid, {:get, :pidex})
  end

  @spec state( GenServer.server() ) :: any
  def state(pid) do
    GenServer.call(pid, {:get, :state})
  end

  @spec reset(GenServer.server(), any) :: :ok
  def reset(pid, state \\ %Pidex.State{}) do
    GenServer.cast(pid, {:put, :state, state})
    pid |> set_time()
  end

  @spec output(GenServer.server()) :: number
  def output(pid) do
    GenServer.call(pid, {:get, :output})
  end

  @spec update_async(GenServer.server(), number, Pidex.timestamp() | nil ) :: :ok
  def update_async(pid, process_value, ts \\ nil) when is_number(process_value) do
    GenServer.cast(pid, {:process_update, process_value, ts})
  end

  @spec update(GenServer.server(), number, Pidex.timestamp() | nil) :: any
  def update(pid, process_value, ts \\ nil) when is_number(process_value) do
    GenServer.call(pid, {:process_update, process_value, ts})
  end

  def start_link(args \\ [], opts \\ []) do
    # IO.puts("pidex server args: #{inspect args}")
    # IO.puts("pidex server opts: #{inspect opts}")
    GenServer.start_link(__MODULE__, args, opts ++ [name: __MODULE__])
  end

  def init(args) do
    # IO.puts("pidex server args: #{inspect args}")
    # GenServer(self(), :update_time)
    ts_unit = args[:ts_unit] || :second
    set_time(self())

    {:ok,
     %{pidex: args[:pidex] || args[:settings] || %Pidex{},
       state: args[:state] || %Pidex.State{},
       ts_unit: ts_unit,
       ts_factor: args[:ts_factor] || 1.0,
       output: nil}}
  end

  def handle_call({:get, key}, _from, proc_state) do
    {:reply, Map.get(proc_state, key), proc_state }
  end

  def handle_call({:process_update, process_value, ts}, _from, proc_state) do
    # IO.puts "process_update: #{System.monotonic_time(:second)} "
    proc_state = process_update(proc_state, process_value, ts)
    {:reply, proc_state[:output], proc_state}
  end

  def handle_cast({:put, key, value}, proc_state) do
    {:noreply, Map.put(proc_state, key, value)}
  end

  def handle_cast({:put_ts, ts, ts_unit}, proc_state) do
    # IO.puts "update_time: #{ts}"
    ts = ts || System.monotonic_time(proc_state.ts_unit || ts_unit)
    state = %{ proc_state.state | ts: ts }
    proc_state =
      proc_state
      |> Map.put(:ts_unit, ts_unit || proc_state.ts_unit)
      |> Map.put(:state, state)

    {:noreply, proc_state}
  end

  def handle_cast({:process_update, process_value, ts}, proc_state) do
    proc_state = process_update(proc_state, process_value, ts)
    {:noreply, proc_state}
  end

  def process_update(proc, process_value, ts) when is_nil(ts) do
    ts = System.monotonic_time(proc.ts_unit)
    # IO.puts "process_update ts set: #{ts}"
    process_update(proc, process_value, ts)
  end

  def process_update(proc, process_value, ts) do
    # IO.puts "process_update ts!: #{ts}"
    {output, state} =
      {proc.pidex, proc.state, process_value, ts}
      |> Pidex.update()

    # IO.puts "pid out: #{inspect output} <#{inspect state}>"
    %{ proc | state: state, output: output}
  end
end

