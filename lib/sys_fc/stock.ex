defmodule SysFc.Stock do
  @moduledoc """
  Contexto de estoque: produtos, entradas, saídas e cálculo de quantidade atual.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Stock.{Product, StockEntry, StockExit}

  # ── Produtos ──────────────────────────────────────────────

  def list_products(opts \\ []) do
    Product
    |> apply_product_filters(opts)
    |> order_by([p], asc: p.name)
    |> Repo.all()
    |> Enum.map(&with_current_quantity/1)
  end

  def get_product(id) do
    case Repo.get(Product, id) do
      nil -> nil
      p -> with_current_quantity(p)
    end
  end

  def get_product!(id) do
    Repo.get!(Product, id) |> with_current_quantity()
  end

  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, p} -> {:ok, with_current_quantity(p)}
      error -> error
    end
  end

  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, p} -> {:ok, with_current_quantity(p)}
      error -> error
    end
  end

  def deactivate_product(%Product{} = product) do
    product
    |> Product.changeset(%{"is_active" => false})
    |> Repo.update()
  end

  # ── Resumo de estoque (todos os produtos) ─────────────────

  def stock_summary do
    list_products()
  end

  # ── Entradas ──────────────────────────────────────────────

  def list_entries(product_id) do
    StockEntry
    |> where([e], e.product_id == ^product_id)
    |> order_by([e], desc: e.date)
    |> Repo.all()
  end

  def create_entry(product_id, attrs) do
    attrs = Map.put(attrs, "product_id", product_id)

    %StockEntry{}
    |> StockEntry.changeset(attrs)
    |> Repo.insert()
  end

  # ── Saídas ────────────────────────────────────────────────

  def list_exits(product_id) do
    StockExit
    |> where([e], e.product_id == ^product_id)
    |> order_by([e], desc: e.date)
    |> Repo.all()
  end

  def create_exit(product_id, attrs) do
    qty = parse_qty(attrs["quantity"] || attrs[:quantity])
    available = current_quantity(product_id)

    if qty > available do
      {:error, :insufficient_stock, available}
    else
      attrs = Map.put(attrs, "product_id", product_id)

      %StockExit{}
      |> StockExit.changeset(attrs)
      |> Repo.insert()
    end
  end

  # ── Histórico (entradas + saídas combinadas) ──────────────

  def product_history(product_id) do
    entries =
      StockEntry
      |> where([e], e.product_id == ^product_id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :movement_type, :entry))

    exits =
      StockExit
      |> where([e], e.product_id == ^product_id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :movement_type, :exit))

    (entries ++ exits)
    |> Enum.sort_by(& &1.date, {:desc, Date})
  end

  # ── Cálculo de quantidade ─────────────────────────────────

  def current_quantity(product_id) do
    total_in =
      StockEntry
      |> where([e], e.product_id == ^product_id)
      |> Repo.aggregate(:sum, :quantity) || 0

    total_out =
      StockExit
      |> where([e], e.product_id == ^product_id)
      |> Repo.aggregate(:sum, :quantity) || 0

    total_in - total_out
  end

  def last_entry_prices(product_id) do
    StockEntry
    |> where([e], e.product_id == ^product_id)
    |> order_by([e], desc: e.date)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> %{cost_price: nil, sale_price: nil}
      e -> %{cost_price: e.cost_price, sale_price: e.sale_price}
    end
  end

  # ── Helpers privados ──────────────────────────────────────

  defp with_current_quantity(%Product{} = product) do
    qty = current_quantity(product.id)
    prices = last_entry_prices(product.id)
    Map.merge(product, %{current_quantity: qty, cost_price: prices.cost_price, sale_price: prices.sale_price})
  end

  defp apply_product_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:category, cat}, q when is_binary(cat) -> where(q, [p], p.category == ^cat)
      {:is_active, val}, q when is_boolean(val) -> where(q, [p], p.is_active == ^val)
      {:search, term}, q when is_binary(term) and term != "" ->
        like = "%#{term}%"
        where(q, [p], ilike(p.name, ^like))
      _, q -> q
    end)
  end

  defp parse_qty(qty) when is_integer(qty), do: qty
  defp parse_qty(qty) when is_binary(qty), do: String.to_integer(qty)
  defp parse_qty(_), do: 0
end
