defmodule SysFc.Repo.Migrations.AddComplementToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :complement, :string
    end
  end
end
