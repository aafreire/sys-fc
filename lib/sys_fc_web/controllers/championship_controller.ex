defmodule SysFcWeb.ChampionshipController do
  use SysFcWeb, :controller

  alias SysFc.Championships

  # ── Championships ─────────────────────────────────────────

  # GET /api/admin/championships
  def index(conn, params) do
    opts = []
    opts = if params["status"], do: [{:status, parse_atom(params["status"])} | opts], else: opts
    championships = Championships.list_championships(opts)
    render(conn, :index, championships: championships)
  end

  # GET /api/admin/championships/:id
  def show(conn, %{"id" => id}) do
    case Championships.get_championship(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      c   -> render(conn, :show, championship: c)
    end
  end

  # POST /api/admin/championships
  def create(conn, params) do
    case Championships.create_championship(params) do
      {:ok, c} ->
        conn |> put_status(:created) |> render(:show, championship: c)

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # PUT /api/admin/championships/:id
  def update(conn, %{"id" => id} = params) do
    case Championships.get_championship(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      c ->
        case Championships.update_championship(c, Map.delete(params, "id")) do
          {:ok, updated}  -> render(conn, :show, championship: updated)
          {:error, cs}    -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
        end
    end
  end

  # PUT /api/admin/championships/:id/advance-phase
  def advance_phase(conn, %{"id" => id}) do
    case Championships.get_championship(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      c ->
        case Championships.advance_phase(c) do
          {:ok, updated}         -> render(conn, :show, championship: updated)
          {:error, :already_finished} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "already_finished"})
          {:error, cs}           -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
        end
    end
  end

  # ── Subs ──────────────────────────────────────────────────

  # GET /api/admin/championships/:id/subs
  def list_subs(conn, %{"id" => id}) do
    subs = Championships.list_subs(id)
    render(conn, :subs, subs: subs)
  end

  # POST /api/admin/championships/:id/subs
  def create_sub(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["name"])

    case Championships.create_sub(id, attrs) do
      {:ok, sub}  -> conn |> put_status(:created) |> render(:sub, sub: sub)
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Groups ────────────────────────────────────────────────

  # GET /api/admin/championships/:id/groups
  def list_groups(conn, %{"id" => id}) do
    groups = Championships.list_groups(id)
    render(conn, :groups, groups: groups)
  end

  # POST /api/admin/championships/:id/groups
  def create_group(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["name", "championship_sub_id"])

    case Championships.create_group(id, attrs) do
      {:ok, group} -> conn |> put_status(:created) |> render(:group, group: group)
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Teams ─────────────────────────────────────────────────

  # GET /api/admin/championships/:id/teams
  def list_teams(conn, %{"id" => id} = params) do
    opts = []
    opts = if params["group_id"], do: [{:group_id, params["group_id"]} | opts], else: opts
    opts = if params["sub_id"],   do: [{:sub_id, params["sub_id"]} | opts],     else: opts
    teams = Championships.list_teams(id, opts)
    render(conn, :teams, teams: teams)
  end

  # POST /api/admin/championships/:id/teams
  def create_team(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["name", "group_id", "championship_sub_id"])

    case Championships.create_team(id, attrs) do
      {:ok, team}  -> conn |> put_status(:created) |> render(:team, team: team)
      {:error, cs} -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Players ───────────────────────────────────────────────

  # GET /api/admin/teams/:id/players
  def list_players(conn, %{"id" => team_id}) do
    players = Championships.list_players(team_id)
    render(conn, :players, players: players)
  end

  # POST /api/admin/teams/:id/players
  def create_player(conn, %{"id" => team_id} = params) do
    attrs = Map.take(params, ["name", "jersey_number", "student_id"])

    case Championships.create_player(team_id, attrs) do
      {:ok, player} -> conn |> put_status(:created) |> render(:player, player: player)
      {:error, cs}  -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Standings ─────────────────────────────────────────────

  # GET /api/admin/championships/:id/standings
  def standings(conn, %{"id" => id}) do
    case Championships.get_championship(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      _   -> render(conn, :standings, standings: Championships.championship_standings(id))
    end
  end

  # GET /api/admin/groups/:id/standings
  def group_standings(conn, %{"id" => group_id}) do
    case Championships.get_group(group_id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      g   -> render(conn, :group_standings, group: g, standings: Championships.group_standings(group_id))
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp parse_atom(s) when is_binary(s), do: String.to_existing_atom(s)
  defp parse_atom(a) when is_atom(a), do: a

  defp format_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
