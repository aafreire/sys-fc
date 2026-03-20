defmodule SysFc.Repo.Migrations.AddFrozenToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :is_frozen, :boolean, default: false, null: false
    end
  end
end
