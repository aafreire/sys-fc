defmodule SysFc.Repo.Migrations.CreateRentalUnavailableDates do
  use Ecto.Migration

  def change do
    create table(:rental_unavailable_dates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date, null: false
      add :reason, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rental_unavailable_dates, [:date])
  end
end
