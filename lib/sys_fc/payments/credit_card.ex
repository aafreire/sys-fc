defmodule SysFc.Payments.CreditCard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @brands ~w(visa mastercard elo amex hipercard other)

  schema "credit_cards" do
    field :token, :string
    field :brand, :string
    field :last_four, :string
    field :holder_name, :string
    field :expiry_month, :integer
    field :expiry_year, :integer
    field :is_default, :boolean, default: false
    field :is_active, :boolean, default: true

    belongs_to :guardian, SysFc.Accounts.Guardian

    timestamps(type: :utc_datetime)
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [
      :token, :brand, :last_four, :holder_name,
      :expiry_month, :expiry_year, :is_default, :is_active, :guardian_id
    ])
    |> validate_required([:token, :brand, :last_four, :holder_name, :expiry_month, :expiry_year, :guardian_id])
    |> validate_inclusion(:brand, @brands, message: "bandeira inválida")
    |> validate_length(:last_four, is: 4, message: "deve ter exatamente 4 dígitos")
    |> validate_format(:last_four, ~r/^\d{4}$/, message: "deve conter apenas dígitos")
    |> validate_number(:expiry_month, greater_than_or_equal_to: 1, less_than_or_equal_to: 12)
    |> validate_number(:expiry_year, greater_than_or_equal_to: 2024)
    |> validate_length(:holder_name, min: 3, message: "nome muito curto")
    |> foreign_key_constraint(:guardian_id)
    |> unique_constraint(:token)
  end

  def status_changeset(card, attrs) do
    card
    |> cast(attrs, [:is_default, :is_active])
  end
end
