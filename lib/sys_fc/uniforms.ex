defmodule SysFc.Uniforms do
  @moduledoc """
  Contexto de pedidos de uniforme.
  Ao criar um pedido, valida o estoque e registra saídas automáticas.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Uniforms.{UniformOrder, UniformOrderItem}
  alias SysFc.Stock
  alias SysFc.Stock.StockExit

  # ── Listagem ──────────────────────────────────────────────

  def list_orders(opts \\ []) do
    UniformOrder
    |> apply_filters(opts)
    |> order_by([o], desc: o.requested_at)
    |> preload([:student, items: :product])
    |> Repo.all()
  end

  def list_orders_by_guardian(guardian_id) do
    UniformOrder
    |> where([o], o.guardian_id == ^guardian_id)
    |> order_by([o], desc: o.requested_at)
    |> preload([:student, items: :product])
    |> Repo.all()
  end

  def get_order(id) do
    UniformOrder
    |> preload([:student, items: :product])
    |> Repo.get(id)
  end

  def get_order!(id) do
    UniformOrder
    |> preload([:student, items: :product])
    |> Repo.get!(id)
  end

  # ── Criação ───────────────────────────────────────────────

  @doc """
  Cria um pedido de uniforme dentro de uma transação:
    1. Valida estoque para todos os itens
    2. Cria o pedido e seus itens
    3. Registra saídas de estoque para cada item
  items = [%{"product_id" => id, "size" => "M", "quantity" => 2, "unit_price" => "75.00"}]
  """
  def create_order(guardian_id, student_id, items) when is_list(items) do
    with :ok <- validate_stock(items) do
      Repo.transaction(fn ->
        total = calculate_total(items)
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        with {:ok, order} <- insert_order(guardian_id, student_id, total, now),
             :ok <- insert_items(order.id, items),
             :ok <- register_stock_exits(items, now) do
          get_order!(order.id)
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  # ── Atualização de status ─────────────────────────────────

  def update_status(%UniformOrder{} = order, status) do
    order
    |> UniformOrder.changeset(%{status: status})
    |> Repo.update()
    |> case do
      {:ok, updated} -> {:ok, Repo.preload(updated, [:student, items: :product])}
      error -> error
    end
  end

  # ── Helpers privados ──────────────────────────────────────

  defp validate_stock(items) do
    insufficient =
      Enum.filter(items, fn item ->
        product_id = item["product_id"] || item[:product_id]
        qty = parse_int(item["quantity"] || item[:quantity])
        available = Stock.current_quantity(product_id)
        qty > available
      end)

    case insufficient do
      [] ->
        :ok

      items ->
        details =
          Enum.map(items, fn item ->
            pid = item["product_id"] || item[:product_id]
            %{product_id: pid, available: Stock.current_quantity(pid)}
          end)

        {:error, {:insufficient_stock, details}}
    end
  end

  defp calculate_total(items) do
    Enum.reduce(items, Decimal.new("0"), fn item, acc ->
      qty = Decimal.new(to_string(item["quantity"] || item[:quantity]))
      price = Decimal.new(to_string(item["unit_price"] || item[:unit_price]))
      Decimal.add(acc, Decimal.mult(qty, price))
    end)
  end

  defp insert_order(guardian_id, student_id, total, now) do
    %UniformOrder{}
    |> UniformOrder.changeset(%{
      guardian_id: guardian_id,
      student_id: student_id,
      total_amount: total,
      status: :pedido_realizado,
      requested_at: now
    })
    |> Repo.insert()
  end

  defp insert_items(order_id, items) do
    Enum.reduce_while(items, :ok, fn item, :ok ->
      result =
        %UniformOrderItem{}
        |> UniformOrderItem.changeset(%{
          uniform_order_id: order_id,
          product_id: item["product_id"] || item[:product_id],
          size: item["size"] || item[:size],
          quantity: parse_int(item["quantity"] || item[:quantity]),
          unit_price: Decimal.new(to_string(item["unit_price"] || item[:unit_price]))
        })
        |> Repo.insert()

      case result do
        {:ok, _} -> {:cont, :ok}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp register_stock_exits(items, now) do
    date = DateTime.to_date(now)

    Enum.reduce_while(items, :ok, fn item, :ok ->
      result =
        %StockExit{}
        |> StockExit.changeset(%{
          product_id: item["product_id"] || item[:product_id],
          quantity: parse_int(item["quantity"] || item[:quantity]),
          date: date,
          notes: "Pedido de uniforme"
        })
        |> Repo.insert()

      case result do
        {:ok, _} -> {:cont, :ok}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, status}, q -> where(q, [o], o.status == ^status)
      {:guardian_id, gid}, q -> where(q, [o], o.guardian_id == ^gid)
      {:student_id, sid}, q -> where(q, [o], o.student_id == ^sid)
      _, q -> q
    end)
  end

  defp parse_int(v) when is_integer(v), do: v
  defp parse_int(v) when is_binary(v), do: String.to_integer(v)
  defp parse_int(_), do: 0
end
