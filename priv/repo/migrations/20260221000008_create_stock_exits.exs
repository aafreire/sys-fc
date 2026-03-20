defmodule SysFc.Repo.Migrations.CreateStockExits do
  use Ecto.Migration

  def change do
    create table(:stock_exits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :restrict), null: false
      add :quantity, :integer, null: false
      add :date, :date, null: false
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:stock_exits, [:product_id])
    create index(:stock_exits, [:date])
  end
end
