defmodule SysFcWeb.RentalJSON do
  def config(%{config: config}), do: %{data: config_data(config)}

  def unavailable_dates(%{dates: dates}), do: %{data: Enum.map(dates, &unavailable_data/1)}

  def unavailable_date(%{date: date}), do: %{data: unavailable_data(date)}

  def calendar(%{days: days, config: config, year: year, month: month}) do
    %{
      data: %{
        year: year,
        month: month,
        config: config_data(config),
        days: Enum.map(days, &day_data/1)
      }
    }
  end

  def index(%{rentals: rentals}), do: %{data: Enum.map(rentals, &rental_data/1)}

  def show(%{rental: rental}), do: %{data: rental_data(rental)}

  def admin_index(%{rentals: rentals}), do: %{data: Enum.map(rentals, &admin_rental_data/1)}

  def admin_show(%{rental: rental}), do: %{data: admin_rental_data(rental)}

  def rental_fees(%{fees: fees}), do: %{data: Enum.map(fees, &fee_data/1)}

  def rental_fee(%{fee: fee}), do: %{data: fee_data(fee)}

  def monthly(%{fees: fees, month: month, year: year}) do
    %{
      data: %{
        month: month,
        year: year,
        summary: summarize_month(fees),
        fees: Enum.map(fees, &month_fee_data/1)
      }
    }
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp config_data(config) do
    %{
      id: config.id,
      price_per_hour: config.price_per_hour,
      price_per_day: config.price_per_day,
      price_flat: config.price_flat,
      description: config.description
    }
  end

  defp unavailable_data(d) do
    %{id: d.id, date: d.date, reason: d.reason}
  end

  defp day_data(day) do
    %{date: day.date, status: day.status, rental_id: day.rental_id}
  end

  defp rental_data(rental) do
    %{
      id: rental.id,
      date: rental.date,
      hours: rental.hours,
      pricing_type: rental.pricing_type,
      amount: rental.amount,
      payment_method: rental.payment_method,
      status: rental.status,
      notes: rental.notes,
      court: rental.court,
      start_time: rental.start_time,
      end_time: rental.end_time,
      renter_name: rental.renter_name,
      renter_email: rental.renter_email,
      renter_phone: rental.renter_phone,
      renter_document_type: rental.renter_document_type,
      renter_document: format_renter_document(rental.renter_document_type, rental.renter_document),
      is_recurring: rental.is_recurring,
      recurrence_weekdays: rental.recurrence_weekdays,
      recurrence_start_date: rental.recurrence_start_date,
      recurrence_end_date: rental.recurrence_end_date,
      monthly_amount: rental.monthly_amount,
      created_by_admin: rental.created_by_admin,
      inserted_at: rental.inserted_at
    }
  end

  defp admin_rental_data(rental) do
    guardian_name =
      case rental do
        %{guardian: %{user: %{name: name}}} when not is_nil(name) -> name
        _ -> nil
      end

    fees =
      case rental do
        %{rental_fees: fees} when is_list(fees) -> Enum.map(fees, &fee_data/1)
        _ -> []
      end

    rental_data(rental)
    |> Map.put(:guardian_name, guardian_name)
    |> Map.put(:fees, fees)
    |> Map.put(:financial_summary, summarize_fees(fees))
  end

  defp summarize_fees([]), do: %{total: "0", paid: "0", pending: "0", overdue: 0}

  defp summarize_fees(fees) do
    today = Date.utc_today()

    {total, paid, pending} =
      Enum.reduce(fees, {Decimal.new(0), Decimal.new(0), Decimal.new(0)}, fn f, {t, p, q} ->
        amount = to_decimal(f.amount)
        t = Decimal.add(t, amount)

        cond do
          f.status == "paid" -> {t, Decimal.add(p, amount), q}
          true -> {t, p, Decimal.add(q, amount)}
        end
      end)

    overdue_count =
      Enum.count(fees, fn f ->
        f.status != "paid" and not is_nil(f.due_date) and
          Date.compare(parse_due(f.due_date), today) == :lt
      end)

    %{
      total: Decimal.to_string(total),
      paid: Decimal.to_string(paid),
      pending: Decimal.to_string(pending),
      overdue: overdue_count
    }
  end

  # Resumo mensal com valores (recebido / pendente / atraso / falta receber)
  defp summarize_month(fees) do
    today = Date.utc_today()

    {received, pending, overdue} =
      Enum.reduce(fees, {Decimal.new(0), Decimal.new(0), Decimal.new(0)}, fn f, {r, p, o} ->
        amount = to_decimal(f.amount)

        cond do
          to_string(f.status) == "paid" ->
            {Decimal.add(r, amount), p, o}

          not is_nil(f.due_date) and Date.compare(parse_due(f.due_date), today) == :lt ->
            {r, p, Decimal.add(o, amount)}

          true ->
            {r, Decimal.add(p, amount), o}
        end
      end)

    to_receive = Decimal.add(pending, overdue)

    %{
      received: Decimal.to_string(received),
      pending: Decimal.to_string(pending),
      overdue: Decimal.to_string(overdue),
      to_receive: Decimal.to_string(to_receive),
      total: Decimal.to_string(Decimal.add(received, to_receive))
    }
  end

  defp month_fee_data(f) do
    rental = if Ecto.assoc_loaded?(f.rental), do: f.rental, else: nil

    %{
      id: f.id,
      rental_id: f.rental_id,
      reference_month: f.reference_month,
      reference_year: f.reference_year,
      amount: f.amount,
      due_date: f.due_date,
      payment_date: f.payment_date,
      status: f.status,
      renter_name: rental && rental.renter_name,
      court: rental && rental.court,
      is_recurring: rental && rental.is_recurring,
      pricing_type: rental && rental.pricing_type
    }
  end

  defp parse_due(%Date{} = d), do: d
  defp parse_due(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end

  defp to_decimal(nil), do: Decimal.new(0)
  defp to_decimal(%Decimal{} = d), do: d
  defp to_decimal(v) when is_binary(v) do
    case Decimal.parse(v) do
      {d, _} -> d
      _ -> Decimal.new(0)
    end
  end
  defp to_decimal(v) when is_integer(v), do: Decimal.new(v)
  defp to_decimal(v) when is_float(v), do: Decimal.from_float(v)

  defp format_renter_document(_, nil), do: nil
  defp format_renter_document("cpf", cpf) when byte_size(cpf) == 11 do
    String.slice(cpf, 0, 3) <> "." <>
    String.slice(cpf, 3, 3) <> "." <>
    String.slice(cpf, 6, 3) <> "-" <>
    String.slice(cpf, 9, 2)
  end
  defp format_renter_document(_, value), do: value

  defp fee_data(%{} = f) when is_map(f) do
    %{
      id: f.id,
      rental_id: f.rental_id,
      reference_month: f.reference_month,
      reference_year: f.reference_year,
      amount: f.amount,
      due_date: f.due_date,
      payment_date: f.payment_date,
      status: f.status,
      receipt_url: f.receipt_url,
      notes: f.notes
    }
  end
end
