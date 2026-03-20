defmodule SysFcWeb.CardJSON do
  def index(%{cards: cards}), do: %{data: Enum.map(cards, &card_data/1)}

  def show(%{card: card}), do: %{data: card_data(card)}

  defp card_data(card) do
    %{
      id: card.id,
      brand: card.brand,
      last_four: card.last_four,
      holder_name: card.holder_name,
      expiry_month: card.expiry_month,
      expiry_year: card.expiry_year,
      is_default: card.is_default,
      inserted_at: card.inserted_at
      # token NÃO é exposto na API
    }
  end
end
