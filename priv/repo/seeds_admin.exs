alias SysFc.Repo
alias SysFc.Accounts.User

admin_email = System.get_env("ADMIN_EMAIL", "admin@sysfc.com")
admin_password = System.get_env("ADMIN_PASSWORD", "Admin@2026!")
admin_name = System.get_env("ADMIN_NAME", "Administrador")

case Repo.get_by(User, email: admin_email) do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      name: admin_name,
      email: admin_email,
      password: admin_password,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin criado com sucesso: #{admin_email}")

  _user ->
    IO.puts("Admin já existe: #{admin_email}")
end
