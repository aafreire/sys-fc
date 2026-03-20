defmodule SysFcWeb.TrainingPlanJSON do
  def index(%{plans: plans, locations: locations}) do
    %{
      data: %{
        plans: Enum.map(plans, &plan_data/1),
        locations: Enum.map(locations, &location_data/1)
      }
    }
  end

  def show_plan(%{plan: plan}) do
    %{data: plan_data(plan)}
  end

  def show_location(%{location: location}) do
    %{data: location_data(location)}
  end

  defp plan_data(plan) do
    %{
      id: plan.id,
      name: plan.name,
      label: plan.label,
      description: plan.description,
      frequency: plan.frequency,
      days: plan.days,
      price: plan.price,
      is_active: plan.is_active,
      sort_order: plan.sort_order
    }
  end

  defp location_data(location) do
    %{
      id: location.id,
      name: location.name,
      label: location.label,
      is_active: location.is_active,
      sort_order: location.sort_order
    }
  end
end
