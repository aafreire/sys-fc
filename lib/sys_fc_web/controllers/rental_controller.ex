defmodule SysFcWeb.RentalController do
  use SysFcWeb, :controller

  alias SysFc.Rentals
  alias SysFc.Accounts

  # ── Config (admin) ────────────────────────────────────────────

  # GET /api/admin/rental-config
  def get_config(conn, _params) do
    config = Rentals.get_config()
    conn |> put_status(:ok) |> render(:config, config: config)
  end

  # PUT /api/admin/rental-config
  def update_config(conn, params) do
    case Rentals.update_config(params) do
      {:ok, config} ->
        conn |> put_status(:ok) |> render(:config, config: config)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # ── Datas indisponíveis (admin) ───────────────────────────────

  # GET /api/admin/rental-unavailable
  def list_unavailable(conn, _params) do
    dates = Rentals.list_unavailable_dates()
    conn |> put_status(:ok) |> render(:unavailable_dates, dates: dates)
  end

  # POST /api/admin/rental-unavailable
  def create_unavailable(conn, params) do
    case Rentals.create_unavailable_date(params) do
      {:ok, date} ->
        conn |> put_status(:created) |> render(:unavailable_date, date: date)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # DELETE /api/admin/rental-unavailable/:id
  def delete_unavailable(conn, %{"id" => id}) do
    case Rentals.delete_unavailable_date(id) do
      {:ok, _}             -> conn |> put_status(:ok) |> json(%{message: "deleted"})
      {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
    end
  end

  # ── Reservas (admin) ─────────────────────────────────────────

  # GET /api/admin/rentals
  def admin_index(conn, _params) do
    rentals = Rentals.list_all_rentals()
    conn |> put_status(:ok) |> render(:admin_index, rentals: rentals)
  end

  # PUT /api/admin/rentals/:id/status
  def admin_update_status(conn, %{"id" => id, "status" => status}) do
    case Rentals.get_rental(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      rental ->
        case Rentals.update_rental_status(rental, status) do
          {:ok, updated} ->
            conn |> put_status(:ok) |> render(:admin_show, rental: updated)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  def admin_update_status(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "status is required"})
  end

  # ── Calendário (autenticado, qualquer role) ───────────────────

  # GET /api/rentals/calendar?year=2026&month=2
  def calendar(conn, params) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)
    guardian_id = if guardian, do: guardian.id, else: nil

    today = Date.utc_today()
    year  = parse_int(params["year"],  today.year)
    month = parse_int(params["month"], today.month)

    config = Rentals.get_config()
    days   = Rentals.get_calendar(year, month, guardian_id)

    conn
    |> put_status(:ok)
    |> render(:calendar, days: days, config: config, year: year, month: month)
  end

  # ── Reservas (guardian) ───────────────────────────────────────

  # GET /api/guardian/rentals
  def guardian_index(conn, _params) do
    with guardian when not is_nil(guardian) <- guardian_for(conn) do
      rentals = Rentals.list_guardian_rentals(guardian.id)
      conn |> put_status(:ok) |> render(:index, rentals: rentals)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    end
  end

  # POST /api/guardian/rentals
  def guardian_create(conn, params) do
    with guardian when not is_nil(guardian) <- guardian_for(conn) do
      case Rentals.create_rental(guardian.id, params) do
        {:ok, rental} ->
          conn |> put_status(:created) |> render(:show, rental: rental)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "validation_failed", details: format_errors(changeset)})
      end
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp guardian_for(conn) do
    Accounts.get_guardian_by_user_id(conn.assigns.current_user.id)
  end

  defp parse_int(nil, default), do: default
  defp parse_int(v, _default) when is_integer(v), do: v
  defp parse_int(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error  -> default
    end
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
