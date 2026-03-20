defmodule SysFcWeb.CardController do
  use SysFcWeb, :controller

  alias SysFc.Payments
  alias SysFc.Accounts

  # GET /api/guardian/cards
  def index(conn, _params) do
    with {:ok, guardian} <- guardian_for(conn) do
      cards = Payments.list_guardian_cards(guardian.id)
      conn |> put_status(:ok) |> render(:index, cards: cards)
    end
  end

  # POST /api/guardian/cards
  def create(conn, params) do
    with {:ok, guardian} <- guardian_for(conn) do
      case Payments.create_card(guardian.id, params) do
        {:ok, card} ->
          conn |> put_status(:created) |> render(:show, card: card)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "validation_failed", details: format_errors(changeset)})
      end
    end
  end

  # DELETE /api/guardian/cards/:id
  def delete(conn, %{"id" => id}) do
    with {:ok, guardian} <- guardian_for(conn) do
      case Payments.delete_card(guardian.id, id) do
        {:ok, _}             -> conn |> put_status(:ok) |> json(%{message: "deleted"})
        {:error, :not_found} -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      end
    end
  end

  # PUT /api/guardian/cards/:id/default
  def set_default(conn, %{"id" => id}) do
    with {:ok, guardian} <- guardian_for(conn) do
      case Payments.set_default_card(guardian.id, id) do
        {:ok, card} ->
          conn |> put_status(:ok) |> render(:show, card: card)

        {:error, :not_found} ->
          conn |> put_status(:not_found) |> json(%{error: "not_found"})
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp guardian_for(conn) do
    case Accounts.get_guardian_by_user_id(conn.assigns.current_user.id) do
      nil -> {:error, conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})}
      g   -> {:ok, g}
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
