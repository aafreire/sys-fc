defmodule SysFc.Repo.Migrations.AddBillingDayToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :billing_day, :integer, default: 10, null: false
    end
  end
end
