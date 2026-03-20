defmodule SysFc.Repo.Migrations.CreateMatchEvents do
  use Ecto.Migration

  def change do
    create table(:match_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :match_id, references(:matches, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :team_id, references(:teams, type: :binary_id, on_delete: :restrict), null: false
      add :player_id, references(:players, type: :binary_id, on_delete: :restrict), null: false
      add :minute, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:match_events, [:match_id])
    create index(:match_events, [:team_id])
    create index(:match_events, [:player_id])
  end
end
