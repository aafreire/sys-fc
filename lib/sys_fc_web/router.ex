defmodule SysFcWeb.Router do
  use SysFcWeb, :router

  alias SysFcWeb.Plugs.AuthPlug
  alias SysFcWeb.Plugs.RequireRolePlug

  # ── Pipelines ─────────────────────────────────────────────

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug AuthPlug
  end

  pipeline :admin do
    plug RequireRolePlug, [:admin_master, :admin_limited]
  end

  pipeline :admin_master do
    plug RequireRolePlug, [:admin_master]
  end

  pipeline :guardian do
    plug RequireRolePlug, [:guardian]
  end

  # ── Rotas públicas (sem autenticação) ─────────────────────

  scope "/api", SysFcWeb do
    pipe_through :api

    post "/auth/login", AuthController, :login
    post "/auth/register", AuthController, :register
    get  "/auth/check-phone", AuthController, :check_phone
    post "/auth/complete-registration", AuthController, :complete_registration
    post "/auth/forgot-password", AuthController, :forgot_password
    post "/auth/reset-password", AuthController, :reset_password
  end

  # ── Rotas autenticadas ────────────────────────────────────

  scope "/api", SysFcWeb do
    pipe_through [:api, :authenticated]

    get "/auth/me", AuthController, :me
    post "/auth/logout", AuthController, :logout
  end

  # ── Rotas de admin (master + limited) ─────────────────────

  scope "/api/admin", SysFcWeb do
    pipe_through [:api, :authenticated, :admin]

    # Alunos
    get    "/students",                    StudentController, :index
    get    "/students/pending",            StudentController, :pending
    post   "/students",                    StudentController, :create
    get    "/students/:id",                StudentController, :show
    put    "/students/:id",                StudentController, :update
    delete "/students/:id",                StudentController, :delete
    post   "/students/:id/link-guardian",  StudentController, :link_guardian
    put    "/students/:id/confirm",        StudentController, :confirm
    put    "/students/:id/reject",         StudentController, :reject
    put    "/students/:id/freeze",         StudentController, :freeze
    put    "/students/:id/unfreeze",       StudentController, :unfreeze
    post   "/students/:id/photo",          StudentController, :upload_photo

    # Responsáveis
    get  "/guardians",  GuardianController, :index
    post "/guardians",  GuardianController, :create

    # Mensalidades por aluno (admin + admin_limited podem ver)
    get "/students/:student_id/fees", FeeController, :by_student

    # Estoque — produtos
    get    "/products",                  ProductController, :index
    post   "/products",                  ProductController, :create
    get    "/products/:id",              ProductController, :show
    put    "/products/:id",              ProductController, :update
    delete "/products/:id",              ProductController, :delete
    post   "/products/:id/entries",      ProductController, :create_entry
    post   "/products/:id/exits",        ProductController, :create_exit
    get    "/products/:id/history",      ProductController, :history
    get    "/stock/summary",             ProductController, :summary

    # Pedidos de uniforme (admin)
    get "/uniforms/orders",            UniformOrderController, :index
    get "/uniforms/orders/:id",        UniformOrderController, :show
    put "/uniforms/orders/:id/status", UniformOrderController, :update_status

    # Planos e locais de treino (admin CRUD)
    post   "/training-plans",           TrainingPlanController, :create_plan
    put    "/training-plans/:id",       TrainingPlanController, :update_plan
    delete "/training-plans/:id",       TrainingPlanController, :delete_plan
    post   "/training-locations",       TrainingPlanController, :create_location
    put    "/training-locations/:id",   TrainingPlanController, :update_location
    delete "/training-locations/:id",   TrainingPlanController, :delete_location

    # Aluguel de quadra/salão — config, disponibilidade e gestão (admin)
    get    "/rental-config",              RentalController, :get_config
    put    "/rental-config",              RentalController, :update_config
    get    "/rental-unavailable",         RentalController, :list_unavailable
    post   "/rental-unavailable",         RentalController, :create_unavailable
    delete "/rental-unavailable/:id",     RentalController, :delete_unavailable
    get    "/rentals",                    RentalController, :admin_index
    put    "/rentals/:id/status",         RentalController, :admin_update_status

    # Campeonatos — gestão
    get  "/championships",                        ChampionshipController, :index
    post "/championships",                        ChampionshipController, :create
    get  "/championships/:id",                    ChampionshipController, :show
    put  "/championships/:id",                    ChampionshipController, :update
    put  "/championships/:id/advance-phase",      ChampionshipController, :advance_phase
    get  "/championships/:id/subs",               ChampionshipController, :list_subs
    post "/championships/:id/subs",               ChampionshipController, :create_sub
    get  "/championships/:id/groups",             ChampionshipController, :list_groups
    post "/championships/:id/groups",             ChampionshipController, :create_group
    get  "/championships/:id/teams",              ChampionshipController, :list_teams
    post "/championships/:id/teams",              ChampionshipController, :create_team
    get  "/championships/:id/standings",          ChampionshipController, :standings
    get  "/groups/:id/standings",                 ChampionshipController, :group_standings
    get  "/teams/:id/players",                    ChampionshipController, :list_players
    post "/teams/:id/players",                    ChampionshipController, :create_player

    # Campeonatos — partidas
    get  "/championships/:id/matches",            MatchController, :index
    post "/championships/:id/matches",            MatchController, :create
    get  "/matches/:id",                          MatchController, :show
    put  "/matches/:id",                          MatchController, :update
    put  "/matches/:id/status",                   MatchController, :update_status
    post "/matches/:id/events",                   MatchController, :add_event
    post "/matches/:id/penalties",                MatchController, :create_shootout
    put  "/penalties/:id",                        MatchController, :update_shootout
    post "/penalties/:id/shots",                  MatchController, :add_penalty_shot
    get  "/championships/:id/knockout",           MatchController, :list_knockout
    post "/championships/:id/knockout",           MatchController, :create_knockout_match
    put  "/knockout/:id/winner",                  MatchController, :set_knockout_winner
  end

  # ── Rotas de admin (master + limited) — financeiro ────────

  scope "/api/admin", SysFcWeb do
    pipe_through [:api, :authenticated, :admin]

    # Financeiro global (ambos os roles podem ver e marcar como pago)
    get  "/fees",                    FeeController, :index
    get  "/fees/home",               FeeController, :home_fees
    put  "/fees/batch-mark-paid",    FeeController, :batch_mark_paid
    get  "/fees/:id",                FeeController, :show
    put  "/fees/:id/mark-paid",      FeeController, :mark_paid
  end

  # ── Rotas exclusivas admin_master ─────────────────────────

  scope "/api/admin", SysFcWeb do
    pipe_through [:api, :authenticated, :admin_master]

    # Gestão de administradores
    get  "/users",            UserController, :index
    post "/users",            UserController, :create
    put  "/users/:id/status", UserController, :update_status

    # Geração de mensalidades (apenas admin_master)
    post "/fees/generate-monthly", FeeController, :generate_monthly
  end

  # ── Rotas do responsável (guardian) ───────────────────────

  scope "/api/guardian", SysFcWeb do
    pipe_through [:api, :authenticated, :guardian]

    get  "/students",                 GuardianController, :my_students
    post "/students",                 StudentController, :guardian_create
    put  "/students/:id",               StudentController, :guardian_update
    put  "/students/:id/toggle-freeze", StudentController, :guardian_freeze
    post "/students/:id/photo",          StudentController, :guardian_upload_photo
    get  "/fees",             FeeController, :guardian_index
    post "/fees/pay",         FeeController, :guardian_pay
    get  "/fees/:id",         FeeController, :guardian_show
    put  "/fees/:id/receipt", FeeController, :upload_receipt

    # Pedidos de uniforme (guardian)
    get  "/uniforms/orders",     UniformOrderController, :guardian_index
    get  "/uniforms/orders/:id", UniformOrderController, :guardian_show
    post "/uniforms/orders",     UniformOrderController, :guardian_create

    # Aluguel de quadra/salão (guardian)
    get  "/rentals", RentalController, :guardian_index
    post "/rentals", RentalController, :guardian_create

    # Cartões de crédito (guardian)
    get    "/cards",             CardController, :index
    post   "/cards",             CardController, :create
    delete "/cards/:id",         CardController, :delete
    put    "/cards/:id/default", CardController, :set_default
  end

  # ── Configurações e calendário — leitura pública (autenticado, qualquer role) ─

  scope "/api", SysFcWeb do
    pipe_through [:api, :authenticated]

    get "/training-plans",  TrainingPlanController, :index
    get "/rentals/calendar", RentalController, :calendar
  end

  # ── Campeonatos — leitura pública (autenticado, qualquer role) ──

  scope "/api", SysFcWeb do
    pipe_through [:api, :authenticated]

    get "/championships",                         ChampionshipController, :index
    get "/championships/:id",                     ChampionshipController, :show
    get "/championships/:id/groups",              ChampionshipController, :list_groups
    get "/championships/:id/teams",               ChampionshipController, :list_teams
    get "/championships/:id/standings",           ChampionshipController, :standings
    get "/groups/:id/standings",                  ChampionshipController, :group_standings
    get "/championships/:id/matches",             MatchController, :index
    get "/matches/:id",                           MatchController, :show
    get "/championships/:id/knockout",            MatchController, :list_knockout
  end

  # ── LiveDashboard (dev only) ──────────────────────────────

  if Application.compile_env(:sys_fc, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: SysFcWeb.Telemetry
    end
  end
end
