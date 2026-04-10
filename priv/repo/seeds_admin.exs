alias SysFc.Repo
alias SysFc.Accounts.User

# ── Admin 1 (telefone: 11983534144) ──────────────────────────────────────────

admin1_phone = "11983534144"
admin1_name = case System.get_env("ADMIN_NAME") do
  nil -> "Administrador 1"
  "" -> "Administrador 1"
  name -> name
end

case Repo.get_by(User, phone: admin1_phone) do
  nil ->
    %User{}
    |> User.admin_stub_changeset(%{
      name: admin1_name,
      phone: admin1_phone,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin 1 criado com sucesso: #{admin1_phone}")

  _user ->
    IO.puts("Admin 1 já existe: #{admin1_phone}")
end

# ── Admin 2 (telefone: 11982254843) ──────────────────────────────────────────

admin2_phone = "11982254843"
admin2_name = case System.get_env("ADMIN2_NAME") do
  nil -> "Administrador 2"
  "" -> "Administrador 2"
  name -> name
end

case Repo.get_by(User, phone: admin2_phone) do
  nil ->
    %User{}
    |> User.admin_stub_changeset(%{
      name: admin2_name,
      phone: admin2_phone,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin 2 criado com sucesso: #{admin2_phone}")

  _user ->
    IO.puts("Admin 2 já existe: #{admin2_phone}")
end

# ── Admin 3 (telefone: 11983534145) ──────────────────────────────────────────

admin3_phone = "11983534145"

case Repo.get_by(User, phone: admin3_phone) do
  nil ->
    %User{}
    |> User.admin_stub_changeset(%{
      name: "Administrador 3",
      phone: admin3_phone,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin 3 criado com sucesso: #{admin3_phone}")

  _user ->
    IO.puts("Admin 3 já existe: #{admin3_phone}")
end

# ── Admin 4 (telefone: 11983534146) ──────────────────────────────────────────

admin4_phone = "11983534146"

case Repo.get_by(User, phone: admin4_phone) do
  nil ->
    %User{}
    |> User.admin_stub_changeset(%{
      name: "Administrador 4",
      phone: admin4_phone,
      role: :admin_master
    })
    |> Repo.insert!()

    IO.puts("Admin 4 criado com sucesso: #{admin4_phone}")

  _user ->
    IO.puts("Admin 4 já existe: #{admin4_phone}")
end
