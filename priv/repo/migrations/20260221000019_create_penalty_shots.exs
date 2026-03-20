defmodule SysFc.Repo.Migrations.CreatePenaltyShots do
  use Ecto.Migration

  def change do
    create table(:penalty_shots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :penalty_shootout_id, references(:penalty_shootouts, type: :binary_id, on_delete: :delete_all), null: false
      add :player_id, references(:players, type: :binary_id, on_delete: :restrict), null: false
      add :team_id, references(:teams, type: :binary_id, on_delete: :restrict), null: false
      add :scored, :boolean, null: false
      add :order, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:penalty_shots, [:penalty_shootout_id])
    create index(:penalty_shots, [:player_id])
    create index(:penalty_shots, [:team_id])
  end
end
