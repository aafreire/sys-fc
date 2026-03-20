defmodule SysFc.Accounts.Guardian do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "guardians" do
    field :cpf, :string
    field :phone, :string

    belongs_to :user, SysFc.Accounts.User
    has_many :student_guardians, SysFc.Students.StudentGuardian
    has_many :students, through: [:student_guardians, :student]
    has_many :uniform_orders, SysFc.Uniforms.UniformOrder

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset padrão — CPF e telefone opcionais, validados se fornecidos"
  def changeset(guardian, attrs) do
    guardian
    |> cast(attrs, [:user_id, :cpf, :phone])
    |> validate_required([:user_id])
    |> sanitize_cpf()
    |> validate_cpf_format()
    |> sanitize_phone()
    |> validate_phone_format()
    |> unique_constraint(:user_id)
    |> unique_constraint(:cpf)
    |> unique_constraint(:phone, name: :guardians_phone_index)
  end

  @doc "Changeset para criação pelo admin — telefone obrigatório, CPF opcional"
  def admin_create_changeset(guardian, attrs) do
    guardian
    |> cast(attrs, [:user_id, :cpf, :phone])
    |> validate_required([:user_id, :phone])
    |> sanitize_cpf()
    |> validate_cpf_format()
    |> sanitize_phone()
    |> validate_phone_format()
    |> unique_constraint(:user_id)
    |> unique_constraint(:cpf)
    |> unique_constraint(:phone, name: :guardians_phone_index)
  end

  defp sanitize_cpf(changeset) do
    case get_change(changeset, :cpf) do
      nil -> changeset
      "" -> put_change(changeset, :cpf, nil)
      cpf -> put_change(changeset, :cpf, String.replace(cpf, ~r/\D/, ""))
    end
  end

  defp validate_cpf_format(changeset) do
    case get_field(changeset, :cpf) do
      nil -> changeset
      "" -> changeset
      _ ->
        validate_format(changeset, :cpf, ~r/^\d{11}$/,
          message: "deve ter 11 dígitos numéricos"
        )
    end
  end

  # Remove qualquer caractere não-numérico do telefone antes de validar
  defp sanitize_phone(changeset) do
    case get_change(changeset, :phone) do
      nil -> changeset
      phone -> put_change(changeset, :phone, String.replace(phone, ~r/\D/, ""))
    end
  end

  # Valida formato do telefone somente quando informado (campo opcional)
  defp validate_phone_format(changeset) do
    case get_field(changeset, :phone) do
      nil -> changeset
      "" -> changeset
      _ ->
        validate_format(changeset, :phone, ~r/^\d{10,11}$/,
          message: "deve ter 10 ou 11 dígitos com DDD (ex: 11987654321)"
        )
    end
  end
end
