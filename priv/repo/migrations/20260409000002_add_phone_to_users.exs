defmodule SysFc.Repo.Migrations.AddPhoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone, :string
    end

    create unique_index(:users, [:phone], where: "phone IS NOT NULL AND phone != ''", name: :users_phone_unique)
  end
end
