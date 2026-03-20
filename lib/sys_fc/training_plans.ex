defmodule SysFc.TrainingPlans do
  @moduledoc "Contexto para planos de treino e locais de treino."

  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.TrainingPlans.{TrainingPlan, TrainingLocation}

  # ── Planos de Treino ──────────────────────────────────────────────────────────

  def list_training_plans(opts \\ []) do
    only_active = Keyword.get(opts, :only_active, false)

    TrainingPlan
    |> then(fn q -> if only_active, do: where(q, [p], p.is_active == true), else: q end)
    |> order_by([p], [asc: p.sort_order, asc: p.inserted_at])
    |> Repo.all()
  end

  def get_training_plan!(id), do: Repo.get!(TrainingPlan, id)

  def create_training_plan(attrs) do
    %TrainingPlan{}
    |> TrainingPlan.changeset(attrs)
    |> Repo.insert()
  end

  def update_training_plan(%TrainingPlan{} = plan, attrs) do
    plan
    |> TrainingPlan.changeset(attrs)
    |> Repo.update()
  end

  def delete_training_plan(%TrainingPlan{} = plan) do
    Repo.delete(plan)
  end

  # ── Locais de Treino ──────────────────────────────────────────────────────────

  def list_training_locations(opts \\ []) do
    only_active = Keyword.get(opts, :only_active, false)

    TrainingLocation
    |> then(fn q -> if only_active, do: where(q, [l], l.is_active == true), else: q end)
    |> order_by([l], [asc: l.sort_order, asc: l.inserted_at])
    |> Repo.all()
  end

  def get_training_location!(id), do: Repo.get!(TrainingLocation, id)

  def create_training_location(attrs) do
    %TrainingLocation{}
    |> TrainingLocation.changeset(attrs)
    |> Repo.insert()
  end

  def update_training_location(%TrainingLocation{} = location, attrs) do
    location
    |> TrainingLocation.changeset(attrs)
    |> Repo.update()
  end

  def delete_training_location(%TrainingLocation{} = location) do
    Repo.delete(location)
  end
end
