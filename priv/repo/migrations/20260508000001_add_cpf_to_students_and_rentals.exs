defmodule SysFc.Repo.Migrations.AddCpfToStudentsAndRentals do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :cpf, :string
    end

    create unique_index(:students, [:cpf],
      name: :students_cpf_unique,
      where: "cpf IS NOT NULL"
    )

    alter table(:rentals) do
      add :renter_document_type, :string
      add :renter_document, :string
    end
  end
end
