defmodule SysFc.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :championship_id, references(:championships, type: :binary_id, on_delete: :delete_all), null: false
      add :championship_sub_id, references(:championship_subs, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :group_id, references(:groups, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:championship_id])
    create index(:teams, [:championship_sub_id])
    create index(:teams, [:group_id])
  end
end
