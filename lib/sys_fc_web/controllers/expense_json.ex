defmodule SysFcWeb.ExpenseJSON do
  def index(%{expenses: expenses}) do
    %{data: Enum.map(expenses, &expense_data/1)}
  end

  def show(%{expense: expense}) do
    %{data: expense_data(expense)}
  end

  defp expense_data(expense) do
    %{
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      status: expense.status,
      reference_month: expense.reference_month,
      reference_year: expense.reference_year,
      is_recurring: expense.is_recurring,
      recurrence_id: expense.recurrence_id,
      recurrence_total: expense.recurrence_total,
      inserted_at: expense.inserted_at
    }
  end
end
