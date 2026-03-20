defmodule SysFc.Rentals.Rental do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @pricing_types ~w(hourly daily flat)
  @payment_methods ~w(pix credit_card on_site)
  @statuses ~w(requested confirmed cancelled completed)

  schema "rentals" do
    field :date, :date
    field :hours, :integer
    field :pricing_type, :string
    field :amount, :decimal
    field :payment_method, :string
    field :status, :string, default: "requested"
    field :notes, :string

    belongs_to :guardian, SysFc.Accounts.Guardian

    timestamps(type: :utc_datetime)
  end

  def changeset(rental, attrs) do
    rental
    |> cast(attrs, [
      :date, :hours, :pricing_type, :amount, :payment_method,
      :status, :notes, :guardian_id
    ])
    |> validate_required([:date, :pricing_type, :amount, :payment_method, :guardian_id])
    |> validate_inclusion(:pricing_type, @pricing_types,
        message: "deve ser hourly, daily ou flat"
      )
    |> validate_inclusion(:payment_method, @payment_methods,
        message: "deve ser pix, credit_card ou on_site"
      )
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:amount, greater_than: 0, message: "deve ser maior que zero")
    |> validate_hours()
    |> foreign_key_constraint(:guardian_id)
    |> unique_constraint(:date,
        name: :rentals_date_active,
        message: "Este dia já está reservado"
      )
  end

  defp validate_hours(changeset) do
    case get_field(changeset, :pricing_type) do
      "hourly" ->
        changeset
        |> validate_required([:hours], message: "informe a quantidade de horas")
        |> validate_number(:hours,
            greater_than: 0,
            less_than_or_equal_to: 24,
            message: "deve ser entre 1 e 24"
          )

      _ ->
        changeset
    end
  end
end
