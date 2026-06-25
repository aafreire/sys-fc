defmodule SysFc.Finance.MonthlyFeeScheduler do
  @moduledoc """
  Gera automaticamente as mensalidades do mês corrente para todos os alunos
  ativos e não congelados, sem depender de ação manual.

  Roda pouco depois do boot e, em seguida, a cada 24h. A geração é idempotente
  (`Finance.generate_monthly_fees/0` usa `on_conflict: :nothing`), então rodar
  diariamente não duplica cobranças e garante que a virada de mês seja coberta
  em até um dia.
  """
  use GenServer
  require Logger

  alias SysFc.Finance

  # Pequeno atraso após o boot para o Repo/conexões estabilizarem
  @initial_delay :timer.seconds(10)
  @interval :timer.hours(24)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Process.send_after(self(), :generate, @initial_delay)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:generate, state) do
    try do
      Finance.generate_monthly_fees()
      Logger.info("[MonthlyFeeScheduler] mensalidades do mês geradas/atualizadas")
    rescue
      error ->
        Logger.error("[MonthlyFeeScheduler] falha ao gerar mensalidades: #{inspect(error)}")
    end

    Process.send_after(self(), :generate, @interval)
    {:noreply, state}
  end
end
