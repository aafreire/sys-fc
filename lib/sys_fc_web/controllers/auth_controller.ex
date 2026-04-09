defmodule SysFcWeb.AuthController do
  use SysFcWeb, :controller

  alias SysFc.Accounts
  alias SysFc.Auth.Token

  # POST /api/auth/login (por e-mail)
  def login(conn, %{"email" => email, "password" => password}) when is_binary(email) and email != "" do
    handle_login_result(conn, Accounts.authenticate(email, password))
  end

  # POST /api/auth/login (por telefone — responsáveis)
  def login(conn, %{"phone" => phone, "password" => password}) when is_binary(phone) and phone != "" do
    handle_login_result(conn, Accounts.authenticate_by_phone(phone, password))
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "email or phone, and password are required"})
  end

  defp handle_login_result(conn, {:ok, user}) do
    {:ok, token, _claims} = Token.generate(user)
    guardian = Accounts.get_guardian_by_user_id(user.id)

    conn
    |> put_status(:ok)
    |> render(:login, user: user, token: token, guardian: guardian)
  end

  defp handle_login_result(conn, {:error, :invalid_credentials}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "invalid_credentials"})
  end

  defp handle_login_result(conn, {:error, :no_password}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "no_password"})
  end

  defp handle_login_result(conn, {:error, :inactive}) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "account_inactive"})
  end

  # POST /api/auth/register
  def register(conn, params) do
    attrs = %{
      "name" => params["name"],
      "email" => params["email"],
      "password" => params["password"],
      "cpf" => params["cpf"],
      "phone" => params["phone"]
    }

    case Accounts.register_guardian(attrs) do
      {:ok, %{user: user, guardian: guardian}} ->
        {:ok, token, _claims} = Token.generate(user)

        conn
        |> put_status(:created)
        |> render(:register, user: user, token: token, guardian: guardian)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # GET /api/auth/me
  def me(conn, _params) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    conn
    |> put_status(:ok)
    |> render(:me, user: user, guardian: guardian)
  end

  # POST /api/auth/logout
  # JWT é stateless — o logout é gerenciado no cliente descartando o token.
  # Em produção, implemente uma blocklist se necessário.
  def logout(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{message: "logged out"})
  end

  # GET /api/auth/check-phone?phone=11987654321
  # Verifica se já existe responsável com aquele telefone (para fluxo de cadastro)
  def check_phone(conn, %{"phone" => phone}) do
    case Accounts.find_guardian_by_phone(phone) do
      nil ->
        conn |> put_status(:ok) |> json(%{exists: false})

      guardian ->
        has_email = not is_nil(guardian.user.email)
        has_password = not is_nil(guardian.user.password_hash)
        has_account = has_email and has_password

        base = %{
          exists: true,
          has_account: has_account,
          guardian_id: guardian.id,
          name: guardian.user.name
        }

        base =
          if not has_account do
            missing = []
            missing = if not has_email, do: ["email" | missing], else: missing
            missing = if is_nil(guardian.cpf) or guardian.cpf == "", do: ["cpf" | missing], else: missing
            missing = if not has_password, do: ["password" | missing], else: missing
            Map.put(base, :missing_fields, missing)
          else
            base
          end

        conn
        |> put_status(:ok)
        |> json(base)
    end
  end

  def check_phone(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "phone is required"})
  end

  # POST /api/auth/complete-registration
  # Responsável que foi pré-cadastrado pelo admin completa sua conta (e-mail + senha + cpf opcional)
  def complete_registration(conn, %{"phone" => phone, "password" => password} = params) do
    email = params["email"]
    case Accounts.find_guardian_by_phone(phone) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "phone_not_found"})

      guardian ->
        has_email = not is_nil(guardian.user.email)
        has_password = not is_nil(guardian.user.password_hash)

        if has_email and has_password do
          conn |> put_status(:unprocessable_entity) |> json(%{error: "account_already_complete"})
        else
          # Update CPF if provided and not already set
          cpf = params["cpf"]
          if cpf && (is_nil(guardian.cpf) || guardian.cpf == "") do
            Accounts.update_guardian_cpf(guardian, cpf)
          end

          # Use existing email if already set, otherwise use the provided one
          final_email = if has_email, do: guardian.user.email, else: email

          case Accounts.complete_guardian_account(guardian, final_email, password) do
            {:ok, %{user: user, guardian: g}} ->
              {:ok, token, _claims} = Token.generate(user)

              conn
              |> put_status(:ok)
              |> render(:login, user: user, token: token, guardian: g)

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "validation_failed", details: format_errors(changeset)})
          end
        end
    end
  end

  def complete_registration(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "phone and password are required"})
  end

  # POST /api/auth/forgot-password
  def forgot_password(conn, %{"email" => email}) do
    # Sempre retorna 200 para não revelar se o email existe
    case Accounts.get_user_by_email(email) do
      nil ->
        conn |> put_status(:ok) |> json(%{message: "if the email exists, a reset link was sent"})

      user ->
        {:ok, reset_token} = Token.generate_reset(user)

        # Em produção: enviar email com o link. Em dev: retorna o token na response.
        # TODO: integrar com serviço de email (ex: Swoosh)
        conn
        |> put_status(:ok)
        |> json(%{
          message: "if the email exists, a reset link was sent",
          # Remover em produção — apenas para facilitar desenvolvimento
          debug_reset_token: reset_token
        })
    end
  end

  def forgot_password(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "email is required"})
  end

  # POST /api/auth/reset-password
  def reset_password(conn, %{"token" => token, "password" => password}) do
    case Token.verify_reset(token) do
      {:ok, user_id} ->
        user = Accounts.get_user!(user_id)

        case Accounts.update_password(user, password) do
          {:ok, _user} ->
            conn |> put_status(:ok) |> json(%{message: "password updated successfully"})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_or_expired_token"})
    end
  end

  def reset_password(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "token and password are required"})
  end

  # ── Helpers ───────────────────────────────────────────────

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
