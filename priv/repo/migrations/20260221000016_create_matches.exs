defmodule SysFc.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :championship_id, references(:championships, type: :binary_id, on_delete: :delete_all), null: false
      add :home_team_id, references(:teams, type: :binary_id, on_delete: :restrict), null: false
      add :away_team_id, references(:teams, type: :binary_id, on_delete: :restrict), null: false
      add :home_score, :integer, null: false, default: 0
      add :away_score, :integer, null: false, default: 0
      add :date, :date
      add :time, :time
      add :location, :string
      add :status, :string, null: false, default: "not_started"
      add :phase, :string, null: false, default: "group_stage"
      add :group_id, references(:groups, type: :binary_id, on_delete: :nilify_all)
      add :knockout_round, :string
      add :match_number, :integer
      add :total_duration, :integer
      add :first_half_injury_time, :integer, null: false, default: 0
      add :second_half_injury_time, :integer, null: false, default: 0
      add :locked, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:matches, [:championship_id])
    create index(:matches, [:championship_id, :phase, :status])
    create index(:matches, [:home_team_id])
    create index(:matches, [:away_team_id])
    create index(:matches, [:group_id])
  end
end
