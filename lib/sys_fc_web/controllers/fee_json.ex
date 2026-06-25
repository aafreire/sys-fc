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

  def overview(%{overview: o}) do
    %{
      data: %{
        month: o.month,
        year: o.year,
        students: money_group(o.students),
        rentals: money_group(o.rentals),
        expenses: %{
          total: dec(o.expenses.total),
          paid: dec(o.expenses.paid),
          unpaid: dec(o.expenses.unpaid)
        },
        totals: %{
          total_received: dec(o.totals.total_received),
          total_to_receive: dec(o.totals.total_to_receive),
          total_overdue: dec(o.totals.total_overdue),
          total_expenses: dec(o.totals.total_expenses),
          net_revenue: dec(o.totals.net_revenue)
        }
      }
    }
  end

  defp money_group(g) do
    %{
      received: dec(g.received),
      pending: dec(g.pending),
      overdue: dec(g.overdue),
      to_receive: dec(g.to_receive),
      total: dec(g.total)
    }
  end

  defp dec(%Decimal{} = d), do: Decimal.to_string(d)
  defp dec(other), do: to_string(other)

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
