defmodule SysFcWeb.UserJSON do
  def index(%{users: users}) do
    %{data: Enum.map(users, &user_data/1)}
  end

  def show(%{user: user}) do
    %{data: user_data(user)}
  end

  defp user_data(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      is_active: user.is_active,
      inserted_at: user.inserted_at
    }
  end
end
