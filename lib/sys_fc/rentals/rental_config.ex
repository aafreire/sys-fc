defmodule SysFc.Rentals.RentalConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "rental_configs" do
    field :price_per_hour, :decimal
    field :price_per_day, :decimal
    field :price_flat, :decimal
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:price_per_hour, :price_per_day, :price_flat, :description])
    |> validate_number(:price_per_hour, greater_than: 0, message: "deve ser maior que zero")
    |> validate_number(:price_per_day, greater_than: 0, message: "deve ser maior que zero")
    |> validate_number(:price_flat, greater_than: 0, message: "deve ser maior que zero")
  end
end
