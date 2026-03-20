alias SysFc.{Accounts, Students, TrainingPlans}

IO.puts("Seeding database...")

# ── Admin Master ───────────────────────────────────────────────────────────────

case Accounts.get_user_by_email("admin@saocaetano.com") do
  nil ->
    {:ok, _} =
      Accounts.create_user(%{
        "name" => "Administrador Master",
        "email" => "admin@saocaetano.com",
        "password" => "Admin@123",
        "role" => "admin_master",
        "is_active" => true
      })
    IO.puts("  ok Admin Master: admin@saocaetano.com / Admin@123")

  _ ->
    IO.puts("  -- Admin Master já existe")
end

# ── Admin Limitado ─────────────────────────────────────────────────────────────

case Accounts.get_user_by_email("professor@saocaetano.com") do
  nil ->
    {:ok, _} =
      Accounts.create_user(%{
        "name" => "Carlos Professor",
        "email" => "professor@saocaetano.com",
        "password" => "Prof@123",
        "role" => "admin_limited",
        "is_active" => true
      })
    IO.puts("  ok Admin Limitado: professor@saocaetano.com / Prof@123")

  _ ->
    IO.puts("  -- Admin Limitado já existe")
end

# ── Planos de Treino ───────────────────────────────────────────────────────────

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

# ── Locais de Treino ────────────────────────────────────────────────────────────

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

# ── Responsáveis e Alunos ──────────────────────────────────────────────────────
#
# Cada família tem: email, senha, cpf, telefone, nome do responsável
# e uma lista de filhos com: nome, data_nascimento, categoria, mensalidade,
#   dias_de_treino, local_de_treino, plano_de_treino

