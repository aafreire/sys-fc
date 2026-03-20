defmodule SysFc.Repo.Migrations.CreateChampionshipSubs do
  use Ecto.Migration

  def change do
    create table(:championship_subs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :championship_id, references(:championships, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:championship_subs, [:championship_id])
  end
end
