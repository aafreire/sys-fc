defmodule SysFc.Repo.Migrations.MakeUserEmailOptional do
  use Ecto.Migration

  def change do
    # Permite criar usuário (responsável) sem e-mail e sem senha
    # (criado pelo admin apenas com nome + telefone)
    alter table(:users) do
      modify :email, :string, null: true
      modify :password_hash, :string, null: true
    end

    # Recriar índice único de e-mail como PARTIAL (ignora NULLs)
    drop_if_exists unique_index(:users, [:email])
    execute(
      "CREATE UNIQUE INDEX users_email_index ON users (email) WHERE email IS NOT NULL",
      "DROP INDEX IF EXISTS users_email_index"
    )

    # CPF do responsável também passa a ser opcional (nem sempre disponível no ato)
    alter table(:guardians) do
      modify :cpf, :string, null: true
    end

    # Índice único parcial para telefone (quando informado, deve ser único)
    execute(
      "CREATE UNIQUE INDEX guardians_phone_index ON guardians (phone) WHERE phone IS NOT NULL AND phone <> ''",
      "DROP INDEX IF EXISTS guardians_phone_index"
    )
  end
end
