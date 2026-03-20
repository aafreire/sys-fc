defmodule SysFc.Payments do
  @moduledoc """
  Contexto de pagamentos: gerenciamento de cartões de crédito dos responsáveis.

  Os dados brutos do cartão NUNCA são armazenados.
  Apenas o token retornado pelo gateway de pagamento (ex.: Stripe, PagarMe)
  é persistido, junto com informações não-sensíveis (bandeira, últimos 4 dígitos,
  nome do titular e validade).
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Payments.CreditCard

  # ── Listagem ──────────────────────────────────────────────────

  @doc "Lista os cartões ativos de um responsável, com o padrão primeiro."
  def list_guardian_cards(guardian_id) do
    CreditCard
    |> where([c], c.guardian_id == ^guardian_id and c.is_active == true)
    |> order_by([c], [desc: c.is_default, asc: c.inserted_at])
    |> Repo.all()
  end

  # ── Criação ───────────────────────────────────────────────────

  @doc """
  Cadastra um novo cartão para o responsável.
  Se for o primeiro cartão, já define como padrão automaticamente.
  """
  def create_card(guardian_id, attrs) do
    is_first = list_guardian_cards(guardian_id) == []

    attrs =
      attrs
      |> Map.put("guardian_id", guardian_id)
      |> Map.put("is_default", is_first)

    %CreditCard{}
    |> CreditCard.changeset(attrs)
    |> Repo.insert()
  end

  # ── Remoção (soft delete) ─────────────────────────────────────

  @doc """
  Remove um cartão (soft delete: is_active = false).
  Se era o cartão padrão, elege automaticamente o próximo ativo como padrão.
  """
  def delete_card(guardian_id, card_id) do
    case get_guardian_card(guardian_id, card_id) do
      nil ->
        {:error, :not_found}

      card ->
        result = card |> CreditCard.status_changeset(%{is_active: false, is_default: false}) |> Repo.update()

        # Se era o padrão, promove o próximo cartão ativo
        if card.is_default do
          promote_next_default(guardian_id)
        end

        result
    end
  end

  # ── Cartão padrão ─────────────────────────────────────────────

  @doc "Define um cartão como padrão, desmarcando os demais."
  def set_default_card(guardian_id, card_id) do
    case get_guardian_card(guardian_id, card_id) do
      nil ->
        {:error, :not_found}

      card ->
        Repo.transaction(fn ->
          # Remove padrão de todos os outros
          CreditCard
          |> where([c], c.guardian_id == ^guardian_id and c.id != ^card_id)
          |> Repo.update_all(set: [is_default: false])

          card
          |> CreditCard.status_changeset(%{is_default: true})
          |> Repo.update!()
        end)
    end
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp get_guardian_card(guardian_id, card_id) do
    CreditCard
    |> where([c], c.guardian_id == ^guardian_id and c.id == ^card_id and c.is_active == true)
    |> Repo.one()
  end

  defp promote_next_default(guardian_id) do
    next =
      CreditCard
      |> where([c], c.guardian_id == ^guardian_id and c.is_active == true)
      |> order_by([c], asc: c.inserted_at)
      |> limit(1)
      |> Repo.one()

    if next do
      next |> CreditCard.status_changeset(%{is_default: true}) |> Repo.update()
    end
  end
end
