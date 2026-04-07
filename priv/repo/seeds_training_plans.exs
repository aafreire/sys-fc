alias SysFc.TrainingPlans

# ── Planos de Treino ──────────────────────────────────────────────────────────

training_plans_data = [
  %{
    "name" => "quartas-sextas",
    "label" => "Turma Quartas e Sextas",
    "description" => "Quartas e Sextas-feiras – manhã e tarde",
    "frequency" => "2 aulas por semana",
    "days" => ["Quarta", "Sexta"],
    "price" => "120.00",
    "sort_order" => 1
  },
  %{
    "name" => "quartas-sextas-sabados",
    "label" => "Turma Quartas, Sextas e Sábados",
    "description" => "Quartas e Sextas-feiras + Sábados – manhã",
    "frequency" => "3 aulas por semana",
    "days" => ["Quarta", "Sexta", "Sábado"],
    "price" => "150.00",
    "sort_order" => 2
  },
  %{
    "name" => "sabados",
    "label" => "Turma Sábados",
    "description" => "Somente Sábados – manhã",
    "frequency" => "1 aula por semana",
    "days" => ["Sábado"],
    "price" => "90.00",
    "sort_order" => 3
  }
]

Enum.each(training_plans_data, fn attrs ->
  case SysFc.Repo.get_by(SysFc.TrainingPlans.TrainingPlan, name: attrs["name"]) do
    nil ->
      {:ok, _} = TrainingPlans.create_training_plan(attrs)
      IO.puts("  ok Plano de treino: #{attrs["label"]}")
    _ ->
      IO.puts("  -- Plano já existe: #{attrs["label"]}")
  end
end)

# ── Locais de Treino ──────────────────────────────────────────────────────────

training_locations_data = [
  %{"name" => "campo-principal", "label" => "Campo Principal", "sort_order" => 1},
  %{"name" => "campo-auxiliar", "label" => "Campo Auxiliar", "sort_order" => 2},
  %{"name" => "unidade-a", "label" => "Unidade A - Centro", "sort_order" => 3},
  %{"name" => "unidade-b", "label" => "Unidade B - Santa Paula", "sort_order" => 4}
]

Enum.each(training_locations_data, fn attrs ->
  case SysFc.Repo.get_by(SysFc.TrainingPlans.TrainingLocation, name: attrs["name"]) do
    nil ->
      {:ok, _} = TrainingPlans.create_training_location(attrs)
      IO.puts("  ok Local de treino: #{attrs["label"]}")
    _ ->
      IO.puts("  -- Local já existe: #{attrs["label"]}")
  end
end)
