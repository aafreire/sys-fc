defmodule SysFcWeb.ProductController do
  use SysFcWeb, :controller

  alias SysFc.Stock

  # GET /api/admin/products
  def index(conn, params) do
    opts =
      []
      |> maybe_filter(:category, params["category"])
      |> maybe_filter(:search, params["search"])
      |> maybe_filter(:is_active, parse_bool(params["is_active"], true))

    products = Stock.list_products(opts)
    render(conn, :index, products: products)
  end

  # GET /api/admin/stock/summary
  def summary(conn, _params) do
    products = Stock.stock_summary()
    render(conn, :index, products: products)
  end

  # GET /api/admin/products/:id
  def show(conn, %{"id" => id}) do
    case Stock.get_product(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      product -> render(conn, :show, product: product)
    end
  end

  # POST /api/admin/products
  def create(conn, params) do
    case Stock.create_product(params) do
      {:ok, product} ->
        conn |> put_status(:created) |> render(:show, product: product)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/products/:id
  def update(conn, %{"id" => id} = params) do
    case Stock.get_product(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      product ->
        case Stock.update_product(product, params) do
          {:ok, updated} -> render(conn, :show, product: updated)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # DELETE /api/admin/products/:id  (soft-delete)
  def delete(conn, %{"id" => id}) do
    case Stock.get_product(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      product ->
        {:ok, _} = Stock.deactivate_product(product)
        send_resp(conn, :no_content, "")
    end
  end

  # POST /api/admin/products/:id/entries
  def create_entry(conn, %{"id" => product_id} = params) do
    case Stock.get_product(product_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "product_not_found"})

      _product ->
        case Stock.create_entry(product_id, params) do
          {:ok, entry} ->
            product = Stock.get_product!(product_id)
            conn |> put_status(:created) |> render(:entry_created, entry: entry, product: product)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # POST /api/admin/products/:id/exits
  def create_exit(conn, %{"id" => product_id} = params) do
    case Stock.get_product(product_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "product_not_found"})

      _product ->
        case Stock.create_exit(product_id, params) do
          {:ok, exit_record} ->
            product = Stock.get_product!(product_id)
            conn |> put_status(:created) |> render(:exit_created, exit: exit_record, product: product)

          {:error, :insufficient_stock, available} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "insufficient_stock", available_quantity: available})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # GET /api/admin/products/:id/history
  def history(conn, %{"id" => product_id}) do
    case Stock.get_product(product_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "product_not_found"})

      product ->
        movements = Stock.product_history(product_id)
        render(conn, :history, product: product, movements: movements)
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp maybe_filter(opts, _key, nil), do: opts
  defp maybe_filter(opts, _key, ""), do: opts
  defp maybe_filter(opts, key, value), do: [{key, value} | opts]

  defp parse_bool(nil, default), do: default
  defp parse_bool("true", _), do: true
  defp parse_bool("false", _), do: false
  defp parse_bool(_, default), do: default

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
