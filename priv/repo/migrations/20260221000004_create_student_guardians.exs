defmodule SysFc.Repo.Migrations.CreateStudentGuardians do
  use Ecto.Migration

  def change do
    create table(:student_guardians, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :student_id, references(:students, type: :binary_id, on_delete: :delete_all), null: false
      add :guardian_id, references(:guardians, type: :binary_id, on_delete: :delete_all), null: false
      add :is_primary, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:student_guardians, [:student_id, :guardian_id])
    create index(:student_guardians, [:student_id])
    create index(:student_guardians, [:guardian_id])
  end
end
