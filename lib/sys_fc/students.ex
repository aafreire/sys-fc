defmodule SysFc.Students do
  @moduledoc """
  Contexto de alunos: CRUD, vínculo com responsável, geração de matrícula.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Students.{Student, StudentGuardian}
  alias SysFc.Finance.Fee

  # ── Listagem / Busca ──────────────────────────────────────

  def list_students(opts \\ []) do
    # Por padrão só retorna alunos ativos (exclui pendentes e recusados)
    opts = if Keyword.has_key?(opts, :status), do: opts, else: [{:status, "active"} | opts]

    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      Student
      |> apply_filters(opts)

    total = Repo.aggregate(base_query, :count)

    students =
      base_query
      |> order_by([s], asc: s.name)
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(student_guardians: [guardian: :user])
      |> Repo.all()

    %{data: students, meta: %{page: page, per_page: per_page, total: total}}
  end

  def get_student(id) do
    Student
    |> preload(student_guardians: [guardian: :user])
    |> Repo.get(id)
  end

  def get_student!(id) do
    Student
    |> preload(student_guardians: [guardian: :user])
    |> Repo.get!(id)
  end

  def list_students_by_guardian(guardian_id) do
    Student
    |> join(:inner, [s], sg in StudentGuardian,
      on: sg.student_id == s.id and sg.guardian_id == ^guardian_id
    )
    |> order_by([s], asc: s.name)
    |> preload(student_guardians: [guardian: :user])
    |> Repo.all()
  end

  # ── Criação ───────────────────────────────────────────────

  @doc """
  Cria um aluno pelo admin dentro de uma transação:
    1. Gera enrollment_number
    2. Insere o aluno com status :active
    3. Vincula ao responsável (guardian_id)
    4. Cria fee do mês corrente
  """
  def create_student(attrs, guardian_id) when is_binary(guardian_id) do
    attrs = Map.put(attrs, "status", "active")

    Repo.transaction(fn ->
      with {:ok, student} <- insert_student(attrs),
           {:ok, _sg} <- link_guardian(student.id, guardian_id, true),
           {:ok, _fee} <- generate_current_fee(student) do
        Repo.preload(student, student_guardians: [guardian: :user])
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def create_student(_attrs, nil), do: {:error, :guardian_required}

  @doc """
  Cria um aluno pelo responsável com status :pending_confirmation.
  Não gera fee — a mensalidade só é gerada após confirmação pelo admin.
  """
  def create_student_by_guardian(attrs, guardian_id) when is_binary(guardian_id) do
    attrs = Map.put(attrs, "status", "pending_confirmation")

    Repo.transaction(fn ->
      with {:ok, student} <- insert_student(attrs),
           {:ok, _sg} <- link_guardian(student.id, guardian_id, true) do
        Repo.preload(student, student_guardians: [guardian: :user])
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def create_student_by_guardian(_attrs, nil), do: {:error, :guardian_required}

  # ── Atualização ───────────────────────────────────────────

  def update_student(%Student{} = student, attrs) do
    student
    |> Student.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, student_guardians: [guardian: :user])}
      error -> error
    end
  end

  def deactivate_student(%Student{} = student) do
    student
    |> Student.changeset(%{"is_active" => false})
    |> Repo.update()
  end

  @doc """
  Confirma um aluno pendente: muda status para :active e gera a mensalidade do mês.
  """
  def confirm_student(%Student{} = student) do
    Repo.transaction(fn ->
      with {:ok, confirmed} <-
             (student
              |> Student.changeset(%{"status" => "active"})
              |> Repo.update()),
           {:ok, _fee} <- generate_current_fee(confirmed) do
        Repo.preload(confirmed, student_guardians: [guardian: :user])
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Recusa um aluno pendente: muda status para :rejected.
  """
  def reject_student(%Student{} = student) do
    student
    |> Student.changeset(%{"status" => "rejected"})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, student_guardians: [guardian: :user])}
      error -> error
    end
  end

  @doc """
  Lista alunos com status pending_confirmation (aguardando aprovação do admin).
  """
  def list_pending_students(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      Student
      |> where([s], s.status == "pending_confirmation")

    total = Repo.aggregate(base_query, :count)

    students =
      base_query
      |> order_by([s], asc: s.inserted_at)
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(student_guardians: [guardian: :user])
      |> Repo.all()

    %{data: students, meta: %{page: page, per_page: per_page, total: total}}
  end

  # ── Congelamento de matrícula ─────────────────────────────

  @doc "Congela a matrícula do aluno. Nenhuma mensalidade será gerada enquanto congelado."
  def freeze_student(%Student{} = student) do
    student
    |> Student.changeset(%{"is_frozen" => true})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, student_guardians: [guardian: :user])}
      error -> error
    end
  end

  @doc "Descongela a matrícula do aluno, reativando a geração de mensalidades."
  def unfreeze_student(%Student{} = student) do
    student
    |> Student.changeset(%{"is_frozen" => false})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, student_guardians: [guardian: :user])}
      error -> error
    end
  end

  # ── Vínculo com responsável ───────────────────────────────

  def link_guardian(student_id, guardian_id, is_primary \\ false) do
    %StudentGuardian{}
    |> StudentGuardian.changeset(%{
      student_id: student_id,
      guardian_id: guardian_id,
      is_primary: is_primary
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:student_id, :guardian_id])
  end

  def unlink_guardian(student_id, guardian_id) do
    StudentGuardian
    |> where(student_id: ^student_id, guardian_id: ^guardian_id)
    |> Repo.delete_all()
  end

  # ── Helpers privados ──────────────────────────────────────

  defp insert_student(attrs) do
    enrollment = generate_enrollment_number()

    attrs
    |> Map.put("enrollment_number", enrollment)
    |> then(&Student.changeset(%Student{}, &1))
    |> Repo.insert()
  end

  defp generate_enrollment_number do
    year = Date.utc_today().year

    count =
      Student
      |> where([s], fragment("EXTRACT(YEAR FROM ?)", s.inserted_at) == ^year)
      |> Repo.aggregate(:count)

    "#{year}#{String.pad_leading(to_string(count + 1), 4, "0")}"
  end

  defp generate_current_fee(%Student{} = student) do
    today = Date.utc_today()
    due_day = min(student.billing_day || 10, Date.days_in_month(today))
    due_date = Date.new!(today.year, today.month, due_day)

    %Fee{}
    |> Fee.changeset(%{
      student_id: student.id,
      reference_month: today.month,
      reference_year: today.year,
      amount: student.monthly_fee,
      due_date: due_date,
      status: :pending
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:student_id, :reference_month, :reference_year])
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:category, cat}, q when is_binary(cat) ->
        where(q, [s], s.category == ^cat)

      {:is_active, active}, q when is_boolean(active) ->
        where(q, [s], s.is_active == ^active)

      {:status, status}, q when is_binary(status) ->
        where(q, [s], s.status == ^status)

      {:search, term}, q when is_binary(term) and term != "" ->
        like = "%#{term}%"
        where(q, [s], ilike(s.name, ^like) or ilike(s.enrollment_number, ^like))

      {:guardian_id, gid}, q when is_binary(gid) ->
        join(q, :inner, [s], sg in StudentGuardian,
          on: sg.student_id == s.id and sg.guardian_id == ^gid
        )

      {:guardian_search, term}, q when is_binary(term) and term != "" ->
        like = "%#{term}%"

        q
        |> join(:inner, [s], sg in StudentGuardian, on: sg.student_id == s.id, as: :sg_search)
        |> join(:inner, [sg_search: sg], g in SysFc.Accounts.Guardian, on: g.id == sg.guardian_id, as: :g_search)
        |> join(:inner, [g_search: g], u in SysFc.Accounts.User, on: u.id == g.user_id, as: :u_search)
        |> where([u_search: u], ilike(u.name, ^like))
        |> distinct([s], s.id)

      _, q ->
        q
    end)
  end
end