families = [
  # 1 — Família Silva
  %{
    guardian: %{
      "name" => "Paulo Roberto Silva",
      "email" => "paulo.silva@email.com",
      "password" => "Resp@123",
      "cpf" => "11122233344",
      "phone" => "(11) 98001-0001"
    },
    students: [
      %{
        "name" => "Gabriel Silva",
        "birth_date" => "2016-05-12",
        "category" => "Sub-10",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua das Flores", "address_number" => "102",
        "neighborhood" => "Centro", "city" => "São Caetano do Sul", "cep" => "09521001"
      },
      %{
        "name" => "Lucas Silva",
        "birth_date" => "2014-03-20",
        "category" => "Sub-12",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua das Flores", "address_number" => "102",
        "neighborhood" => "Centro", "city" => "São Caetano do Sul", "cep" => "09521001"
      }
    ]
  },
  # 2 — Família Santos
  %{
    guardian: %{
      "name" => "Fernanda Santos",
      "email" => "fernanda.santos@email.com",
      "password" => "Resp@123",
      "cpf" => "22233344455",
      "phone" => "(11) 98001-0002"
    },
    students: [
      %{
        "name" => "Mateus Santos",
        "birth_date" => "2019-08-15",
        "category" => "Sub-7",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Av. Brasil", "address_number" => "500",
        "neighborhood" => "Vila Prosperidade", "city" => "São Caetano do Sul", "cep" => "09530001"
      },
      %{
        "name" => "Pedro Santos",
        "birth_date" => "2017-11-02",
        "category" => "Sub-9",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Av. Brasil", "address_number" => "500",
        "neighborhood" => "Vila Prosperidade", "city" => "São Caetano do Sul", "cep" => "09530001"
      },
      %{
        "name" => "Rafael Santos",
        "birth_date" => "2015-04-08",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Av. Brasil", "address_number" => "500",
        "neighborhood" => "Vila Prosperidade", "city" => "São Caetano do Sul", "cep" => "09530001"
      }
    ]
  },
  # 3 — Família Oliveira
  %{
    guardian: %{
      "name" => "Marcelo Oliveira",
      "email" => "marcelo.oliveira@email.com",
      "password" => "Resp@123",
      "cpf" => "33344455566",
      "phone" => "(11) 98001-0003"
    },
    students: [
      %{
        "name" => "Thiago Oliveira",
        "birth_date" => "2018-02-18",
        "category" => "Sub-8",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua XV de Novembro", "address_number" => "78",
        "neighborhood" => "Santa Maria", "city" => "São Caetano do Sul", "cep" => "09510001"
      },
      %{
        "name" => "Diego Oliveira",
        "birth_date" => "2013-07-30",
        "category" => "Sub-13",
        "monthly_fee" => "180.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua XV de Novembro", "address_number" => "78",
        "neighborhood" => "Santa Maria", "city" => "São Caetano do Sul", "cep" => "09510001"
      }
    ]
  },
  # 4 — Família Souza
  %{
    guardian: %{
      "name" => "Ana Paula Souza",
      "email" => "ana.souza@email.com",
      "password" => "Resp@123",
      "cpf" => "44455566677",
      "phone" => "(11) 98001-0004"
    },
    students: [
      %{
        "name" => "Bruno Souza",
        "birth_date" => "2012-09-14",
        "category" => "Sub-14",
        "monthly_fee" => "180.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Goiás", "address_number" => "340",
        "neighborhood" => "Barcelona", "city" => "São Caetano do Sul", "cep" => "09550001"
      },
      %{
        "name" => "Vinicius Souza",
        "birth_date" => "2009-01-25",
        "category" => "Sub-17",
        "monthly_fee" => "200.00",
        "training_days" => ["Segunda", "Quarta", "Sexta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Elite",
        "address" => "Rua Goiás", "address_number" => "340",
        "neighborhood" => "Barcelona", "city" => "São Caetano do Sul", "cep" => "09550001"
      }
    ]
  },
  # 5 — Família Ferreira
  %{
    guardian: %{
      "name" => "Roberto Ferreira",
      "email" => "roberto.ferreira@email.com",
      "password" => "Resp@123",
      "cpf" => "55566677788",
      "phone" => "(11) 98001-0005"
    },
    students: [
      %{
        "name" => "Arthur Ferreira",
        "birth_date" => "2019-03-05",
        "category" => "Sub-7",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Independência", "address_number" => "55",
        "neighborhood" => "Nova Gerty", "city" => "São Caetano do Sul", "cep" => "09560001"
      },
      %{
        "name" => "Henrique Ferreira",
        "birth_date" => "2016-10-22",
        "category" => "Sub-10",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Independência", "address_number" => "55",
        "neighborhood" => "Nova Gerty", "city" => "São Caetano do Sul", "cep" => "09560001"
      },
      %{
        "name" => "Gustavo Ferreira",
        "birth_date" => "2011-06-17",
        "category" => "Sub-15",
        "monthly_fee" => "200.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Independência", "address_number" => "55",
        "neighborhood" => "Nova Gerty", "city" => "São Caetano do Sul", "cep" => "09560001"
      }
    ]
  },
  # 6 — Família Pereira
  %{
    guardian: %{
      "name" => "Claudia Pereira",
      "email" => "claudia.pereira@email.com",
      "password" => "Resp@123",
      "cpf" => "66677788899",
      "phone" => "(11) 98001-0006"
    },
    students: [
      %{
        "name" => "Felipe Pereira",
        "birth_date" => "2018-07-09",
        "category" => "Sub-8",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Piauí", "address_number" => "210",
        "neighborhood" => "Santo Antônio", "city" => "São Caetano do Sul", "cep" => "09540001"
      },
      %{
        "name" => "Caio Pereira",
        "birth_date" => "2014-12-03",
        "category" => "Sub-12",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Piauí", "address_number" => "210",
        "neighborhood" => "Santo Antônio", "city" => "São Caetano do Sul", "cep" => "09540001"
      }
    ]
  },
  # 7 — Família Costa
  %{
    guardian: %{
      "name" => "Sandro Costa",
      "email" => "sandro.costa@email.com",
      "password" => "Resp@123",
      "cpf" => "77788899900",
      "phone" => "(11) 98001-0007"
    },
    students: [
      %{
        "name" => "Leonardo Costa",
        "birth_date" => "2017-09-28",
        "category" => "Sub-9",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Maranhão", "address_number" => "89",
        "neighborhood" => "Fundação", "city" => "São Caetano do Sul", "cep" => "09570001"
      },
      %{
        "name" => "Eduardo Costa",
        "birth_date" => "2015-02-14",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Maranhão", "address_number" => "89",
        "neighborhood" => "Fundação", "city" => "São Caetano do Sul", "cep" => "09570001"
      }
    ]
  },
  # 8 — Família Rodrigues
  %{
    guardian: %{
      "name" => "Juliana Rodrigues",
      "email" => "juliana.rodrigues@email.com",
      "password" => "Resp@123",
      "cpf" => "88899900011",
      "phone" => "(11) 98001-0008"
    },
    students: [
      %{
        "name" => "Davi Rodrigues",
        "birth_date" => "2019-11-11",
        "category" => "Sub-7",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Amazonas", "address_number" => "170",
        "neighborhood" => "Cerâmica", "city" => "São Caetano do Sul", "cep" => "09580001"
      },
      %{
        "name" => "Nicolas Rodrigues",
        "birth_date" => "2016-04-19",
        "category" => "Sub-10",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Amazonas", "address_number" => "170",
        "neighborhood" => "Cerâmica", "city" => "São Caetano do Sul", "cep" => "09580001"
      },
      %{
        "name" => "Samuel Rodrigues",
        "birth_date" => "2013-08-06",
        "category" => "Sub-13",
        "monthly_fee" => "180.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Amazonas", "address_number" => "170",
        "neighborhood" => "Cerâmica", "city" => "São Caetano do Sul", "cep" => "09580001"
      }
    ]
  },
  # 9 — Família Almeida
  %{
    guardian: %{
      "name" => "Ricardo Almeida",
      "email" => "ricardo.almeida@email.com",
      "password" => "Resp@123",
      "cpf" => "99900011122",
      "phone" => "(11) 98001-0009"
    },
    students: [
      %{
        "name" => "Enzo Almeida",
        "birth_date" => "2015-06-30",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Bahia", "address_number" => "430",
        "neighborhood" => "Oswaldo Cruz", "city" => "São Caetano do Sul", "cep" => "09590001"
      },
      %{
        "name" => "Otávio Almeida",
        "birth_date" => "2012-01-07",
        "category" => "Sub-14",
        "monthly_fee" => "180.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Bahia", "address_number" => "430",
        "neighborhood" => "Oswaldo Cruz", "city" => "São Caetano do Sul", "cep" => "09590001"
      }
    ]
  },
  # 10 — Família Nascimento
  %{
    guardian: %{
      "name" => "Tatiana Nascimento",
      "email" => "tatiana.nascimento@email.com",
      "password" => "Resp@123",
      "cpf" => "10011122233",
      "phone" => "(11) 98001-0010"
    },
    students: [
      %{
        "name" => "João Nascimento",
        "birth_date" => "2018-04-25",
        "category" => "Sub-8",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Tocantins", "address_number" => "65",
        "neighborhood" => "Santa Paula", "city" => "São Caetano do Sul", "cep" => "09521100"
      },
      %{
        "name" => "Murilo Nascimento",
        "birth_date" => "2009-05-13",
        "category" => "Sub-17",
        "monthly_fee" => "200.00",
        "training_days" => ["Segunda", "Quarta", "Sexta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Elite",
        "address" => "Rua Tocantins", "address_number" => "65",
        "neighborhood" => "Santa Paula", "city" => "São Caetano do Sul", "cep" => "09521100"
      }
    ]
  },
  # 11 — Família Lima
  %{
    guardian: %{
      "name" => "Adriana Lima",
      "email" => "adriana.lima@email.com",
      "password" => "Resp@123",
      "cpf" => "11122233345",
      "phone" => "(11) 98001-0011"
    },
    students: [
      %{
        "name" => "Ryan Lima",
        "birth_date" => "2017-07-17",
        "category" => "Sub-9",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Pernambuco", "address_number" => "300",
        "neighborhood" => "Boa Vista", "city" => "São Caetano do Sul", "cep" => "09530100"
      },
      %{
        "name" => "Cauã Lima",
        "birth_date" => "2014-10-01",
        "category" => "Sub-12",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Pernambuco", "address_number" => "300",
        "neighborhood" => "Boa Vista", "city" => "São Caetano do Sul", "cep" => "09530100"
      },
      %{
        "name" => "Kaique Lima",
        "birth_date" => "2011-02-22",
        "category" => "Sub-15",
        "monthly_fee" => "200.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Pernambuco", "address_number" => "300",
        "neighborhood" => "Boa Vista", "city" => "São Caetano do Sul", "cep" => "09530100"
      }
    ]
  },
  # 12 — Família Araújo
  %{
    guardian: %{
      "name" => "Carlos Araújo",
      "email" => "carlos.araujo@email.com",
      "password" => "Resp@123",
      "cpf" => "22233344456",
      "phone" => "(11) 98001-0012"
    },
    students: [
      %{
        "name" => "Luan Araújo",
        "birth_date" => "2019-06-08",
        "category" => "Sub-7",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Minas Gerais", "address_number" => "12",
        "neighborhood" => "Taquara Alta", "city" => "São Caetano do Sul", "cep" => "09540100"
      },
      %{
        "name" => "Yago Araújo",
        "birth_date" => "2016-12-29",
        "category" => "Sub-10",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Minas Gerais", "address_number" => "12",
        "neighborhood" => "Taquara Alta", "city" => "São Caetano do Sul", "cep" => "09540100"
      }
    ]
  },
  # 13 — Família Barros
  %{
    guardian: %{
      "name" => "Renata Barros",
      "email" => "renata.barros@email.com",
      "password" => "Resp@123",
      "cpf" => "33344455567",
      "phone" => "(11) 98001-0013"
    },
    students: [
      %{
        "name" => "Igor Barros",
        "birth_date" => "2015-08-11",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Paraná", "address_number" => "88",
        "neighborhood" => "Santo André", "city" => "Santo André", "cep" => "09210001"
      },
      %{
        "name" => "Kelvin Barros",
        "birth_date" => "2013-04-16",
        "category" => "Sub-13",
        "monthly_fee" => "180.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Paraná", "address_number" => "88",
        "neighborhood" => "Santo André", "city" => "Santo André", "cep" => "09210001"
      }
    ]
  },
  # 14 — Família Gomes
  %{
    guardian: %{
      "name" => "Flávio Gomes",
      "email" => "flavio.gomes@email.com",
      "password" => "Resp@123",
      "cpf" => "44455566678",
      "phone" => "(11) 98001-0014"
    },
    students: [
      %{
        "name" => "Alexsandro Gomes",
        "birth_date" => "2012-11-20",
        "category" => "Sub-14",
        "monthly_fee" => "180.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua São Paulo", "address_number" => "250",
        "neighborhood" => "Centro", "city" => "São Caetano do Sul", "cep" => "09521200"
      },
      %{
        "name" => "Wellington Gomes",
        "birth_date" => "2009-03-04",
        "category" => "Sub-17",
        "monthly_fee" => "200.00",
        "training_days" => ["Segunda", "Quarta", "Sexta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Elite",
        "address" => "Rua São Paulo", "address_number" => "250",
        "neighborhood" => "Centro", "city" => "São Caetano do Sul", "cep" => "09521200"
      }
    ]
  },
  # 15 — Família Carvalho
  %{
    guardian: %{
      "name" => "Patricia Carvalho",
      "email" => "patricia.carvalho@email.com",
      "password" => "Resp@123",
      "cpf" => "55566677789",
      "phone" => "(11) 98001-0015"
    },
    students: [
      %{
        "name" => "Matheus Carvalho",
        "birth_date" => "2018-09-03",
        "category" => "Sub-8",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Ceará", "address_number" => "450",
        "neighborhood" => "Vila Paula", "city" => "São Caetano do Sul", "cep" => "09550100"
      },
      %{
        "name" => "Renan Carvalho",
        "birth_date" => "2014-06-14",
        "category" => "Sub-12",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Ceará", "address_number" => "450",
        "neighborhood" => "Vila Paula", "city" => "São Caetano do Sul", "cep" => "09550100"
      },
      %{
        "name" => "Anderson Carvalho",
        "birth_date" => "2011-08-27",
        "category" => "Sub-15",
        "monthly_fee" => "200.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Ceará", "address_number" => "450",
        "neighborhood" => "Vila Paula", "city" => "São Caetano do Sul", "cep" => "09550100"
      }
    ]
  },
  # 16 — Família Dias
  %{
    guardian: %{
      "name" => "Marcos Dias",
      "email" => "marcos.dias@email.com",
      "password" => "Resp@123",
      "cpf" => "66677788890",
      "phone" => "(11) 98001-0016"
    },
    students: [
      %{
        "name" => "Giovani Dias",
        "birth_date" => "2017-05-21",
        "category" => "Sub-9",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Rio de Janeiro", "address_number" => "135",
        "neighborhood" => "Mauá", "city" => "Mauá", "cep" => "09370001"
      },
      %{
        "name" => "Thierry Dias",
        "birth_date" => "2015-10-09",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Rio de Janeiro", "address_number" => "135",
        "neighborhood" => "Mauá", "city" => "Mauá", "cep" => "09370001"
      }
    ]
  },
  # 17 — Família Martins
  %{
    guardian: %{
      "name" => "Eliane Martins",
      "email" => "eliane.martins@email.com",
      "password" => "Resp@123",
      "cpf" => "77788899901",
      "phone" => "(11) 98001-0017"
    },
    students: [
      %{
        "name" => "Nathan Martins",
        "birth_date" => "2019-01-31",
        "category" => "Sub-7",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Acre", "address_number" => "77",
        "neighborhood" => "Riviera", "city" => "São Caetano do Sul", "cep" => "09560100"
      },
      %{
        "name" => "Bryan Martins",
        "birth_date" => "2013-12-05",
        "category" => "Sub-13",
        "monthly_fee" => "180.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Acre", "address_number" => "77",
        "neighborhood" => "Riviera", "city" => "São Caetano do Sul", "cep" => "09560100"
      }
    ]
  },
  # 18 — Família Ribeiro
  %{
    guardian: %{
      "name" => "Fábio Ribeiro",
      "email" => "fabio.ribeiro@email.com",
      "password" => "Resp@123",
      "cpf" => "88899900012",
      "phone" => "(11) 98001-0018"
    },
    students: [
      %{
        "name" => "Wendell Ribeiro",
        "birth_date" => "2016-08-18",
        "category" => "Sub-10",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Espírito Santo", "address_number" => "320",
        "neighborhood" => "São José", "city" => "São Caetano do Sul", "cep" => "09570100"
      },
      %{
        "name" => "Jefferson Ribeiro",
        "birth_date" => "2012-05-02",
        "category" => "Sub-14",
        "monthly_fee" => "180.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Espírito Santo", "address_number" => "320",
        "neighborhood" => "São José", "city" => "São Caetano do Sul", "cep" => "09570100"
      }
    ]
  },
  # 19 — Família Cardoso
  %{
    guardian: %{
      "name" => "Simone Cardoso",
      "email" => "simone.cardoso@email.com",
      "password" => "Resp@123",
      "cpf" => "99900011123",
      "phone" => "(11) 98001-0019"
    },
    students: [
      %{
        "name" => "Lucca Cardoso",
        "birth_date" => "2018-11-26",
        "category" => "Sub-8",
        "monthly_fee" => "120.00",
        "training_days" => ["Terça", "Quinta"],
        "training_location" => "Campo Auxiliar",
        "training_plan" => "Iniciante",
        "address" => "Rua Bahia", "address_number" => "190",
        "neighborhood" => "Santa Maria", "city" => "São Caetano do Sul", "cep" => "09580100"
      },
      %{
        "name" => "Erick Cardoso",
        "birth_date" => "2017-02-13",
        "category" => "Sub-9",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Básico",
        "address" => "Rua Bahia", "address_number" => "190",
        "neighborhood" => "Santa Maria", "city" => "São Caetano do Sul", "cep" => "09580100"
      },
      %{
        "name" => "Kauan Cardoso",
        "birth_date" => "2009-09-19",
        "category" => "Sub-17",
        "monthly_fee" => "200.00",
        "training_days" => ["Segunda", "Quarta", "Sexta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Elite",
        "address" => "Rua Bahia", "address_number" => "190",
        "neighborhood" => "Santa Maria", "city" => "São Caetano do Sul", "cep" => "09580100"
      }
    ]
  },
  # 20 — Família Pinto
  %{
    guardian: %{
      "name" => "Gustavo Pinto",
      "email" => "gustavo.pinto@email.com",
      "password" => "Resp@123",
      "cpf" => "10011122234",
      "phone" => "(11) 98001-0020"
    },
    students: [
      %{
        "name" => "Marcio Pinto",
        "birth_date" => "2015-03-07",
        "category" => "Sub-11",
        "monthly_fee" => "150.00",
        "training_days" => ["Segunda", "Quarta", "Sexta"],
        "training_location" => "Campo Principal",
        "training_plan" => "Intermediário",
        "address" => "Rua Rodrigues Alves", "address_number" => "600",
        "neighborhood" => "Nova Gerti", "city" => "São Caetano do Sul", "cep" => "09590100"
      },
      %{
        "name" => "Danilo Pinto",
        "birth_date" => "2011-11-15",
        "category" => "Sub-15",
        "monthly_fee" => "200.00",
        "training_days" => ["Terça", "Quinta", "Sábado"],
        "training_location" => "Campo Principal",
        "training_plan" => "Avançado",
        "address" => "Rua Rodrigues Alves", "address_number" => "600",
        "neighborhood" => "Nova Gerti", "city" => "São Caetano do Sul", "cep" => "09590100"
      }
    ]
  }
]

student_count =
  Enum.reduce(families, 0, fn family, acc ->
    email = family.guardian["email"]

    guardian_id =
      case Accounts.get_user_by_email(email) do
        nil ->
          case Accounts.register_guardian(family.guardian) do
            {:ok, %{guardian: guardian}} ->
              IO.puts("  ok Responsável: #{email}")
              guardian.id

            {:error, reason} ->
              IO.puts("  ERRO ao criar responsável #{email}: #{inspect(reason)}")
              nil
          end

        existing_user ->
          guardian = Accounts.get_guardian_by_user_id(existing_user.id)
          IO.puts("  -- Responsável já existe: #{email}")
          guardian && guardian.id
      end

    if guardian_id do
      created =
        Enum.reduce(family.students, 0, fn attrs, count ->
          case Students.create_student(attrs, guardian_id) do
            {:ok, student} ->
              IO.puts("    + #{student.name} [#{student.category}] #{student.enrollment_number}")
              count + 1

            {:error, reason} ->
              IO.puts("    ! ERRO ao criar aluno #{attrs["name"]}: #{inspect(reason)}")
              count
          end
        end)

      acc + created
    else
      acc
    end
  end)

IO.puts("\nSeed concluído: #{student_count} alunos criados em #{length(families)} famílias.")

# ── Campeonato Copa Integração São Caetano 2026 ─────────────────────────────

alias SysFc.Championships

champ_name = "Copa Integração São Caetano 2026"

case SysFc.Repo.get_by(SysFc.Championships.Championship, name: champ_name) do
  nil ->
    IO.puts("\nCriando campeonato #{champ_name}...")

    {:ok, champ} =
      Championships.create_championship(%{
        "name" => champ_name,
        "status" => "upcoming",
        "phase" => "group_stage",
        "format" => "groups_only",
        "start_date" => "2026-03-01",
        "end_date" => "2026-06-30",
        "default_match_duration" => 30
      })

    IO.puts("  ok Campeonato: #{champ.name}")

    {:ok, sub9} = Championships.create_sub(champ.id, %{"name" => "Sub-9"})
    {:ok, sub11} = Championships.create_sub(champ.id, %{"name" => "Sub-11"})
    IO.puts("  ok Categorias Sub-9 e Sub-11")

    {:ok, group9} =
      Championships.create_group(champ.id, %{
        "name" => "Grupo Único",
        "championship_sub_id" => sub9.id
      })

    {:ok, group11} =
      Championships.create_group(champ.id, %{
        "name" => "Grupo Único",
        "championship_sub_id" => sub11.id
      })

    all_students = SysFc.Repo.all(SysFc.Students.Student)

    sub9_students =
      all_students
      |> Enum.filter(&(&1.category == "Sub-9"))
      |> Enum.sort_by(& &1.name)
      |> Enum.take(12)

    sub11_students =
      all_students
      |> Enum.filter(&(&1.category == "Sub-11"))
      |> Enum.sort_by(& &1.name)
      |> Enum.take(12)

    make_players = fn team_id, students, num_players ->
      students
      |> Enum.with_index(1)
      |> Enum.each(fn {student, i} ->
        {:ok, _} =
          Championships.create_player(team_id, %{
            "name" => student.name,
            "jersey_number" => i,
            "student_id" => student.id
          })
      end)

      current = length(students)

      if current < num_players do
        Enum.each((current + 1)..num_players//1, fn i ->
          {:ok, _} =
            Championships.create_player(team_id, %{
              "name" => "Reserva #{i}",
              "jersey_number" => i
            })
        end)
      end
    end

    {team_a_s9_players, team_b_s9_players} = Enum.split(sub9_students, 6)

    {:ok, team_a9} =
      Championships.create_team(champ.id, %{
        "name" => "Leões SC Sub-9",
        "championship_sub_id" => sub9.id,
        "group_id" => group9.id
      })

    {:ok, team_b9} =
      Championships.create_team(champ.id, %{
        "name" => "Tigres SC Sub-9",
        "championship_sub_id" => sub9.id,
        "group_id" => group9.id
      })

    make_players.(team_a9.id, team_a_s9_players, 6)
    make_players.(team_b9.id, team_b_s9_players, 6)
    IO.puts("  ok Sub-9: #{team_a9.name} (#{length(team_a_s9_players)} alunos) vs #{team_b9.name} (#{length(team_b_s9_players)} alunos)")

    {team_a_s11_players, team_b_s11_players} = Enum.split(sub11_students, 6)

    {:ok, team_a11} =
      Championships.create_team(champ.id, %{
        "name" => "Leões SC Sub-11",
        "championship_sub_id" => sub11.id,
        "group_id" => group11.id
      })

    {:ok, team_b11} =
      Championships.create_team(champ.id, %{
        "name" => "Tigres SC Sub-11",
        "championship_sub_id" => sub11.id,
        "group_id" => group11.id
      })

    make_players.(team_a11.id, team_a_s11_players, 6)
    make_players.(team_b11.id, team_b_s11_players, 6)
    IO.puts("  ok Sub-11: #{team_a11.name} (#{length(team_a_s11_players)} alunos) vs #{team_b11.name} (#{length(team_b_s11_players)} alunos)")

    IO.puts("  ok Campeonato #{champ_name} criado com sucesso!")

  _ ->
    IO.puts("  -- Campeonato #{champ_name} já existe, pulando...")
end
