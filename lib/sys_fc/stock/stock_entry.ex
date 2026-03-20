defmodule SysFc.Stock.StockEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "stock_entries" do
    field :quantity, :integer
    field :cost_price, :decimal
    field :sale_price, :decimal
    field :date, :date

    belongs_to :product, SysFc.Stock.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:product_id, :quantity, :cost_price, :sale_price, :date])
    |> validate_required([:product_id, :quantity, :cost_price, :sale_price, :date])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:cost_price, greater_than_or_equal_to: 0)
    |> validate_number(:sale_price, greater_than_or_equal_to: 0)
  end
end
