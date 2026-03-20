defmodule SysFc.Uniforms.UniformOrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "uniform_order_items" do
    field :size, :string
    field :quantity, :integer
    field :unit_price, :decimal

    belongs_to :uniform_order, SysFc.Uniforms.UniformOrder
    belongs_to :product, SysFc.Stock.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:uniform_order_id, :product_id, :size, :quantity, :unit_price])
    |> validate_required([:uniform_order_id, :product_id, :size, :quantity, :unit_price])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than_or_equal_to: 0)
  end
end
