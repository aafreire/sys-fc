defmodule SysFc.Repo.Migrations.CreateRentals do
  use Ecto.Migration

  def change do
    create table(:rentals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guardian_id, references(:guardians, type: :binary_id, on_delete: :restrict), null: false
      add :date, :date, null: false
      add :hours, :integer
      add :pricing_type, :string, null: false
      add :amount, :decimal, null: false
      add :payment_method, :string, null: false
      add :status, :string, null: false, default: "requested"
      add :notes, :string

      timestamps(type: :utc_datetime)
    end

    create index(:rentals, [:guardian_id])
    create index(:rentals, [:date])

    # Apenas uma reserva ativa por dia (cancelladas não contam)
    execute(
      "CREATE UNIQUE INDEX rentals_date_active ON rentals (date) WHERE status != 'cancelled'",
      "DROP INDEX IF EXISTS rentals_date_active"
    )
  end
end
