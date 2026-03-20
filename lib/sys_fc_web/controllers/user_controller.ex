defmodule SysFcWeb.UserController do
  use SysFcWeb, :controller

  alias SysFc.Accounts

  # GET /api/admin/users
  def index(conn, _params) do
    admins = Accounts.list_admins()
    render(conn, :index, users: admins)
  end

  # POST /api/admin/users
  def create(conn, params) do
    case Accounts.create_admin(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render(:show, user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/users/:id/status
  def update_status(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      user ->
        case Accounts.toggle_admin_status(user) do
          {:ok, updated} ->
            render(conn, :show, user: updated)

          {:error, :cannot_deactivate_master} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "cannot_deactivate_master"})
        end
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
