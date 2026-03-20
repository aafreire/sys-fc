defmodule SysFc.TrainingPlans.TrainingPlan do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "training_plans" do
    field :name, :string
    field :label, :string
    field :description, :string
    field :frequency, :string
    field :days, {:array, :string}, default: []
    field :price, :decimal
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:name, :label, :description, :frequency, :days, :price, :is_active, :sort_order])
    |> validate_required([:name, :label, :days, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
