defmodule SysFc.Repo.Migrations.CreateGuardians do
  use Ecto.Migration

  def change do
    create table(:guardians, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :cpf, :string, null: false
      add :phone, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:guardians, [:user_id])
    create unique_index(:guardians, [:cpf])
  end
end
