defmodule SysFc.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :championship_id, references(:championships, type: :binary_id, on_delete: :delete_all), null: false
      add :championship_sub_id, references(:championship_subs, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:groups, [:championship_id])
    create index(:groups, [:championship_sub_id])
  end
end
