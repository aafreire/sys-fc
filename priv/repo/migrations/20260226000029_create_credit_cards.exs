defmodule SysFc.Repo.Migrations.CreateCreditCards do
  use Ecto.Migration

  def change do
    create table(:credit_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :guardian_id, references(:guardians, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :string, null: false          # token gerado pelo gateway (nunca dados brutos)
      add :brand, :string, null: false          # visa, mastercard, elo, amex, other
      add :last_four, :string, null: false      # últimos 4 dígitos
      add :holder_name, :string, null: false    # nome no cartão
      add :expiry_month, :integer, null: false  # 1..12
      add :expiry_year, :integer, null: false   # ex.: 2028
      add :is_default, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:credit_cards, [:guardian_id])
    create unique_index(:credit_cards, [:token])
  end
end
