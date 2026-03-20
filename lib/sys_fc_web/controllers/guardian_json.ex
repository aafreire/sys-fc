defmodule SysFcWeb.GuardianJSON do
  def index(%{guardians: guardians, meta: meta}) do
    %{data: Enum.map(guardians, &guardian_data/1), meta: meta}
  end

  def index(%{guardians: guardians}) do
    %{data: Enum.map(guardians, &guardian_data/1)}
  end

  def show(%{guardian: guardian}) do
    %{data: guardian_data(guardian)}
  end

  defp guardian_data(guardian) do
    %{
      id: guardian.id,
      cpf: format_cpf(guardian.cpf),
      phone: format_phone(guardian.phone),
      inserted_at: guardian.inserted_at,
      user: %{
        id: guardian.user.id,
        name: guardian.user.name,
        email: guardian.user.email,
        is_active: guardian.user.is_active
      }
    }
  end

  # "00000000000" → "000.000.000-00"
  defp format_cpf(nil), do: nil
  defp format_cpf(cpf) when byte_size(cpf) == 11 do
    String.slice(cpf, 0, 3) <> "." <>
    String.slice(cpf, 3, 3) <> "." <>
    String.slice(cpf, 6, 3) <> "-" <>
    String.slice(cpf, 9, 2)
  end
  defp format_cpf(cpf), do: cpf

  # "11987654321" → "(11) 98765-4321"  ou  "1134567890" → "(11) 3456-7890"
  defp format_phone(nil), do: nil
  defp format_phone(phone) when byte_size(phone) == 11 do
    "(#{String.slice(phone, 0, 2)}) #{String.slice(phone, 2, 5)}-#{String.slice(phone, 7, 4)}"
  end
  defp format_phone(phone) when byte_size(phone) == 10 do
    "(#{String.slice(phone, 0, 2)}) #{String.slice(phone, 2, 4)}-#{String.slice(phone, 6, 4)}"
  end
  defp format_phone(phone), do: phone
end
