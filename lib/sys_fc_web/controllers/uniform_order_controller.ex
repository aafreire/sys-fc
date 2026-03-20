defmodule SysFcWeb.UniformOrderController do
  use SysFcWeb, :controller

  alias SysFc.Uniforms
  alias SysFc.Accounts

  # ── Admin ─────────────────────────────────────────────────

  # GET /api/admin/uniforms/orders
  def index(conn, params) do
    opts =
      []
      |> maybe_filter(:status, parse_status(params["status"]))
      |> maybe_filter(:guardian_id, params["guardian_id"])
      |> maybe_filter(:student_id, params["student_id"])

    orders = Uniforms.list_orders(opts)
    render(conn, :index, orders: orders)
  end

  # GET /api/admin/uniforms/orders/:id
  def show(conn, %{"id" => id}) do
    case Uniforms.get_order(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      order -> render(conn, :show, order: order)
    end
  end

  # PUT /api/admin/uniforms/orders/:id/status
  def update_status(conn, %{"id" => id, "status" => status}) do
    case Uniforms.get_order(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      order ->
        case Uniforms.update_status(order, parse_status(status)) do
          {:ok, updated} ->
            render(conn, :show, order: updated)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  def update_status(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "status is required"})
  end

  # ── Guardian ──────────────────────────────────────────────

  # GET /api/guardian/uniforms/orders
  def guardian_index(conn, _params) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    if is_nil(guardian) do
      conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    else
      orders = Uniforms.list_orders_by_guardian(guardian.id)
      render(conn, :index, orders: orders)
    end
  end

  # GET /api/guardian/uniforms/orders/:id
  def guardian_show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    with %{} = order <- Uniforms.get_order(id),
         true <- order.guardian_id == guardian.id do
      render(conn, :show, order: order)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      false -> conn |> put_status(:forbidden) |> json(%{error: "forbidden"})
    end
  end

  # POST /api/guardian/uniforms/orders
  def guardian_create(conn, %{"student_id" => student_id, "items" => items}) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    if is_nil(guardian) do
      conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    else
      case Uniforms.create_order(guardian.id, student_id, items) do
        {:ok, order} ->
          conn |> put_status(:created) |> render(:show, order: order)

        {:error, {:insufficient_stock, details}} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "insufficient_stock", details: details})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "validation_failed", details: format_errors(changeset)})
      end
    end
  end

  def guardian_create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "student_id and items are required"})
  end

  # ── Helpers ───────────────────────────────────────────────

  defp maybe_filter(opts, _key, nil), do: opts
  defp maybe_filter(opts, _key, ""), do: opts
  defp maybe_filter(opts, key, value), do: [{key, value} | opts]

  defp parse_status(nil), do: nil
  defp parse_status(s) when is_atom(s), do: s
  defp parse_status(s) when is_binary(s) do
    case s do
      "pedido_realizado" -> :pedido_realizado
      "pagamento_realizado" -> :pagamento_realizado
      "pronto_retirada" -> :pronto_retirada
      "entregue" -> :entregue
      _ -> nil
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
