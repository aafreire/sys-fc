defmodule SysFcWeb.StudentJSON do
  def index(%{students: students, meta: meta}) do
    %{data: Enum.map(students, &student_data/1), meta: meta}
  end

  def index(%{students: students}) do
    %{data: Enum.map(students, &student_data/1)}
  end

  def show(%{student: student}) do
    %{data: student_data(student)}
  end

  defp student_data(student) do
    %{
      id: student.id,
      enrollment_number: student.enrollment_number,
      name: student.name,
      birth_date: student.birth_date,
      category: student.category,
      photo_url: student.photo_url,
      rg: student.rg,
      school_name: student.school_name,
      address: student.address,
      address_number: student.address_number,
      neighborhood: student.neighborhood,
      city: student.city,
      cep: format_cep(student.cep),
      training_days: student.training_days,
      training_plan: student.training_plan,
      training_location: student.training_location,
      has_health_plan: student.has_health_plan,
      health_plan_name: student.health_plan_name,
      monthly_fee: student.monthly_fee,
      billing_day: student.billing_day,
      is_active: student.is_active,
      is_frozen: student.is_frozen,
      status: student.status,
      inserted_at: student.inserted_at,
      guardians: guardian_list(student)
    }
  end

  defp guardian_list(%{student_guardians: sgs}) when is_list(sgs) do
    Enum.map(sgs, fn sg ->
      %{
        guardian_id: sg.guardian_id,
        is_primary: sg.is_primary,
        name: sg.guardian.user.name,
        email: sg.guardian.user.email,
        cpf: format_cpf(sg.guardian.cpf),
        phone: format_phone(sg.guardian.phone)
      }
    end)
  end

  defp guardian_list(_), do: []

  defp format_cep(nil), do: nil
  defp format_cep(cep) when byte_size(cep) == 8 do
    String.slice(cep, 0, 5) <> "-" <> String.slice(cep, 5, 3)
  end
  defp format_cep(cep), do: cep

  defp format_cpf(nil), do: nil
  defp format_cpf(cpf) when byte_size(cpf) == 11 do
    String.slice(cpf, 0, 3) <> "." <>
    String.slice(cpf, 3, 3) <> "." <>
    String.slice(cpf, 6, 3) <> "-" <>
    String.slice(cpf, 9, 2)
  end
  defp format_cpf(cpf), do: cpf

  defp format_phone(nil), do: nil
  defp format_phone(phone) when byte_size(phone) == 11 do
    "(#{String.slice(phone, 0, 2)}) #{String.slice(phone, 2, 5)}-#{String.slice(phone, 7, 4)}"
  end
  defp format_phone(phone) when byte_size(phone) == 10 do
    "(#{String.slice(phone, 0, 2)}) #{String.slice(phone, 2, 4)}-#{String.slice(phone, 6, 4)}"
  end
  defp format_phone(phone), do: phone
end
