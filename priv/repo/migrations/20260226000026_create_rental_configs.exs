defmodule SysFc.Repo.Migrations.CreateRentalConfigs do
  use Ecto.Migration

  def change do
    create table(:rental_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :price_per_hour, :decimal
      add :price_per_day, :decimal
      add :price_flat, :decimal
      add :description, :string

      timestamps(type: :utc_datetime)
    end
  end
end
