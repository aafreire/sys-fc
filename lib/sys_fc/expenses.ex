defmodule SysFc.Expenses do
  @moduledoc """
  Contexto de despesas da escolinha.

  Cada despesa é registrada como uma ocorrência mensal (`reference_month` /
  `reference_year`). Despesas recorrentes compartilham um `recurrence_id`:

    * recorrência por N meses  → materializa N ocorrências no cadastro
    * recorrência indeterminada (`recurrence_total = nil`) → materializa um
      horizonte adiante e é estendida automaticamente conforme novos meses
      são consultados (`list_expenses/2`), sem cadastro manual mês a mês.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Expenses.Expense

  # Meses materializados adiante para recorrência por tempo indeterminado
  @indefinite_horizon 12

  @doc """
  Lista as despesas de um mês/ano, garantindo que as recorrências
  indeterminadas estejam materializadas até o mês solicitado.
  """
  def list_expenses(month, year) do
    ensure_recurring_materialized(month, year)

    Expense
    |> where([e], e.reference_month == ^month and e.reference_year == ^year)
    |> order_by([e], asc: e.title)
    |> Repo.all()
  end

  def get_expense(id), do: Repo.get(Expense, id)

  @doc """
  Cria uma despesa. Para `is_recurring = true`, gera as ocorrências mensais
  conforme `recurrence_total` (nil = indeterminado). Retorna a ocorrência do
  mês inicial.
  """
  def create_expense(attrs) do
    attrs = normalize_keys(attrs)
    {month, year} = start_month_year(attrs)

    if truthy(attrs["is_recurring"]) do
      recurrence_id = Ecto.UUID.generate()
      total = parse_int(attrs["recurrence_total"])

      count =
        case total do
          nil -> @indefinite_horizon
          n when n > 0 -> n
          _ -> 1
        end

      Repo.transaction(fn ->
        Enum.reduce(0..(count - 1), nil, fn offset, primary ->
          {m, y} = add_month(month, year, offset)

          case insert_occurrence(attrs, m, y, true, recurrence_id, total) do
            {:ok, expense} -> primary || expense
            {:error, changeset} -> Repo.rollback(changeset)
          end
        end)
      end)
    else
      insert_occurrence(attrs, month, year, false, nil, nil)
    end
  end

  def update_expense(%Expense{} = expense, attrs) do
    expense
    |> Expense.update_changeset(normalize_keys(attrs))
    |> Repo.update()
  end

  def mark_paid(%Expense{} = expense) do
    update_expense(expense, %{"title" => expense.title, "amount" => expense.amount, "status" => "paid"})
  end

  def mark_unpaid(%Expense{} = expense) do
    update_expense(expense, %{"title" => expense.title, "amount" => expense.amount, "status" => "unpaid"})
  end

  @doc "Remove apenas a ocorrência informada."
  def delete_expense(%Expense{} = expense), do: Repo.delete(expense)

  @doc "Remove todas as ocorrências de uma série recorrente."
  def delete_recurrence(recurrence_id) when is_binary(recurrence_id) do
    Expense
    |> where([e], e.recurrence_id == ^recurrence_id)
    |> Repo.delete_all()
  end

  # ── Materialização de recorrências indeterminadas ────────────

  defp ensure_recurring_materialized(month, year) do
    target = month_index(month, year)

    recurrence_ids =
      Expense
      |> where([e], e.is_recurring == true and is_nil(e.recurrence_total) and not is_nil(e.recurrence_id))
      |> distinct(true)
      |> select([e], e.recurrence_id)
      |> Repo.all()

    Enum.each(recurrence_ids, fn rid ->
      latest =
        Expense
        |> where([e], e.recurrence_id == ^rid)
        |> order_by([e], desc: e.reference_year, desc: e.reference_month)
        |> limit(1)
        |> Repo.one()

      if latest do
        latest_idx = month_index(latest.reference_month, latest.reference_year)

        if target > latest_idx do
          Enum.each((latest_idx + 1)..target, fn idx ->
            {m, y} = index_to_month_year(idx)

            %Expense{}
            |> Expense.changeset(%{
              title: latest.title,
              amount: latest.amount,
              status: "unpaid",
              reference_month: m,
              reference_year: y,
              is_recurring: true,
              recurrence_id: rid,
              recurrence_total: nil
            })
            |> Repo.insert(
              on_conflict: :nothing,
              conflict_target: [:recurrence_id, :reference_year, :reference_month]
            )
          end)
        end
      end
    end)
  end

  # ── Helpers ──────────────────────────────────────────────────

  defp insert_occurrence(attrs, month, year, is_recurring, recurrence_id, total) do
    %Expense{}
    |> Expense.changeset(%{
      title: attrs["title"],
      amount: attrs["amount"],
      status: attrs["status"] || "unpaid",
      reference_month: month,
      reference_year: year,
      is_recurring: is_recurring,
      recurrence_id: recurrence_id,
      recurrence_total: total
    })
    |> Repo.insert()
  end

  defp start_month_year(attrs) do
    today = Date.utc_today()
    month = parse_int(attrs["reference_month"]) || today.month
    year = parse_int(attrs["reference_year"]) || today.year
    {month, year}
  end

  defp month_index(month, year), do: year * 12 + (month - 1)

  defp index_to_month_year(idx), do: {rem(idx, 12) + 1, div(idx, 12)}

  defp add_month(month, year, offset), do: index_to_month_year(month_index(month, year) + offset)

  defp normalize_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
  end

  defp truthy(true), do: true
  defp truthy("true"), do: true
  defp truthy(_), do: false

  defp parse_int(nil), do: nil
  defp parse_int(v) when is_integer(v), do: v

  defp parse_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_int(_), do: nil
end
