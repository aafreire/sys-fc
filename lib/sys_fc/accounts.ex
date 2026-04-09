defmodule SysFc.Accounts do
  @moduledoc """
  Contexto de contas: usuários (admin_master, admin_limited, guardian) e responsáveis.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Accounts.{User, Guardian}

  # ── Usuários ──────────────────────────────────────────────

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc "Retorna o usuário ativo pelo ID. Usado pelo AuthPlug após verificar o JWT."
  def get_active_user(id) do
    case Repo.get(User, id) do
      %User{is_active: true} = user -> {:ok, user}
      %User{is_active: false} -> {:error, :inactive}
      nil -> {:error, :not_found}
    end
  end

  @doc "Autentica usuário por email e senha. Retorna {:ok, user} ou {:error, reason}."
  def authenticate(email, password) do
    user = get_user_by_email(email)

    cond do
      is_nil(user) ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      not user.is_active ->
        {:error, :inactive}

      not User.valid_password?(user, password) ->
        {:error, :invalid_credentials}

      true ->
        {:ok, user}
    end
  end

  @doc "Autentica responsável por telefone e senha. Retorna {:ok, user} ou {:error, reason}."
  def authenticate_by_phone(phone, password) do
    guardian = find_guardian_by_phone(phone)

    cond do
      is_nil(guardian) ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      not guardian.user.is_active ->
        {:error, :inactive}

      is_nil(guardian.user.password_hash) ->
        {:error, :no_password}

      not User.valid_password?(guardian.user, password) ->
        {:error, :invalid_credentials}

      true ->
        {:ok, guardian.user}
    end
  end

  @doc "Cria um admin (admin_limited). Apenas admin_master pode chamar."
  def create_admin(attrs) do
    attrs = Map.put(attrs, "role", "admin_limited")

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Registra um responsável completo: User com e-mail + senha + Guardian."
  def register_guardian(attrs) do
    Repo.transaction(fn ->
      with {:ok, user} <- create_user(Map.put(attrs, "role", "guardian")),
           {:ok, guardian} <- create_guardian(%{
             user_id: user.id,
             cpf: attrs["cpf"] || attrs[:cpf],
             phone: attrs["phone"] || attrs[:phone]
           }) do
        %{user: user, guardian: guardian}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Cria um responsável pelo admin.
  Telefone obrigatório. E-mail e senha opcionais.
  Se e-mail/senha fornecidos, cria conta completa; caso contrário cria stub.
  """
  def create_guardian_by_admin(attrs) do
    has_email = not is_nil_or_empty(attrs["email"] || attrs[:email])
    has_password = not is_nil_or_empty(attrs["password"] || attrs[:password])

    Repo.transaction(fn ->
      user_attrs = Map.merge(attrs, %{"role" => "guardian"})

      user_changeset =
        if has_email and has_password do
          User.registration_changeset(%User{}, user_attrs)
        else
          User.guardian_stub_changeset(%User{}, user_attrs)
        end

      with {:ok, user} <- Repo.insert(user_changeset),
           {:ok, guardian} <- create_guardian_admin(%{
             user_id: user.id,
             cpf: attrs["cpf"] || attrs[:cpf],
             phone: attrs["phone"] || attrs[:phone]
           }) do
        guardian = Repo.preload(guardian, :user)
        %{user: user, guardian: guardian}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc "Busca responsável pelo telefone (stripped, sem formatação)."
  def find_guardian_by_phone(phone) when is_binary(phone) do
    stripped = String.replace(phone, ~r/\D/, "")

    Guardian
    |> where([g], g.phone == ^stripped)
    |> preload(:user)
    |> Repo.one()
  end

  @doc """
  Completa o cadastro de um responsável que foi criado sem e-mail/senha.
  Vincula o e-mail e define a senha.
  """
  def complete_guardian_account(%Guardian{} = guardian, email, password) do
    user = Repo.preload(guardian, :user).user

    case Repo.update(User.complete_account_changeset(user, %{email: email, password: password})) do
      {:ok, updated_user} ->
        {:ok, %{user: updated_user, guardian: guardian}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def create_guardian(attrs) do
    %Guardian{}
    |> Guardian.changeset(attrs)
    |> Repo.insert()
  end

  defp create_guardian_admin(attrs) do
    %Guardian{}
    |> Guardian.admin_create_changeset(attrs)
    |> Repo.insert()
  end

  defp is_nil_or_empty(nil), do: true
  defp is_nil_or_empty(""), do: true
  defp is_nil_or_empty(_), do: false

  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_password(%User{} = user, new_password) do
    user
    |> User.registration_changeset(%{
      name: user.name,
      email: user.email,
      password: new_password,
      role: to_string(user.role)
    })
    |> Repo.update()
  end

  @doc "Lista todos os admins (master e limited)."
  def list_admins(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      User
      |> where([u], u.role in [:admin_master, :admin_limited])

    total = Repo.aggregate(base_query, :count)

    admins =
      base_query
      |> order_by([u], asc: u.inserted_at)
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> Repo.all()

    %{data: admins, meta: %{page: page, per_page: per_page, total: total}}
  end

  @doc "Ativa/desativa um admin. Protege admin_master de ser desativado."
  def toggle_admin_status(%User{role: :admin_master}),
    do: {:error, :cannot_deactivate_master}

  def toggle_admin_status(%User{} = user) do
    update_user(user, %{is_active: !user.is_active})
  end

  # ── Responsáveis ──────────────────────────────────────────

  def update_guardian_cpf(%Guardian{} = guardian, cpf) when is_binary(cpf) do
    guardian
    |> Guardian.changeset(%{cpf: cpf})
    |> Repo.update()
  end

  def get_guardian_by_user_id(user_id) do
    Repo.get_by(Guardian, user_id: user_id)
  end

  def get_guardian!(id), do: Repo.get!(Guardian, id)

  def list_guardians(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)

    base_query =
      Guardian
      |> join(:inner, [g], u in assoc(g, :user))
      |> where([_g, u], u.is_active == true)

    total = Repo.aggregate(base_query, :count)

    guardians =
      base_query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> preload(:user)
      |> Repo.all()

    %{data: guardians, meta: %{page: page, per_page: per_page, total: total}}
  end
end
