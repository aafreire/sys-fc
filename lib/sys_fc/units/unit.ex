defmodule SysFc.Units.Unit do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "units" do
    field :name, :string
    field :is_active, :boolean, default: true
    field :sort_order, :integer, default: 0

    has_many :courts, SysFc.Units.Court, on_delete: :delete_all
    has_many :students, SysFc.Students.Student

    timestamps(type: :utc_datetime)
  end

  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [:name, :is_active, :sort_order])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
