defmodule SysFc.Repo.Migrations.CreateUnitsAndCourts do
  use Ecto.Migration

  @moduledoc """
  Unidades da escolinha e suas quadras. Cada unidade possui suas próprias
  quadras (ex.: Unidade A → Quadra 1, Quadra 2). Alunos são vinculados a uma
  unidade (ver migration de unit_id em students).
  """

  def change do
    create table(:units, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :is_active, :boolean, null: false, default: true
      add :sort_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:units, [:name])

    create table(:courts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :unit_id, references(:units, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :sort_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:courts, [:unit_id])
    create unique_index(:courts, [:unit_id, :name])
  end
end
