defmodule SysFc.Stock.StockExit do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "stock_exits" do
    field :quantity, :integer
    field :date, :date
    field :notes, :string

    belongs_to :product, SysFc.Stock.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(exit, attrs) do
    exit
    |> cast(attrs, [:product_id, :quantity, :date, :notes])
    |> validate_required([:product_id, :quantity, :date])
    |> validate_number(:quantity, greater_than: 0)
  end
end
