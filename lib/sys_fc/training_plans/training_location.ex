defmodule SysFc.TrainingPlans.TrainingLocation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "training_locations" do
    field :name, :string
    field :label, :string
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :label, :is_active, :sort_order])
    |> validate_required([:name, :label])
    |> unique_constraint(:name)
  end
end
