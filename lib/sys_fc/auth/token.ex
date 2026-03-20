defmodule SysFc.Auth.Token do
  @moduledoc """
  Geração e verificação de tokens JWT usando Joken.
  Claims: user_id, role, iss, exp, iat.
  """
  use Joken.Config

  @impl true
  def token_config do
    expiry = Application.get_env(:sys_fc, :jwt_expiry_seconds, 604_800)

    default_claims(
      iss: "sys_fc",
      default_exp: expiry,
      skip: [:aud]
    )
    |> add_claim("user_id", nil, &is_binary/1)
    |> add_claim("role", nil, &is_binary/1)
  end

  @doc "Gera um JWT para o usuário autenticado."
  def generate(user) do
    extra_claims = %{
      "user_id" => user.id,
      "role" => to_string(user.role)
    }

    case generate_and_sign(extra_claims, signer()) do
      {:ok, token, claims} -> {:ok, token, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Verifica e valida um JWT, retornando os claims."
  def verify_token(token) do
    case verify_and_validate(token, signer()) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Gera um token de reset de senha (expiração curta: 1h)."
  def generate_reset(user) do
    extra_claims = %{
      "user_id" => user.id,
      "purpose" => "password_reset"
    }

    short_signer = Joken.Signer.create("HS256", secret())

    token_config =
      default_claims(iss: "sys_fc", default_exp: 3600, skip: [:aud])
      |> add_claim("user_id", nil, &is_binary/1)
      |> add_claim("purpose", nil, &(&1 == "password_reset"))

    case Joken.generate_and_sign(token_config, extra_claims, short_signer) do
      {:ok, token, _} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Verifica um token de reset de senha."
  def verify_reset(token) do
    short_signer = Joken.Signer.create("HS256", secret())

    token_config =
      default_claims(iss: "sys_fc", default_exp: 3600, skip: [:aud])
      |> add_claim("user_id", nil, &is_binary/1)
      |> add_claim("purpose", nil, &(&1 == "password_reset"))

    case Joken.verify_and_validate(token_config, token, short_signer) do
      {:ok, %{"user_id" => uid, "purpose" => "password_reset"}} -> {:ok, uid}
      _ -> {:error, :invalid_reset_token}
    end
  end

  defp signer, do: Joken.Signer.create("HS256", secret())

  defp secret, do: Application.fetch_env!(:sys_fc, :jwt_secret)
end
