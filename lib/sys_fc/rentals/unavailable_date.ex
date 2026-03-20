defmodule SysFc.Rentals.UnavailableDate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "rental_unavailable_dates" do
    field :date, :date
    field :reason, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(ud, attrs) do
    ud
    |> cast(attrs, [:date, :reason])
    |> validate_required([:date])
    |> unique_constraint(:date, message: "Esta data já está bloqueada")
  end
end
