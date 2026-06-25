defmodule SysFc.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  @moduledoc """
  Despesas da escolinha. Cada linha representa a ocorrência de uma despesa
  em um mês de referência específico. Despesas recorrentes compartilham um
  `recurrence_id`; `recurrence_total` define por quantos meses se repete
  (NULL = recorrência por tempo indeterminado).
  """

  def change do
    create table(:expenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :amount, :decimal, null: false, precision: 10, scale: 2
      add :status, :string, null: false, default: "unpaid"
      add :reference_month, :integer, null: false
      add :reference_year, :integer, null: false
      add :is_recurring, :boolean, null: false, default: false
      add :recurrence_id, :binary_id
      add :recurrence_total, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:expenses, [:reference_year, :reference_month])
    create index(:expenses, [:status])
    create index(:expenses, [:recurrence_id])

    # Evita ocorrências duplicadas de uma mesma série recorrente no mesmo mês.
    # Linhas avulsas têm recurrence_id NULL e nunca colidem (NULLs distintos no Postgres).
    create unique_index(:expenses, [:recurrence_id, :reference_year, :reference_month])
  end
end
