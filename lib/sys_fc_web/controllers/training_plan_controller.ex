defmodule SysFcWeb.TrainingPlanController do
  use SysFcWeb, :controller

  alias SysFc.TrainingPlans

  # ── Leitura pública (autenticado) ────────────────────────────────────────────

  # GET /api/training-plans
  def index(conn, params) do
    only_active = params["active"] != "false"
    plans = TrainingPlans.list_training_plans(only_active: only_active)
    locations = TrainingPlans.list_training_locations(only_active: only_active)
    render(conn, :index, plans: plans, locations: locations)
  end

  # ── Planos (admin) ────────────────────────────────────────────────────────────

  # POST /api/admin/training-plans
  def create_plan(conn, params) do
    case TrainingPlans.create_training_plan(params) do
      {:ok, plan} ->
        conn |> put_status(:created) |> render(:show_plan, plan: plan)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/training-plans/:id
  def update_plan(conn, %{"id" => id} = params) do
    plan = TrainingPlans.get_training_plan!(id)

    case TrainingPlans.update_training_plan(plan, params) do
      {:ok, updated} ->
        render(conn, :show_plan, plan: updated)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # DELETE /api/admin/training-plans/:id
  def delete_plan(conn, %{"id" => id}) do
    plan = TrainingPlans.get_training_plan!(id)
    {:ok, _} = TrainingPlans.delete_training_plan(plan)
    send_resp(conn, :no_content, "")
  end

  # ── Locais (admin) ────────────────────────────────────────────────────────────

  # POST /api/admin/training-locations
  def create_location(conn, params) do
    case TrainingPlans.create_training_location(params) do
      {:ok, location} ->
        conn |> put_status(:created) |> render(:show_location, location: location)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/training-locations/:id
  def update_location(conn, %{"id" => id} = params) do
    location = TrainingPlans.get_training_location!(id)

    case TrainingPlans.update_training_location(location, params) do
      {:ok, updated} ->
        render(conn, :show_location, location: updated)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # DELETE /api/admin/training-locations/:id
  def delete_location(conn, %{"id" => id}) do
    location = TrainingPlans.get_training_location!(id)
    {:ok, _} = TrainingPlans.delete_training_location(location)
    send_resp(conn, :no_content, "")
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
