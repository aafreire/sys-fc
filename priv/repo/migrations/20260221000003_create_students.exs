defmodule SysFc.Repo.Migrations.CreateStudents do
  use Ecto.Migration

  def change do
    create table(:students, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :enrollment_number, :string, null: false
      add :name, :string, null: false
      add :birth_date, :date, null: false
      add :category, :string, null: false
      add :photo_url, :string
      add :rg, :string
      add :school_name, :string
      add :address, :string
      add :address_number, :string
      add :neighborhood, :string
      add :city, :string
      add :cep, :string
      add :training_days, {:array, :string}, default: []
      add :training_plan, :string
      add :training_location, :string
      add :has_health_plan, :boolean, default: false
      add :health_plan_name, :string
      add :monthly_fee, :decimal, null: false, precision: 10, scale: 2
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:students, [:enrollment_number])
    create index(:students, [:category])
    create index(:students, [:is_active])
  end
end
