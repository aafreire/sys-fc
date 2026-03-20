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

    alias SysFc.Students.StudentGuardian

    Fee
    |> where([f], f.reference_month == ^month and f.reference_year == ^year)
    |> where([f], f.status in [:pending, :overdue])
    |> order_by([f], asc: f.due_date)
    |> preload(student: [student_guardians: [guardian: :user]])
    |> Repo.all()
  end

  def get_fee!(id), do: Repo.get!(Fee, id) |> Repo.preload(:student)

  def get_fee(id), do: Repo.get(Fee, id) |> Repo.preload(:student)

  # ── Atualização ───────────────────────────────────────────

  def mark_as_paid(%Fee{} = fee, payment_date \\ nil) do
    payment_date = payment_date || Date.utc_today()

    fee
    |> Fee.changeset(%{status: :paid, payment_date: payment_date})
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
