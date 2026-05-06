defmodule SysFc.Rentals do
  @moduledoc """
  Contexto de aluguel de quadra/salão:
  configuração de preços, datas indisponíveis e reservas.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Rentals.{RentalConfig, UnavailableDate, Rental, RentalFee}

  # Quantos meses gerar adiante para uma locação recorrente sem data fim
  @default_recurrence_months 12

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

  Considera tanto reservas únicas quanto ocorrências de reservas recorrentes.
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

    # Únicas no mês
    single_rentals =
      Rental
      |> where([r], r.is_recurring == false)
      |> where([r], r.date >= ^month_start and r.date <= ^month_end)
      |> where([r], r.status != "cancelled")
      |> Repo.all()

    # Recorrentes ativas que se sobrepõem ao mês
    recurring_rentals =
      Rental
      |> where([r], r.is_recurring == true)
      |> where([r], r.status != "cancelled")
      |> where([r], is_nil(r.recurrence_end_date) or r.recurrence_end_date >= ^month_start)
      |> where([r], r.recurrence_start_date <= ^month_end)
      |> Repo.all()

    # Ocupações: %{date => [%{rental_id, guardian_id, court}]}
    occupations =
      single_rentals
      |> Enum.reduce(%{}, fn r, acc ->
        Map.update(acc, r.date, [r], &[r | &1])
      end)
      |> add_recurring_occurrences(recurring_rentals, month_start, month_end)

    Enum.map(1..days_in_month, fn day ->
      date = Date.new!(year, month, day)
      occ = Map.get(occupations, date, [])

      mine = Enum.find(occ, &(&1.guardian_id == guardian_id and not is_nil(guardian_id)))

      status =
        cond do
          Date.compare(date, today) == :lt    -> "past"
          MapSet.member?(unavailable, date)   -> "unavailable"
          not is_nil(mine)                    -> "my_booking"
          occ != []                           -> "booked"
          true                                -> "available"
        end

      %{date: date, status: status, rental_id: mine && mine.id}
    end)
  end

  defp add_recurring_occurrences(acc, recurrings, month_start, month_end) do
    Enum.reduce(recurrings, acc, fn r, acc ->
      r
      |> expand_recurrence_dates(month_start, month_end)
      |> Enum.reduce(acc, fn d, inner_acc ->
        Map.update(inner_acc, d, [r], &[r | &1])
      end)
    end)
  end

  @doc """
  Calcula as datas em que uma locação recorrente acontece dentro de um
  intervalo (inclusive). Considera apenas dias da semana configurados.
  """
  def expand_recurrence_dates(%Rental{is_recurring: true} = r, range_start, range_end) do
    weekdays = r.recurrence_weekdays || []
    start_date = max_date(r.recurrence_start_date, range_start)
    end_date = min_date(r.recurrence_end_date || range_end, range_end)

    if Date.compare(start_date, end_date) == :gt or weekdays == [] do
      []
    else
      Date.range(start_date, end_date)
      |> Enum.filter(fn d ->
        wd = d |> Date.day_of_week() |> normalize_weekday()
        wd in weekdays
      end)
    end
  end

  def expand_recurrence_dates(_, _, _), do: []

  # Date.day_of_week retorna 1 (segunda) a 7 (domingo); aqui usamos
  # 0 (domingo) a 6 (sábado) — padrão JS — para casar com o frontend.
  defp normalize_weekday(7), do: 0
  defp normalize_weekday(n), do: n

  defp max_date(a, b), do: if(Date.compare(a, b) == :lt, do: b, else: a)
  defp min_date(a, b), do: if(Date.compare(a, b) == :gt, do: b, else: a)

  # ── Reservas (guardian) ──────────────────────────────────────

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
    |> Repo.get(id)
    |> Repo.preload([guardian: :user, rental_fees: ordered_fees_query()])
  end

  @doc "Lista todas as reservas (admin) com responsável e cobranças pré-carregadas."
  def list_all_rentals do
    Rental
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
    |> Repo.preload([guardian: :user, rental_fees: ordered_fees_query()])
  end

  defp ordered_fees_query do
    from f in RentalFee, order_by: [asc: f.due_date]
  end

  @doc "Atualiza o status de uma reserva."
  def update_rental_status(%Rental{} = rental, status) do
    rental
    |> Rental.changeset(%{"status" => status})
    |> Repo.update()
  end

  # ── Cadastro pelo admin (única ou recorrente) ─────────────────

  @doc """
  Cria uma locação manualmente pelo admin. Atributos esperados:

    * `court` — "court_1" | "court_2"
    * `renter_name`, `renter_email`, `renter_phone`
    * `pricing_type` — "flat" | "hourly" | "daily" | "monthly"
    * `amount` — valor por evento (ou mensal, se recorrente)
    * `is_recurring` — boolean
    * `date` — quando única
    * `recurrence_weekdays` — [0..6] (0=domingo) quando recorrente
    * `recurrence_start_date`, `recurrence_end_date` — quando recorrente
    * `monthly_amount` — valor mensal acordado (recorrente)
    * `start_time`, `end_time`, `notes`, `payment_method`
  """
  def create_admin_rental(attrs) do
    attrs =
      attrs
      |> normalize_keys()
      |> Map.put("created_by_admin", true)
      |> Map.put_new("status", "confirmed")
      |> default_recurrence_end()

    Repo.transaction(fn ->
      changeset =
        %Rental{}
        |> Rental.admin_changeset(attrs)

      with :ok <- check_admin_conflicts(changeset),
           {:ok, rental} <- Repo.insert(changeset),
           {:ok, _fees} <- create_initial_fees(rental, attrs) do
        rental
        |> Repo.preload([guardian: :user, rental_fees: ordered_fees_query()])
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp default_recurrence_end(%{"is_recurring" => true} = attrs) do
    case attrs["recurrence_end_date"] do
      nil ->
        case attrs["recurrence_start_date"] do
          nil -> attrs
          start when is_binary(start) ->
            case Date.from_iso8601(start) do
              {:ok, sd} ->
                Map.put(attrs, "recurrence_end_date",
                  add_months(sd, @default_recurrence_months) |> Date.to_iso8601())
              _ -> attrs
            end
          %Date{} = sd ->
            Map.put(attrs, "recurrence_end_date", add_months(sd, @default_recurrence_months))
          _ -> attrs
        end
      _ -> attrs
    end
  end

  defp default_recurrence_end(attrs), do: attrs

  defp normalize_keys(attrs) when is_map(attrs) do
    attrs
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  # ── Validação de conflitos para o admin ──────────────────────

  defp check_admin_conflicts(changeset) do
    if changeset.valid? do
      court = Ecto.Changeset.get_field(changeset, :court)
      is_recurring = Ecto.Changeset.get_field(changeset, :is_recurring)

      cond do
        is_recurring ->
          weekdays = Ecto.Changeset.get_field(changeset, :recurrence_weekdays) || []
          rs = Ecto.Changeset.get_field(changeset, :recurrence_start_date)
          re = Ecto.Changeset.get_field(changeset, :recurrence_end_date) || add_months(rs, @default_recurrence_months)

          if has_recurrence_conflict?(court, weekdays, rs, re) do
            {:error,
              changeset
              |> Ecto.Changeset.add_error(:recurrence_weekdays, "conflito de horário com outra locação na mesma quadra")
            }
          else
            :ok
          end

        true ->
          date = Ecto.Changeset.get_field(changeset, :date)

          if has_single_conflict?(court, date) do
            {:error,
              changeset
              |> Ecto.Changeset.add_error(:date, "Esta quadra já está reservada nesta data")
            }
          else
            :ok
          end
      end
    else
      {:error, changeset}
    end
  end

  defp has_single_conflict?(court, date) when not is_nil(court) and not is_nil(date) do
    # Conflito direto: outra reserva única ativa no mesmo dia + quadra
    direct =
      Rental
      |> where([r], r.is_recurring == false)
      |> where([r], r.date == ^date)
      |> where([r], r.court == ^court)
      |> where([r], r.status != "cancelled")
      |> Repo.exists?()

    if direct do
      true
    else
      # Conflito com recorrências ativas
      weekday = date |> Date.day_of_week() |> normalize_weekday()

      Rental
      |> where([r], r.is_recurring == true)
      |> where([r], r.court == ^court)
      |> where([r], r.status != "cancelled")
      |> where([r], r.recurrence_start_date <= ^date)
      |> where([r], is_nil(r.recurrence_end_date) or r.recurrence_end_date >= ^date)
      |> Repo.all()
      |> Enum.any?(fn r -> weekday in (r.recurrence_weekdays || []) end)
    end
  end

  defp has_single_conflict?(_, _), do: false

  defp has_recurrence_conflict?(court, weekdays, rs, re)
       when is_list(weekdays) and not is_nil(rs) and not is_nil(re) do
    # Locações únicas que caem em algum dos weekdays no intervalo
    singles =
      Rental
      |> where([r], r.is_recurring == false)
      |> where([r], r.court == ^court)
      |> where([r], r.status != "cancelled")
      |> where([r], r.date >= ^rs and r.date <= ^re)
      |> Repo.all()

    single_clash? =
      Enum.any?(singles, fn r ->
        wd = r.date |> Date.day_of_week() |> normalize_weekday()
        wd in weekdays
      end)

    if single_clash? do
      true
    else
      # Outras recorrências sobrepostas
      Rental
      |> where([r], r.is_recurring == true)
      |> where([r], r.court == ^court)
      |> where([r], r.status != "cancelled")
      |> where([r], is_nil(r.recurrence_end_date) or r.recurrence_end_date >= ^rs)
      |> where([r], r.recurrence_start_date <= ^re)
      |> Repo.all()
      |> Enum.any?(fn r ->
        Enum.any?(r.recurrence_weekdays || [], &(&1 in weekdays))
      end)
    end
  end

  defp has_recurrence_conflict?(_, _, _, _), do: false

  # ── Geração de fees iniciais ─────────────────────────────────

  defp create_initial_fees(%Rental{is_recurring: true} = rental, attrs) do
    rs = rental.recurrence_start_date
    re = rental.recurrence_end_date || add_months(rs, @default_recurrence_months)
    monthly = rental.monthly_amount || rental.amount
    due_day = parse_int(attrs["due_day"]) || rs.day

    months = month_range(rs, re)

    fees =
      Enum.map(months, fn {y, m} ->
        last_day = Date.days_in_month(Date.new!(y, m, 1))
        due_date = Date.new!(y, m, min(due_day, last_day))

        %RentalFee{}
        |> RentalFee.changeset(%{
          rental_id: rental.id,
          reference_month: m,
          reference_year: y,
          amount: monthly,
          due_date: due_date,
          status: "pending"
        })
        |> Repo.insert!()
      end)

    {:ok, fees}
  end

  defp create_initial_fees(%Rental{} = rental, attrs) do
    due_date =
      case parse_date(attrs["due_date"]) do
        nil -> rental.date
        d -> d
      end

    fee =
      %RentalFee{}
      |> RentalFee.changeset(%{
        rental_id: rental.id,
        amount: rental.amount,
        due_date: due_date,
        status: "pending"
      })
      |> Repo.insert!()

    {:ok, [fee]}
  end

  defp month_range(start_date, end_date) do
    {ys, ms} = {start_date.year, start_date.month}
    {ye, me} = {end_date.year, end_date.month}

    Stream.iterate({ys, ms}, fn {y, m} ->
      if m == 12, do: {y + 1, 1}, else: {y, m + 1}
    end)
    |> Enum.take_while(fn {y, m} ->
      y < ye or (y == ye and m <= me)
    end)
  end

  defp add_months(%Date{} = d, n) do
    total = (d.year * 12 + (d.month - 1)) + n
    y = div(total, 12)
    m = rem(total, 12) + 1
    last_day = Date.days_in_month(Date.new!(y, m, 1))
    Date.new!(y, m, min(d.day, last_day))
  end

  # ── Rental fees (administração financeira) ───────────────────

  def list_rental_fees(rental_id) do
    RentalFee
    |> where([f], f.rental_id == ^rental_id)
    |> order_by([f], asc: f.due_date)
    |> Repo.all()
  end

  def get_rental_fee(id), do: Repo.get(RentalFee, id) |> Repo.preload(rental: [guardian: :user])

  def mark_rental_fee_paid(%RentalFee{} = fee, payment_date \\ nil) do
    payment_date = payment_date || Date.utc_today()

    fee
    |> RentalFee.changeset(%{status: "paid", payment_date: payment_date})
    |> Repo.update()
  end

  def update_rental_fee_status(%RentalFee{} = fee, status) do
    fee
    |> RentalFee.changeset(%{status: status})
    |> Repo.update()
  end

  # ── Helpers ──────────────────────────────────────────────────

  defp parse_int(nil), do: nil
  defp parse_int(v) when is_integer(v), do: v
  defp parse_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error  -> nil
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(%Date{} = d), do: d
  defp parse_date(v) when is_binary(v) do
    case Date.from_iso8601(v) do
      {:ok, d} -> d
      _ -> nil
    end
  end
end
