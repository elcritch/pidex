defmodule Pidex.State do
  defstruct error: 0.0, integral: 0.0,  ts: 0
end

defmodule Pidex do
  @moduledoc """
  Documentation for Pidex.
  """
  require Logger

  defstruct set_point: 0.0, min_point: nil, max_point: nil, kP: 0.0, kI: 0.0, kD: 0.0, ts_factor: 1.0, bias: 0.0, error_power: 1.0

  @type timestamp() :: integer | float

  @doc """
  Main PID(ex) controller update function. Each call to this will produce a new PID(ex)
  state struct which needs to be passed to the next call to `update`.
    pid = %Pidex{kP: 1.2, kI: 1.0, kD: 0.001, max_point: 20.0}
    initial_state = %Pidex.State{ts: 0.00}
    {output, initial_state} =
      {pid, state, 5.0, 1}
      |> Pidex.update()
  """
  @spec update({Pidex.t(), Pidex.State.t(), number, Pidex.timestamp()}) :: {number, Pidex.State.t()}
  def update({%Pidex{} = pid, %Pidex.State{} = state, process_value, ts}) do
   update(pid, state, process_value, ts)
  end

  @spec update(Pidex.t(), Pidex.State.t(), number, Pidex.timestamp()) :: {number, Pidex.State.t()}
  def update(%Pidex{kP: kP, kI: kI, kD: kD, set_point: target} = pid,
             %Pidex.State{} = state, process_value, ts) do

    dT = (ts - state.ts)/pid.ts_factor

    # IO.puts "update: dT: #{inspect dT}, ts: #{ts}, state.ts: #{state.ts}"
    unless dT > 0, do: raise %ArgumentError{message: "argument error, PID timestep must be non-zero"}

    p_error! = :math.pow(target - process_value, state.error_power)
    p_integral! = state.integral + (p_error! * dT)
    p_derivative! = (p_error! - state.error) / dT

    output = kP*p_error! + kI*p_integral! + kD*p_derivative! + pid.bias

    Logger.warn("pdx: state: #{inspect state}")
    Logger.warn("pdx: process: #{inspect [process_value: process_value, set_point: target]}")
    Logger.warn("pdx: integral: #{inspect [integral: state.integral, p_error_dt: (p_error! * dT)]}")
    Logger.warn("pdx: calc: #{inspect [ts: ts, ts!: state.ts, del_ts:  ts - state.ts, dT: dT, p_error: p_error!, p_integral: p_integral!, p_derivative: p_derivative!]}")
    Logger.warn("pdx: form: #{inspect [error: kP*p_error!, integral: kI*p_integral!, derivative: kD*p_derivative!]}")

    # Implement anti-windup & overmax protection
    # cf https://apmonitor.com/pdc/index.php/Main/ProportionalIntegralDerivative
    %{min_point: min_point, max_point: max_point} = pid
    {output, p_integral!} =
      case output do
        updated_value when is_number(min_point) and updated_value < min_point ->
          {min_point, p_integral! - p_error! * dT}
        updated_value when is_number(max_point) and updated_value > max_point ->
          {max_point, p_integral! - p_error! * dT}
        updated_value ->
          {updated_value, p_integral!}
      end

    Logger.warn("pdx: state!: #{inspect %Pidex.State{error: p_error!, integral: p_integral!, ts: ts}}")
    {output, %Pidex.State{error: p_error!, integral: p_integral!, ts: ts}}
  end
end


# TroFirmware.PdxRefOrig |> Pidex.PdxServer.set(kP: 3.4e-0)
