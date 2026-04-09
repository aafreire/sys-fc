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

# ── Segundo administrador master ──────────────────────────────────────────────

admin2_email = System.get_env("ADMIN2_EMAIL", "alan@sysfc.com")
admin2_password = System.get_env("ADMIN2_PASSWORD", "Alan@2026!")
admin2_name = System.get_env("ADMIN2_NAME", "Alan Freire")

case Repo.get_by(User, email: admin2_email) do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      name: admin2_name,
      email: admin2_email,
      password: admin2_password,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin 2 criado com sucesso: #{admin2_email}")

  _user ->
    IO.puts("Admin 2 já existe: #{admin2_email}")
end
