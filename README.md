# Pidex

Pure Elixir library for PID controllers (proportional–integral–derivative controller). Usable as both a pure function or GenServer setup.

## Usage

Function based usage: 
```
    # Configure Pidex struct
    # P, I, D values are kP, kI, kD respectively. 
    pid = %Pidex{kP: 1.2, kI: 1.0, kD: 0.001, max_point: 20.0}

    # A state struct is created for each update of the PID controller. 
    state = %Pidex.State{ts: 0.00}
    {output, state} = {pid, state, 5.0, 1} |> Pidex.update()

    # Setup in loop or an `Stream.transform`
    # ...
```

GenServer based usage: 
```
    # Configure server
    settings = %Pidex.Pidex{kP: 1.2, kI: 1.0, kD: 0.001,
                      min_point: -20.0, max_point: 20.0, ts_factor: 1_000.0}
    {:ok, pid} = Pidex.PdxServer.start_link(settings: settings,
                                            ts_unit: :millisecond)

    # Set ts & ts units, when ts is nil it will be properly set with monotonic_time. 
    pid |> PdxServer.set_time(nil, :millisecond)

```



## Installation

```elixir
def deps do
  [
    {:pidex, "~> 0.1.0"}
  ]
end
```
