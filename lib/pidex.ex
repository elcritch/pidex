defmodule Pidex.State do
  defstruct error: 0.0, integral: 0.0, bias: 0.0, ts: 0
end

defmodule Pidex do
  @moduledoc """
  Documentation for Pidex.
  """
  defstruct set_point: 0.0, min_point: nil, max_point: nil, kP: 0.0, kI: 0.0, kD: 0.0

  def update({%Pidex{} = pid, %Pidex.State{} = state, process_value, ts}) do
   update(pid, state, process_value, ts)
  end

  def update(%Pidex{kP: kP, kI: kI, kD: kD, set_point: target} = pid, %Pidex.State{} = state, process_value, ts) do

    dT = ts - state.ts
    p_error! = target - process_value
    p_integral! = state.integral + (p_error! * dT)
    p_derivative! = (p_error! - state.error) / dT

    output = kP*p_error! + kI*p_integral! + kD*p_derivative! + state.bias

    %{min_point: min_point, max_point: max_point} = pid
    output =
      case output do
        updated_value when is_number(min_point) and updated_value < min_point ->
          pid.min_point
        updated_value when is_number(max_point) and updated_value > max_point ->
          max_point
        updated_value ->
          updated_value
      end

    {output, %Pidex.State{error: p_error!, integral: p_integral!}}
  end
end
