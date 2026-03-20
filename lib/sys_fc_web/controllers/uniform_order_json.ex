defmodule SysFcWeb.UniformOrderJSON do
  def index(%{orders: orders}) do
    %{data: Enum.map(orders, &order_data/1)}
  end

  def show(%{order: order}) do
    %{data: order_data(order)}
  end

  defp order_data(order) do
    %{
      id: order.id,
      guardian_id: order.guardian_id,
      total_amount: order.total_amount,
      status: order.status,
      requested_at: order.requested_at,
      inserted_at: order.inserted_at,
      student: student_summary(order.student),
      items: items_data(order.items)
    }
  end

  defp student_summary(nil), do: nil
  defp student_summary(s), do: %{id: s.id, name: s.name, enrollment_number: s.enrollment_number}

  defp items_data(items) when is_list(items) do
    Enum.map(items, fn item ->
      %{
        id: item.id,
        size: item.size,
        quantity: item.quantity,
        unit_price: item.unit_price,
        subtotal: Decimal.mult(Decimal.new(to_string(item.quantity)), item.unit_price),
        product: %{
          id: item.product.id,
          name: item.product.name,
          category: item.product.category
        }
      }
    end)
  end

  defp items_data(_), do: []
end
