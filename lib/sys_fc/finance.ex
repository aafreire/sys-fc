defmodule SysFc.Finance do
  @moduledoc """
  Contexto financeiro: mensalidades dos alunos.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Finance.Fee
  alias SysFc.Students.Student

  # ── Listagem ──────────────────────────────────────────────

  def list_fees(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      Fee
      |> apply_filters(opts)

    total = Repo.aggregate(base_query, :count)

    fees =
      base_query
      |> order_by([f], [desc: f.reference_year, desc: f.reference_month])
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(:student)
      |> Repo.all()

    %{data: fees, meta: %{page: page, per_page: per_page, total: total}}
  end

  def list_fees_by_guardian(guardian_id, opts \\ []) do
    alias SysFc.Students.StudentGuardian

    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      Fee
      |> join(:inner, [f], s in Student, on: s.id == f.student_id)
      |> join(:inner, [_f, s], sg in StudentGuardian,
        on: sg.student_id == s.id and sg.guardian_id == ^guardian_id
      )
      |> apply_filters(opts)

    total = Repo.aggregate(base_query, :count)

    fees =
      base_query
      |> order_by([f], [desc: f.reference_year, desc: f.reference_month])
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(:student)
      |> Repo.all()

    %{data: fees, meta: %{page: page, per_page: per_page, total: total}}
  end

  def list_home_fees do
    today = Date.utc_today()
    month = today.month
    year = today.year

    Fee
    |> where([f], f.reference_month == ^month and f.reference_year == ^year)
    |> where([f], f.status in [:pending, :overdue])
    |> order_by([f], asc: f.due_date)
    |> preload(student: [student_guardians: [guardian: :user]])
    |> Repo.all()
  end

  def get_fee!(id), do: Repo.get!(Fee, id) |> Repo.preload(:student)

  def get_fee(id), do: Repo.get(Fee, id) |> Repo.preload(:student)

  @doc "Mensalidades de alunos de um mês/ano específico (todos os status)."
  def list_fees_for_month(month, year) do
    Fee
    |> where([f], f.reference_month == ^month and f.reference_year == ^year)
    |> Repo.all()
  end

  @doc """
  Visão geral financeira consolidada de um mês: alunos, locações e despesas.

  Para alunos e locações calcula, por mês:
    * received   — já recebido (pago)
    * pending    — pendente (ainda não vencido)
    * overdue    — em atraso (não pago e vencido)
    * to_receive — falta receber (pending + overdue)
    * total      — received + to_receive

  Faturamento final (net_revenue) = recebido de alunos + recebido de locações
  − despesas PAGAS do mês. Valores apenas pendentes/em atraso NÃO entram no
  faturamento (ainda não entraram no caixa, mas também não são custos), e
  despesas não pagas também não são descontadas.
  """
  def financial_overview(month, year) do
    today = Date.utc_today()

    student_fees = list_fees_for_month(month, year)
    rental_fees = SysFc.Rentals.list_fees_for_month(month, year)
    expenses = SysFc.Expenses.list_expenses(month, year)

    students = summarize_receivables(student_fees, today)
    rentals = summarize_receivables(rental_fees, today)
    expenses_summary = summarize_expenses(expenses)

    total_received = Decimal.add(students.received, rentals.received)
    total_to_receive = Decimal.add(students.to_receive, rentals.to_receive)
    total_overdue = Decimal.add(students.overdue, rentals.overdue)
    # Faturamento final desconta apenas as despesas efetivamente pagas
    net_revenue = Decimal.sub(total_received, expenses_summary.paid)

    %{
      month: month,
      year: year,
      students: students,
      rentals: rentals,
      expenses: expenses_summary,
      totals: %{
        total_received: total_received,
        total_to_receive: total_to_receive,
        total_overdue: total_overdue,
        total_expenses: expenses_summary.total,
        net_revenue: net_revenue
      }
    }
  end

  defp summarize_receivables(items, today) do
    {received, pending, overdue} =
      Enum.reduce(items, {Decimal.new(0), Decimal.new(0), Decimal.new(0)}, fn it, {r, p, o} ->
        amount = to_decimal(it.amount)

        cond do
          to_string(it.status) == "paid" ->
            {Decimal.add(r, amount), p, o}

          not is_nil(it.due_date) and Date.compare(it.due_date, today) == :lt ->
            {r, p, Decimal.add(o, amount)}

          true ->
            {r, Decimal.add(p, amount), o}
        end
      end)

    to_receive = Decimal.add(pending, overdue)

    %{
      received: received,
      pending: pending,
      overdue: overdue,
      to_receive: to_receive,
      total: Decimal.add(received, to_receive)
    }
  end

  defp summarize_expenses(expenses) do
    Enum.reduce(expenses, %{total: Decimal.new(0), paid: Decimal.new(0), unpaid: Decimal.new(0)}, fn e, acc ->
      amount = to_decimal(e.amount)
      acc = %{acc | total: Decimal.add(acc.total, amount)}

      if to_string(e.status) == "paid" do
        %{acc | paid: Decimal.add(acc.paid, amount)}
      else
        %{acc | unpaid: Decimal.add(acc.unpaid, amount)}
      end
    end)
  end

  defp to_decimal(nil), do: Decimal.new(0)
  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)
  defp to_decimal(v) when is_float(v), do: Decimal.from_float(v)
  defp to_decimal(v) when is_binary(v) do
    case Decimal.parse(v) do
      {d, _} -> d
      _ -> Decimal.new(0)
    end
  end

  # ── Atualização ───────────────────────────────────────────

  def mark_as_paid(%Fee{} = fee, payment_date \\ nil) do
    payment_date = payment_date || Date.utc_today()

    fee
    |> Fee.changeset(%{status: :paid, payment_date: payment_date})
    |> Repo.update()
  end

  @doc """
  Desfaz a marcação de pagamento de uma mensalidade. Retorna o status
  para `:overdue` se a data de vencimento já passou, senão `:pending`.
  """
  def mark_as_unpaid(%Fee{} = fee) do
    today = Date.utc_today()
    new_status =
      if fee.due_date && Date.compare(fee.due_date, today) == :lt do
        :overdue
      else
        :pending
      end

    fee
    |> Fee.changeset(%{status: new_status, payment_date: nil})
    |> Repo.update()
  end

  def mark_as_under_analysis(%Fee{} = fee, receipt_url) do
    fee
    |> Fee.changeset(%{status: :under_analysis, receipt_url: receipt_url})
    |> Repo.update()
  end

  def update_fee(%Fee{} = fee, attrs) do
    fee
    |> Fee.changeset(attrs)
    |> Repo.update()
  end

  # ── Geração em lote ───────────────────────────────────────

  @doc """
  Gera fees do mês corrente para todos os alunos ativos que ainda não possuem.
  Chamado por um job mensal (ou manualmente por admin).
  """
  def generate_monthly_fees do
    today = Date.utc_today()

    Student
    |> where([s], s.is_active == true and s.is_frozen == false)
    |> Repo.all()
    |> Enum.each(fn student ->
      due_day = min(student.billing_day || 10, Date.days_in_month(today))

      %Fee{}
      |> Fee.changeset(%{
        student_id: student.id,
        reference_month: today.month,
        reference_year: today.year,
        amount: student.monthly_fee,
        due_date: Date.new!(today.year, today.month, due_day),
        status: :pending
      })
      |> Repo.insert(
        on_conflict: :nothing,
        conflict_target: [:student_id, :reference_month, :reference_year]
      )
    end)

    :ok
  end

  # ── Helpers ───────────────────────────────────────────────

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:student_id, id}, q -> where(q, [f], f.student_id == ^id)
      {:status, status}, q -> where(q, [f], f.status == ^status)
      {:year, year}, q -> where(q, [f], f.reference_year == ^year)
      {:month, month}, q -> where(q, [f], f.reference_month == ^month)
      _, q -> q
    end)
  end
end
