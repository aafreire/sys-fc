defmodule SysFc.Repo.Migrations.CreateRentalFees do
  use Ecto.Migration

  def change do
    create table(:rental_fees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :rental_id, references(:rentals, type: :binary_id, on_delete: :delete_all), null: false
      add :reference_month, :integer
      add :reference_year, :integer
      add :amount, :decimal, null: false, precision: 10, scale: 2
      add :due_date, :date, null: false
      add :payment_date, :date
      add :status, :string, null: false, default: "pending"
      add :receipt_url, :string
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:rental_fees, [:rental_id])
    create index(:rental_fees, [:status])
    create index(:rental_fees, [:reference_year, :reference_month])

    create unique_index(:rental_fees, [:rental_id, :reference_month, :reference_year],
      name: :rental_fees_rental_month_year_unique,
      where: "reference_month IS NOT NULL AND reference_year IS NOT NULL"
    )
  end
end
