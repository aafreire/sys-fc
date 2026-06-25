defmodule SysFc.Repo.Migrations.AddCourtIdToStudents do
  use Ecto.Migration

  @moduledoc """
  Vínculo opcional do aluno com uma quadra específica da sua unidade.
  Quando nulo, significa "Ambas" (sem quadra específica). Se a quadra for
  removida, o vínculo do aluno é zerado (nilify).
  """

  def change do
    alter table(:students) do
      add :court_id, references(:courts, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:students, [:court_id])
  end
end
