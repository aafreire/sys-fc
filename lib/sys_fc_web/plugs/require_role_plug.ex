defmodule SysFcWeb.Plugs.RequireRolePlug do
  @moduledoc """
  Plug de autorização por role.
  Uso no router: plug SysFcWeb.Plugs.RequireRolePlug, [:admin_master]
  Requer que AuthPlug já tenha injetado :current_user em conn.assigns.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(roles) when is_list(roles), do: roles

  def call(conn, allowed_roles) do
    user = conn.assigns[:current_user]
    role_atoms = Enum.map(allowed_roles, fn
      r when is_atom(r) -> r
      r when is_binary(r) -> String.to_existing_atom(r)
    end)

    if user && user.role in role_atoms do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "forbidden"})
      |> halt()
    end
  end
end
