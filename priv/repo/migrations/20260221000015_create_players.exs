defmodule SysFc.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false
      add :student_id, references(:students, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :jersey_number, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:players, [:team_id])
    create index(:players, [:student_id])
  end
end
