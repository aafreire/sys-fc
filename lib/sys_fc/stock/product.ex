defmodule SysFc.Stock.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :name, :string
    field :category, :string
    field :discount, :decimal, default: Decimal.new("0")
    field :notes, :string
    field :is_active, :boolean, default: true

    has_many :stock_entries, SysFc.Stock.StockEntry
    has_many :stock_exits, SysFc.Stock.StockExit
    has_many :uniform_order_items, SysFc.Uniforms.UniformOrderItem

    timestamps(type: :utc_datetime)
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :category, :discount, :notes, :is_active])
    |> validate_required([:name, :category])
    |> validate_number(:discount, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
