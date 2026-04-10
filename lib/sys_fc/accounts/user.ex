defmodule SysFc.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :role, Ecto.Enum, values: [:admin_master, :admin_limited, :guardian], default: :guardian
    field :is_active, :boolean, default: true

    has_one :guardian, SysFc.Accounts.Guardian

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset para criação de usuário com e-mail e senha (fluxo completo)"
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role, :is_active])
    |> validate_required([:name, :email, :password, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:password, min: 8, max: 72)
    |> validate_inclusion(:role, [:admin_master, :admin_limited, :guardian])
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc """
  Changeset para criação de responsável pelo admin, sem e-mail/senha obrigatórios.
  Apenas nome e role são necessários.
  Se e-mail for fornecido, senha também é obrigatória (e vice-versa).
  """
  @doc "Changeset para admin stub (telefone, sem email/senha)"
  def admin_stub_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :phone, :role, :is_active])
    |> validate_required([:name, :phone, :role])
    |> validate_inclusion(:role, [:admin_master, :admin_limited])
    |> unique_constraint(:phone, name: :users_phone_unique)
  end

  def guardian_stub_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role, :is_active])
    |> validate_required([:name, :role])
    |> validate_inclusion(:role, [:admin_master, :admin_limited, :guardian])
    |> validate_email_if_present()
    |> validate_password_if_present()
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc "Changeset para completar conta de responsável (adicionar e-mail e senha)"
  def complete_account_changeset(user, attrs) do
    required = [:password]
    required = if is_nil(user.email), do: [:email | required], else: required

    user
    |> cast(attrs, [:email, :password, :name])
    |> validate_required(required)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:password, min: 8, max: 72)
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc "Changeset para atualização de dados (sem senha)"
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :role, :is_active])
    |> validate_required([:name, :role])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 160)
    |> validate_inclusion(:role, [:admin_master, :admin_limited, :guardian])
    |> unique_constraint(:email)
  end

  defp validate_email_if_present(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      _ ->
        changeset
        |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
        |> validate_length(:email, max: 160)
    end
  end

  defp validate_password_if_present(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      _ -> validate_length(changeset, :password, min: 8, max: 72)
    end
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  defp hash_password(changeset), do: changeset

  @doc "Verifica se a senha corresponde ao hash armazenado"
  def valid_password?(%__MODULE__{password_hash: hash}, password) do
    Argon2.verify_pass(password, hash)
  end

  def valid_password?(_, _), do: Argon2.no_user_verify()
end
