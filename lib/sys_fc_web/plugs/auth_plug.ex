defmodule SysFcWeb.Plugs.AuthPlug do
  @moduledoc """
  Plug de autenticação. Verifica o Bearer JWT no header Authorization,
  valida o token e injeta o usuário em conn.assigns[:current_user].
  Retorna 401 se o token for inválido ou ausente.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias SysFc.Auth.Token
  alias SysFc.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Token.verify_token(token),
         {:ok, user} <- Accounts.get_active_user(claims["user_id"]) do
      conn
      |> assign(:current_user, user)
      |> assign(:current_claims, claims)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
        |> halt()
    end
  end
end
