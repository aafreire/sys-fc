defmodule SysFc.Rentals.RentalFee do
  @moduledoc """
  Cobrança financeira de uma locação. Para locações únicas há apenas
  uma cobrança; para locações recorrentes há uma por mês de referência.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(pending paid overdue under_analysis)

  schema "rental_fees" do
    field :reference_month, :integer
    field :reference_year, :integer
    field :amount, :decimal
    field :due_date, :date
    field :payment_date, :date
    field :status, :string, default: "pending"
    field :receipt_url, :string
    field :notes, :string

    belongs_to :rental, SysFc.Rentals.Rental

    timestamps(type: :utc_datetime)
  end

  def changeset(fee, attrs) do
    fee
    |> cast(attrs, [
      :rental_id, :reference_month, :reference_year, :amount,
      :due_date, :payment_date, :status, :receipt_url, :notes
    ])
    |> validate_required([:rental_id, :amount, :due_date])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:amount, greater_than: 0)
    |> maybe_validate_month()
    |> foreign_key_constraint(:rental_id)
  end

  defp maybe_validate_month(changeset) do
    case get_field(changeset, :reference_month) do
      nil -> changeset
      _ ->
        changeset
        |> validate_inclusion(:reference_month, 1..12)
        |> validate_required([:reference_year])
        |> validate_number(:reference_year, greater_than: 2000)
    end
  end
end
