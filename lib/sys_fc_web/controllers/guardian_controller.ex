defmodule SysFcWeb.GuardianController do
  use SysFcWeb, :controller

  alias SysFc.Accounts

  # GET /api/admin/guardians
  def index(conn, params) do
    opts =
      []
      |> maybe_filter(:page, parse_int(params["page"]))
      |> maybe_filter(:per_page, parse_int(params["per_page"]))

    %{data: guardians, meta: meta} = Accounts.list_guardians(opts)
    render(conn, :index, guardians: guardians, meta: meta)
  end

  # POST /api/admin/guardians
  # Admin pode criar responsável apenas com nome + telefone (sem e-mail/senha)
  def create(conn, params) do
    case Accounts.create_guardian_by_admin(params) do
      {:ok, %{guardian: guardian}} ->
        conn
        |> put_status(:created)
        |> render(:show, guardian: guardian)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # GET /api/guardian/me/students  (usado pelo responsável autenticado)
  def my_students(conn, _params) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    if is_nil(guardian) do
      conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    else
      students = SysFc.Students.list_students_by_guardian(guardian.id)

      conn
      |> put_view(SysFcWeb.StudentJSON)
      |> render(:index, students: students)
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp maybe_filter(opts, _key, nil), do: opts
  defp maybe_filter(opts, _key, ""), do: opts
  defp maybe_filter(opts, key, value), do: [{key, value} | opts]

  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n) when is_integer(n), do: n

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
