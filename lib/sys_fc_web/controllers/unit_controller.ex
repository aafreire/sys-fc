defmodule SysFcWeb.UnitController do
  use SysFcWeb, :controller

  alias SysFc.Units

  # ── Leitura (autenticado, qualquer role) ──────────────────

  # GET /api/units
  def index(conn, params) do
    only_active = params["active"] != "false"
    units = Units.list_units(only_active: only_active)
    render(conn, :index, units: units)
  end

  # ── Unidades (admin) ──────────────────────────────────────

  # POST /api/admin/units
  def create(conn, params) do
    case Units.create_unit(params) do
      {:ok, unit} ->
        conn |> put_status(:created) |> render(:show, unit: unit)

      {:error, changeset} ->
        unprocessable(conn, changeset)
    end
  end

  # PUT /api/admin/units/:id
  def update(conn, %{"id" => id} = params) do
    case Units.get_unit(id) do
      nil ->
        not_found(conn)

      unit ->
        case Units.update_unit(unit, params) do
          {:ok, updated} -> render(conn, :show, unit: updated)
          {:error, changeset} -> unprocessable(conn, changeset)
        end
    end
  end

  # DELETE /api/admin/units/:id
  def delete(conn, %{"id" => id}) do
    case Units.get_unit(id) do
      nil -> not_found(conn)
      unit ->
        {:ok, _} = Units.delete_unit(unit)
        send_resp(conn, :no_content, "")
    end
  end

  # ── Quadras (admin) ───────────────────────────────────────

  # POST /api/admin/units/:unit_id/courts
  def create_court(conn, %{"unit_id" => unit_id} = params) do
    case Units.create_court(unit_id, Map.drop(params, ["unit_id"])) do
      {:ok, _court} ->
        unit = Units.get_unit(unit_id)
        conn |> put_status(:created) |> render(:show, unit: unit)

      {:error, changeset} ->
        unprocessable(conn, changeset)
    end
  end

  # PUT /api/admin/courts/:id
  def update_court(conn, %{"id" => id} = params) do
    case Units.get_court(id) do
      nil ->
        not_found(conn)

      court ->
        case Units.update_court(court, params) do
          {:ok, updated} -> render(conn, :show, unit: Units.get_unit(updated.unit_id))
          {:error, changeset} -> unprocessable(conn, changeset)
        end
    end
  end

  # DELETE /api/admin/courts/:id
  def delete_court(conn, %{"id" => id}) do
    case Units.get_court(id) do
      nil -> not_found(conn)
      court ->
        {:ok, _} = Units.delete_court(court)
        send_resp(conn, :no_content, "")
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp not_found(conn), do: conn |> put_status(:not_found) |> json(%{error: "not_found"})

  defp unprocessable(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "validation_failed", details: format_errors(changeset)})
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
