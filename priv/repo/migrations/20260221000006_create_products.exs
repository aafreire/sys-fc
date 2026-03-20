defmodule SysFc.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :category, :string, null: false
      add :discount, :decimal, null: false, default: 0, precision: 5, scale: 2
      add :notes, :text
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:category])
    create index(:products, [:is_active])
  end
end
