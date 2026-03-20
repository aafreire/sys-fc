defmodule SysFcWeb.AuthJSON do
  @doc "Response do login e register"
  def login(%{user: user, token: token, guardian: guardian}) do
    %{
      token: token,
      user: user_data(user, guardian)
    }
  end

  def register(%{user: user, token: token, guardian: guardian}) do
    %{
      token: token,
      user: user_data(user, guardian)
    }
  end

  def me(%{user: user, guardian: guardian}) do
    %{user: user_data(user, guardian)}
  end

  defp user_data(user, guardian) do
    base = %{
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      is_active: user.is_active,
      inserted_at: user.inserted_at
    }

    if guardian do
      Map.merge(base, %{
        guardian_id: guardian.id,
        cpf: guardian.cpf,
        phone: guardian.phone
      })
    else
      base
    end
  end
end
