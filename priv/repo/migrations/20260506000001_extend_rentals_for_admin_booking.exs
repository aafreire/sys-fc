defmodule SysFc.Repo.Migrations.ExtendRentalsForAdminBooking do
  use Ecto.Migration

  def change do
    alter table(:rentals) do
      add :court, :string, null: false, default: "court_1"
      add :start_time, :time
      add :end_time, :time

      add :renter_name, :string
      add :renter_email, :string
      add :renter_phone, :string

      add :is_recurring, :boolean, null: false, default: false
      add :recurrence_weekdays, {:array, :integer}, default: []
      add :recurrence_start_date, :date
      add :recurrence_end_date, :date
      add :monthly_amount, :decimal, precision: 10, scale: 2

      add :created_by_admin, :boolean, null: false, default: false
    end

    # guardian_id deixa de ser obrigatório (locação manual pelo admin)
    execute(
      "ALTER TABLE rentals ALTER COLUMN guardian_id DROP NOT NULL",
      "ALTER TABLE rentals ALTER COLUMN guardian_id SET NOT NULL"
    )

    # payment_method deixa de ser obrigatório (admin pode lançar sem)
    execute(
      "ALTER TABLE rentals ALTER COLUMN payment_method DROP NOT NULL",
      "ALTER TABLE rentals ALTER COLUMN payment_method SET NOT NULL"
    )

    # date deixa de ser obrigatório (recorrência usa recurrence_start_date)
    execute(
      "ALTER TABLE rentals ALTER COLUMN date DROP NOT NULL",
      "ALTER TABLE rentals ALTER COLUMN date SET NOT NULL"
    )

    # Substituir índice antigo para considerar a quadra
    execute(
      "DROP INDEX IF EXISTS rentals_date_active",
      "CREATE UNIQUE INDEX rentals_date_active ON rentals (date) WHERE status != 'cancelled'"
    )

    # Nova restrição: 1 reserva ativa por (date, court) — apenas para reservas únicas
    execute(
      """
      CREATE UNIQUE INDEX rentals_date_court_active
      ON rentals (date, court)
      WHERE status != 'cancelled' AND is_recurring = false AND date IS NOT NULL
      """,
      "DROP INDEX IF EXISTS rentals_date_court_active"
    )

    create index(:rentals, [:court])
    create index(:rentals, [:is_recurring])
    create index(:rentals, [:created_by_admin])
  end
end
