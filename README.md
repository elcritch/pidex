**Warning**: This library is likely incorrect. I was trying some random stuff with some broken hardware. Though the core abstraction is there but it's not properly tested. 

# Pidex

Pure Elixir library for PID controllers (proportional–integral–derivative controller). Usable as both a pure function or GenServer setup.

## Usage

Function based usage: 
```
    pid = %Pidex{kP: 1.2, kI: 1.0, kD: 0.001, max_point: 20.0}
    state = %Pidex.State{ts: 0.00}
    {output, state} = {pid, state, 5.0, 1} |> Pidex.update()

```

GenServer based usage: 
```
    settings = %Pidex.Pidex{kP: 1.2, kI: 1.0, kD: 0.001,
                      min_point: -20.0, max_point: 20.0, ts_factor: 1_000.0}
    {:ok, pid} = Pidex.PdxServer.start_link(settings: settings,
                                            ts_unit: :millisecond)

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
