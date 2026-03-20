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
      inserted_at: rental.inserted_at
    }
  end

  defp admin_rental_data(rental) do
    guardian_name =
      case rental do
        %{guardian: %{user: %{name: name}}} when not is_nil(name) -> name
        _ -> nil
      end

    rental_data(rental) |> Map.put(:guardian_name, guardian_name)
  end
end
