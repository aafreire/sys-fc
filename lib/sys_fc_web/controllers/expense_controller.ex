defmodule SysFcWeb.ExpenseController do
  use SysFcWeb, :controller

  alias SysFc.Expenses

  # GET /api/admin/expenses?month=6&year=2026
  def index(conn, params) do
    today = Date.utc_today()
    month = parse_int(params["month"]) || today.month
    year = parse_int(params["year"]) || today.year

    expenses = Expenses.list_expenses(month, year)
    render(conn, :index, expenses: expenses)
  end

  # POST /api/admin/expenses
  def create(conn, params) do
    case Expenses.create_expense(params) do
      {:ok, expense} ->
        conn |> put_status(:created) |> render(:show, expense: expense)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/expenses/:id
  def update(conn, %{"id" => id} = params) do
    with %{} = expense <- Expenses.get_expense(id),
         {:ok, updated} <- Expenses.update_expense(expense, params) do
      render(conn, :show, expense: updated)
    else
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/expenses/:id/mark-paid
  def mark_paid(conn, %{"id" => id}) do
    with %{} = expense <- Expenses.get_expense(id),
         {:ok, updated} <- Expenses.mark_paid(expense) do
      render(conn, :show, expense: updated)
    else
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/expenses/:id/mark-unpaid
  def mark_unpaid(conn, %{"id" => id}) do
    with %{} = expense <- Expenses.get_expense(id),
         {:ok, updated} <- Expenses.mark_unpaid(expense) do
      render(conn, :show, expense: updated)
    else
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # DELETE /api/admin/expenses/:id            → remove só a ocorrência
  # DELETE /api/admin/expenses/:id?scope=series → remove toda a recorrência
  def delete(conn, %{"id" => id} = params) do
    case Expenses.get_expense(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      expense ->
        if params["scope"] == "series" and expense.recurrence_id do
          Expenses.delete_recurrence(expense.recurrence_id)
        else
          Expenses.delete_expense(expense)
        end

        send_resp(conn, :no_content, "")
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp parse_int(nil), do: nil
  defp parse_int(v) when is_integer(v), do: v

  defp parse_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> nil
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
