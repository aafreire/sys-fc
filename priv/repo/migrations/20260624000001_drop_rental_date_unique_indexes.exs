defmodule SysFc.Repo.Migrations.DropRentalDateUniqueIndexes do
  use Ecto.Migration

  @moduledoc """
  Remove os índices únicos baseados apenas em data (e data+quadra), que
  impediam mais de uma locação por dia na mesma quadra. O controle de
  conflito passa a ser por sobreposição de horário, feito na camada de
  aplicação (SysFc.Rentals), permitindo horários consecutivos sem
  sobreposição na mesma quadra e horários iguais em quadras diferentes.
  """

  def up do
    execute "DROP INDEX IF EXISTS rentals_date_court_active"
    execute "DROP INDEX IF EXISTS rentals_date_active"
  end

  def down do
    execute "CREATE UNIQUE INDEX rentals_date_active ON rentals (date) WHERE status != 'cancelled'"

    execute """
    CREATE UNIQUE INDEX rentals_date_court_active
    ON rentals (date, court)
    WHERE status != 'cancelled' AND is_recurring = false AND date IS NOT NULL
    """
  end
end
