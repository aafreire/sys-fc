defmodule SysFc.Repo.Migrations.AddUniqueIndexOnStudentRg do
  use Ecto.Migration

  def change do
    create unique_index(:students, [:rg], where: "rg IS NOT NULL AND rg != ''", name: :students_rg_unique)
  end
end
