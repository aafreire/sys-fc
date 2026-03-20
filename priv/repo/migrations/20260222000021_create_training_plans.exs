defmodule SysFc.Repo.Migrations.CreateTrainingPlans do
  use Ecto.Migration

  def change do
    create table(:training_plans, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :label, :string, null: false
      add :description, :string
      add :frequency, :string
      add :days, {:array, :string}, null: false, default: []
      add :price, :decimal, null: false
      add :is_active, :boolean, null: false, default: true
      add :sort_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:training_plans, [:name])
  end
end
