defmodule SysFc.Repo.Migrations.AddStatusToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :status, :string, null: false, default: "active"
    end

    create index(:students, [:status])
  end
end
