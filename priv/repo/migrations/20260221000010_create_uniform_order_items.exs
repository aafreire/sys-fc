defmodule SysFc.Repo.Migrations.CreateUniformOrderItems do
  use Ecto.Migration

  def change do
    create table(:uniform_order_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uniform_order_id, references(:uniform_orders, type: :binary_id, on_delete: :delete_all), null: false
      add :product_id, references(:products, type: :binary_id, on_delete: :restrict), null: false
      add :size, :string, null: false
      add :quantity, :integer, null: false
      add :unit_price, :decimal, null: false, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:uniform_order_items, [:uniform_order_id])
    create index(:uniform_order_items, [:product_id])
  end
end
