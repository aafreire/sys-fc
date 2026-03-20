defmodule SysFc.Rentals do
  @moduledoc """
  Contexto de aluguel de quadra/salão:
  configuração de preços, datas indisponíveis e reservas.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Rentals.{RentalConfig, UnavailableDate, Rental}

  # ── Configuração de preços ─────────────────────────────────────

  @doc "Retorna a configuração existente ou uma struct vazia (sem persist)."
  def get_config do
    Repo.one(RentalConfig) || %RentalConfig{}
  end

  @doc "Cria ou atualiza a configuração de preços (singleton)."
  def update_config(attrs) do
    config = Repo.one(RentalConfig) || %RentalConfig{}
    changeset = RentalConfig.changeset(config, attrs)

    if is_nil(config.id) do
      Repo.insert(changeset)
    else
      Repo.update(changeset)
    end
  end

  # ── Datas indisponíveis ────────────────────────────────────────

  def list_unavailable_dates do
    UnavailableDate
    |> order_by([u], asc: u.date)
    |> Repo.all()
  end

  def create_unavailable_date(attrs) do
    %UnavailableDate{}
    |> UnavailableDate.changeset(attrs)
    |> Repo.insert()
  end

  def delete_unavailable_date(id) do
    case Repo.get(UnavailableDate, id) do
      nil -> {:error, :not_found}
      ud  -> Repo.delete(ud)
    end
  end

  # ── Calendário ────────────────────────────────────────────────

  @doc """
  Retorna o calendário de um mês com o status de cada dia:
  - "past"        – anterior a hoje
  - "unavailable" – bloqueado pelo admin
  - "my_booking"  – reservado pelo próprio responsável
  - "booked"      – reservado por outro responsável
  - "available"   – livre
  """
  def get_calendar(year, month, guardian_id) do
    today = Date.utc_today()
    days_in_month = Date.days_in_month(Date.new!(year, month, 1))
    month_start = Date.new!(year, month, 1)
    month_end = Date.new!(year, month, days_in_month)

    unavailable =
      UnavailableDate
      |> where([u], u.date >= ^month_start and u.date <= ^month_end)
      |> Repo.all()
      |> Enum.map(& &1.date)
      |> MapSet.new()

    active_rentals =
      Rental
      |> where([r], r.date >= ^month_start and r.date <= ^month_end)
      |> where([r], r.status != "cancelled")
      |> Repo.all()

    my_bookings =
      active_rentals
      |> Enum.filter(&(&1.guardian_id == guardian_id))
      |> Map.new(&{&1.date, &1.id})

    others_booked =
      active_rentals
      |> Enum.filter(&(&1.guardian_id != guardian_id))
      |> MapSet.new(& &1.date)

    Enum.map(1..days_in_month, fn day ->
      date = Date.new!(year, month, day)

      status =
        cond do
          Date.compare(date, today) == :lt    -> "past"
          MapSet.member?(unavailable, date)   -> "unavailable"
          Map.has_key?(my_bookings, date)     -> "my_booking"
          MapSet.member?(others_booked, date) -> "booked"
          true                                -> "available"
        end

      %{date: date, status: status, rental_id: my_bookings[date]}
    end)
  end

  # ── Reservas ──────────────────────────────────────────────────

  def list_guardian_rentals(guardian_id) do
    Rental
    |> where([r], r.guardian_id == ^guardian_id)
    |> order_by([r], desc: r.date)
    |> Repo.all()
  end

  def create_rental(guardian_id, attrs) do
    config = get_config()
    pricing_type = attrs["pricing_type"]
    hours = parse_int(attrs["hours"])

    amount =
      case pricing_type do
        "hourly" ->
          rate = config.price_per_hour || Decimal.new(0)
          Decimal.mult(rate, Decimal.new(hours || 1))

        "daily" ->
          config.price_per_day || Decimal.new(0)

        "flat" ->
          config.price_flat || Decimal.new(0)

        _ ->
          Decimal.new(0)
      end

    attrs =
      attrs
      |> Map.put("guardian_id", guardian_id)
      |> Map.put("amount", amount)

    %Rental{}
    |> Rental.changeset(attrs)
    |> Repo.insert()
  end

  def get_rental!(id), do: Repo.get!(Rental, id)

  def get_rental(id) do
    Rental
    |> preload(guardian: :user)
    |> Repo.get(id)
  end

  @doc "Lista todas as reservas (admin) com responsável pré-carregado."
  def list_all_rentals do
    Rental
    |> order_by([r], desc: r.date)
    |> preload(guardian: :user)
    |> Repo.all()
  end

  @doc "Atualiza o status de uma reserva."
  def update_rental_status(%Rental{} = rental, status) do
    rental
    |> Rental.changeset(%{"status" => status})
    |> Repo.update()
  end

  defp parse_int(nil), do: nil
  defp parse_int(v) when is_integer(v), do: v
  defp parse_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error  -> nil
    end
  end
end
