defmodule SysFc.Students.Student do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @categories ~w(Sub-7 Sub-8 Sub-9 Sub-10 Sub-11 Sub-12 Sub-13 Sub-14 Sub-15 Sub-17)
  @statuses ~w(pending_confirmation active rejected)

  schema "students" do
    field :enrollment_number, :string
    field :name, :string
    field :birth_date, :date
    field :category, :string
    field :photo_url, :string
    field :rg, :string
    field :school_name, :string
    field :address, :string
    field :address_number, :string
    field :neighborhood, :string
    field :city, :string
    field :complement, :string
    field :cep, :string
    field :training_days, {:array, :string}, default: []
    field :training_plan, :string
    field :training_location, :string
    field :has_health_plan, :boolean, default: false
    field :health_plan_name, :string
    field :monthly_fee, :decimal
    field :billing_day, :integer, default: 10
    field :is_active, :boolean, default: true
    field :is_frozen, :boolean, default: false
    field :status, :string, default: "active"

    has_many :student_guardians, SysFc.Students.StudentGuardian
    has_many :guardians, through: [:student_guardians, :guardian]
    has_many :fees, SysFc.Finance.Fee
    has_many :players, SysFc.Championships.Player
    has_many :uniform_orders, SysFc.Uniforms.UniformOrder

    timestamps(type: :utc_datetime)
  end

  def changeset(student, attrs) do
    student
    |> cast(attrs, [
      :enrollment_number, :name, :birth_date, :category, :photo_url,
      :rg, :school_name, :address, :address_number, :neighborhood,
      :city, :complement, :cep, :training_days, :training_plan, :training_location,
      :has_health_plan, :health_plan_name, :monthly_fee, :billing_day,
      :is_active, :is_frozen, :status
    ])
    |> validate_required([:enrollment_number, :name, :birth_date, :category, :monthly_fee, :rg])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:monthly_fee, greater_than_or_equal_to: 0)
    |> validate_number(:billing_day,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to: 28,
        message: "deve ser entre 1 e 28"
      )
    |> sanitize_cep()
    |> validate_cep_format()
    |> validate_rg_format()
    |> unique_constraint(:enrollment_number)
    |> unique_constraint(:rg, name: :students_rg_unique, message: "já existe um aluno cadastrado com este RG")
  end

  @doc "Changeset para atualização — RG não obrigatório (permite atualizar alunos legados)."
  def update_changeset(student, attrs) do
    student
    |> cast(attrs, [
      :enrollment_number, :name, :birth_date, :category, :photo_url,
      :rg, :school_name, :address, :address_number, :neighborhood,
      :city, :complement, :cep, :training_days, :training_plan, :training_location,
      :has_health_plan, :health_plan_name, :monthly_fee, :billing_day,
      :is_active, :is_frozen, :status
    ])
    |> validate_required([:enrollment_number, :name, :birth_date, :category, :monthly_fee])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:monthly_fee, greater_than_or_equal_to: 0)
    |> validate_number(:billing_day,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to: 28,
        message: "deve ser entre 1 e 28"
      )
    |> sanitize_cep()
    |> validate_cep_format()
    |> validate_rg_format()
    |> unique_constraint(:enrollment_number)
    |> unique_constraint(:rg, name: :students_rg_unique, message: "já existe um aluno cadastrado com este RG")
  end

  # Normaliza CEP: aceita "00000-000" ou "00000000" → armazena sem hífen
  defp sanitize_cep(changeset) do
    case get_change(changeset, :cep) do
      nil -> changeset
      cep -> put_change(changeset, :cep, String.replace(cep, ~r/\D/, ""))
    end
  end

  defp validate_cep_format(changeset) do
    case get_field(changeset, :cep) do
      nil -> changeset
      "" -> changeset
      _ ->
        validate_format(changeset, :cep, ~r/^\d{8}$/,
          message: "deve ter 8 dígitos numéricos (ex: 09510100)"
        )
    end
  end

  # RG é opcional e varia por estado; valida apenas comprimento e caracteres básicos
  defp validate_rg_format(changeset) do
    case get_change(changeset, :rg) do
      nil -> changeset
      "" -> changeset
      _ ->
        changeset
        |> validate_length(:rg, min: 5, max: 20,
            message: "deve ter entre 5 e 20 caracteres"
          )
        |> validate_format(:rg, ~r/^[\d.\-xX\/]+$/,
            message: "contém caracteres inválidos"
          )
    end
  end
end
