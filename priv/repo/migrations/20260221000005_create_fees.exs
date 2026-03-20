defmodule SysFc.Repo.Migrations.CreateFees do
  use Ecto.Migration

  def change do
    create table(:fees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :student_id, references(:students, type: :binary_id, on_delete: :restrict), null: false
      add :reference_month, :integer, null: false
      add :reference_year, :integer, null: false
      add :amount, :decimal, null: false, precision: 10, scale: 2
      add :due_date, :date, null: false
      add :payment_date, :date
      add :status, :string, null: false, default: "pending"
      add :receipt_url, :string
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:fees, [:student_id, :reference_month, :reference_year])
    create index(:fees, [:student_id])
    create index(:fees, [:status])
    create index(:fees, [:reference_year, :reference_month])
  end
end
