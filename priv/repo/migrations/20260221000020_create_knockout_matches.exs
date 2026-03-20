defmodule SysFc.Repo.Migrations.CreateKnockoutMatches do
  use Ecto.Migration

  def change do
    create table(:knockout_matches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :championship_id, references(:championships, type: :binary_id, on_delete: :delete_all), null: false
      add :match_id, references(:matches, type: :binary_id, on_delete: :nilify_all)
      add :round, :string, null: false
      add :match_number, :integer, null: false
      add :team1_id, references(:teams, type: :binary_id, on_delete: :nilify_all)
      add :team2_id, references(:teams, type: :binary_id, on_delete: :nilify_all)
      add :winner_id, references(:teams, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:knockout_matches, [:championship_id])
    create index(:knockout_matches, [:match_id])
    create index(:knockout_matches, [:championship_id, :round])
  end
end
