defmodule SysFc.Units do
  @moduledoc """
  Contexto de unidades da escolinha e suas quadras.
  Cada unidade possui suas próprias quadras; alunos são vinculados a uma unidade.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Units.{Unit, Court}

  # ── Unidades ──────────────────────────────────────────────

  def list_units(opts \\ []) do
    only_active = Keyword.get(opts, :only_active, false)

    Unit
    |> then(fn q -> if only_active, do: where(q, [u], u.is_active == true), else: q end)
    |> order_by([u], asc: u.sort_order, asc: u.name)
    |> preload(courts: ^ordered_courts_query())
    |> Repo.all()
  end

  @doc "Retorna a primeira unidade cadastrada (por ordem de exibição), ou nil."
  def default_unit do
    Unit
    |> order_by([u], asc: u.sort_order, asc: u.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_unit(id), do: Repo.get(Unit, id) |> Repo.preload(courts: ordered_courts_query())

  def get_unit!(id), do: Repo.get!(Unit, id) |> Repo.preload(courts: ordered_courts_query())

  def create_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
    |> preload_courts()
  end

  def update_unit(%Unit{} = unit, attrs) do
    unit
    |> Unit.changeset(attrs)
    |> Repo.update()
    |> preload_courts()
  end

  def delete_unit(%Unit{} = unit), do: Repo.delete(unit)

  # ── Quadras ───────────────────────────────────────────────

  def get_court(id), do: Repo.get(Court, id)

  def create_court(unit_id, attrs) do
    attrs = attrs |> Map.new(fn {k, v} -> {to_string(k), v} end) |> Map.put("unit_id", unit_id)

    %Court{}
    |> Court.changeset(attrs)
    |> Repo.insert()
  end

  def update_court(%Court{} = court, attrs) do
    court
    |> Court.changeset(attrs)
    |> Repo.update()
  end

  def delete_court(%Court{} = court), do: Repo.delete(court)

  # ── Helpers ───────────────────────────────────────────────

  defp ordered_courts_query do
    from c in Court, order_by: [asc: c.sort_order, asc: c.name]
  end

  defp preload_courts({:ok, unit}), do: {:ok, Repo.preload(unit, courts: ordered_courts_query())}
  defp preload_courts(error), do: error
end
