defmodule SysFc.Repo.Migrations.AddUnitIdToStudents do
  use Ecto.Migration

  @moduledoc """
  Vincula cada aluno a uma unidade. Opcional: alunos legados podem não ter
  unidade. Se a unidade for removida, o vínculo do aluno é zerado (nilify).
  """

  def change do
    alter table(:students) do
      add :unit_id, references(:units, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:students, [:unit_id])
  end
end
