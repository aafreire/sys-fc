defmodule SysFcWeb.FeeJSON do
  def index(%{fees: fees, meta: meta}) do
    %{data: Enum.map(fees, &fee_data/1), meta: meta}
  end

  def index(%{fees: fees}) do
    %{data: Enum.map(fees, &fee_data/1)}
  end

  def show(%{fee: fee}) do
    %{data: fee_data(fee)}
  end

  defp fee_data(fee) do
    %{
      id: fee.id,
      reference_month: fee.reference_month,
      reference_year: fee.reference_year,
      amount: fee.amount,
      due_date: fee.due_date,
      payment_date: fee.payment_date,
      status: fee.status,
      receipt_url: fee.receipt_url,
      notes: fee.notes,
      inserted_at: fee.inserted_at,
      student: student_summary(fee.student)
    }
  end

  defp student_summary(nil), do: nil

  defp student_summary(student) do
    %{
      id: student.id,
      name: student.name,
      enrollment_number: student.enrollment_number,
      category: student.category
    }
  end
end
