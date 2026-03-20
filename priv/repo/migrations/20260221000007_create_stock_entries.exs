defmodule SysFc.Repo.Migrations.CreateStockEntries do
  use Ecto.Migration

  def change do
    create table(:stock_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :restrict), null: false
      add :quantity, :integer, null: false
      add :cost_price, :decimal, null: false, precision: 10, scale: 2
      add :sale_price, :decimal, null: false, precision: 10, scale: 2
      add :date, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stock_entries, [:product_id])
    create index(:stock_entries, [:date])
  end
end
