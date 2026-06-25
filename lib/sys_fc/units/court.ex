defmodule SysFc.Units.Court do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "courts" do
    field :name, :string
    field :sort_order, :integer, default: 0

    belongs_to :unit, SysFc.Units.Unit

    timestamps(type: :utc_datetime)
  end

  def changeset(court, attrs) do
    court
    |> cast(attrs, [:name, :sort_order, :unit_id])
    |> validate_required([:name, :unit_id])
    |> foreign_key_constraint(:unit_id)
    |> unique_constraint([:unit_id, :name],
      message: "já existe uma quadra com este nome nesta unidade"
    )
  end
end
