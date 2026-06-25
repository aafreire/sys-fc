defmodule SysFcWeb.UnitJSON do
  def index(%{units: units}), do: %{data: Enum.map(units, &unit_data/1)}

  def show(%{unit: unit}), do: %{data: unit_data(unit)}

  defp unit_data(unit) do
    %{
      id: unit.id,
      name: unit.name,
      is_active: unit.is_active,
      sort_order: unit.sort_order,
      courts: courts(unit)
    }
  end

  defp courts(unit) do
    case unit.courts do
      courts when is_list(courts) -> Enum.map(courts, &court_data/1)
      _ -> []
    end
  end

  defp court_data(court) do
    %{
      id: court.id,
      unit_id: court.unit_id,
      name: court.name,
      sort_order: court.sort_order
    }
  end
end
