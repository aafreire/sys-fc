defmodule SysFc.Repo.Migrations.CreateUniformOrders do
  use Ecto.Migration

  def change do
    create table(:uniform_orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guardian_id, references(:guardians, type: :binary_id, on_delete: :restrict), null: false
      add :student_id, references(:students, type: :binary_id, on_delete: :restrict), null: false
      add :total_amount, :decimal, null: false, precision: 10, scale: 2
      add :status, :string, null: false, default: "pedido_realizado"
      add :requested_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:uniform_orders, [:guardian_id])
    create index(:uniform_orders, [:student_id])
    create index(:uniform_orders, [:status])
  end
end
