defmodule SysFc.Repo.Migrations.CreatePenaltyShootouts do
  use Ecto.Migration

  def change do
    create table(:penalty_shootouts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :match_id, references(:matches, type: :binary_id, on_delete: :delete_all), null: false
      add :home_team_score, :integer, null: false, default: 0
      add :away_team_score, :integer, null: false, default: 0
      add :finished, :boolean, null: false, default: false
      add :winner_team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:penalty_shootouts, [:match_id])
    create index(:penalty_shootouts, [:winner_team_id])
  end
end
