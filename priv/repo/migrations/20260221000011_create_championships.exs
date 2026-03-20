defmodule SysFc.Repo.Migrations.CreateChampionships do
  use Ecto.Migration

  def change do
    create table(:championships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false, default: "upcoming"
      add :phase, :string, null: false, default: "group_stage"
      add :format, :string, null: false, default: "groups_and_knockout"
      add :start_date, :date, null: false
      add :end_date, :date
      add :default_match_duration, :integer, null: false, default: 30

      timestamps(type: :utc_datetime)
    end

    create index(:championships, [:status])
  end
end
