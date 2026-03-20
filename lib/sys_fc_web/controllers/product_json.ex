defmodule SysFcWeb.ProductJSON do
  def index(%{products: products}) do
    %{data: Enum.map(products, &product_data/1)}
  end

  def show(%{product: product}) do
    %{data: product_data(product)}
  end

  def entry_created(%{entry: entry, product: product}) do
    %{
      data: %{
        entry: entry_data(entry),
        product: product_data(product)
      }
    }
  end

  def exit_created(%{exit: exit_record, product: product}) do
    %{
      data: %{
        exit: exit_data(exit_record),
        product: product_data(product)
      }
    }
  end

  def history(%{product: product, movements: movements}) do
    %{
      product: product_data(product),
      movements: Enum.map(movements, &movement_data/1)
    }
  end

  defp product_data(product) do
    %{
      id: product.id,
      name: product.name,
      category: product.category,
      discount: product.discount,
      notes: product.notes,
      is_active: product.is_active,
      current_quantity: Map.get(product, :current_quantity, 0),
      cost_price: Map.get(product, :cost_price),
      sale_price: Map.get(product, :sale_price),
      inserted_at: product.inserted_at
    }
  end

  defp entry_data(entry) do
    %{
      id: entry.id,
      product_id: entry.product_id,
      quantity: entry.quantity,
      cost_price: entry.cost_price,
      sale_price: entry.sale_price,
      date: entry.date,
      inserted_at: entry.inserted_at
    }
  end

  defp exit_data(exit_record) do
    %{
      id: exit_record.id,
      product_id: exit_record.product_id,
      quantity: exit_record.quantity,
      date: exit_record.date,
      notes: exit_record.notes,
      inserted_at: exit_record.inserted_at
    }
  end

  defp movement_data(%{movement_type: :entry} = e) do
    %{
      type: :entry,
      id: e.id,
      quantity: e.quantity,
      cost_price: e.cost_price,
      sale_price: e.sale_price,
      date: e.date
    }
  end

  defp movement_data(%{movement_type: :exit} = e) do
    %{
      type: :exit,
      id: e.id,
      quantity: e.quantity,
      date: e.date,
      notes: e.notes
    }
  end
end
