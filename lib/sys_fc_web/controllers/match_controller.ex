defmodule SysFcWeb.MatchController do
  use SysFcWeb, :controller

  alias SysFc.Championships

  # ── Matches ───────────────────────────────────────────────

  # GET /api/admin/championships/:id/matches
  def index(conn, %{"id" => championship_id} = params) do
    opts = []
    opts = if params["status"],   do: [{:status, parse_status(params["status"])} | opts],   else: opts
    opts = if params["phase"],    do: [{:phase, parse_phase(params["phase"])} | opts],     else: opts
    opts = if params["group_id"], do: [{:group_id, params["group_id"]} | opts],            else: opts

    matches = Championships.list_matches(championship_id, opts)
    render(conn, :index, matches: matches)
  end

  # GET /api/admin/matches/:id
  def show(conn, %{"id" => id}) do
    case Championships.get_match(id) do
      nil   -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      match -> render(conn, :show, match: match)
    end
  end

  # POST /api/admin/championships/:id/matches
  def create(conn, %{"id" => championship_id} = params) do
    attrs = Map.take(params, [
      "home_team_id", "away_team_id", "group_id",
      "date", "time", "location", "phase", "knockout_round",
      "match_number", "total_duration"
    ])

    case Championships.create_match(championship_id, attrs) do
      {:ok, match} ->
        conn |> put_status(:created) |> render(:show, match: match)

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # PUT /api/admin/matches/:id
  def update(conn, %{"id" => id} = params) do
    attrs = Map.take(params, [
      "home_team_id", "away_team_id", "group_id",
      "date", "time", "location", "phase", "knockout_round",
      "match_number", "total_duration",
      "first_half_injury_time", "second_half_injury_time", "locked"
    ])

    with_match(conn, id, fn match ->
      case Championships.update_match(match, attrs) do
        {:ok, updated} -> render(conn, :show, match: updated)
        {:error, cs}   -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
      end
    end)
  end

  # PUT /api/admin/matches/:id/status
  def update_status(conn, %{"id" => id, "status" => status}) do
    with_match(conn, id, fn match ->
      case Championships.update_match_status(match, parse_status(status)) do
        {:ok, updated} -> render(conn, :show, match: updated)
        {:error, cs}   -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
      end
    end)
  end

  def update_status(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "status is required"})
  end

  # POST /api/admin/matches/:id/events
  def add_event(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["type", "team_id", "player_id", "minute"])

    case Championships.add_event(id, attrs) do
      {:ok, event} ->
        conn |> put_status(:created) |> render(:event, event: event)

      {:error, :match_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      {:error, :match_locked} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "match_locked"})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Penalty Shootout ──────────────────────────────────────

  # POST /api/admin/matches/:id/penalties
  def create_shootout(conn, %{"id" => match_id} = params) do
    attrs = Map.take(params, ["home_team_score", "away_team_score"])

    case Championships.create_shootout(match_id, attrs) do
      {:ok, shootout} ->
        conn |> put_status(:created) |> render(:shootout, shootout: shootout)

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # PUT /api/admin/penalties/:id
  def update_shootout(conn, %{"id" => id} = params) do
    attrs = Map.take(params, ["home_team_score", "away_team_score", "finished", "winner_team_id"])

    case SysFc.Repo.get(SysFc.Championships.PenaltyShootout, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      shootout ->
        case Championships.update_shootout(shootout, attrs) do
          {:ok, updated} -> render(conn, :shootout, shootout: updated)
          {:error, cs}   -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
        end
    end
  end

  # POST /api/admin/penalties/:id/shots
  def add_penalty_shot(conn, %{"id" => shootout_id} = params) do
    attrs = Map.take(params, ["player_id", "team_id", "scored", "order"])

    case Championships.add_penalty_shot(shootout_id, attrs) do
      {:ok, shot} ->
        conn |> put_status(:created) |> render(:shot, shot: shot)

      {:error, :shootout_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # ── Knockout ──────────────────────────────────────────────

  # GET /api/admin/championships/:id/knockout
  def list_knockout(conn, %{"id" => championship_id}) do
    matches = Championships.list_knockout_matches(championship_id)
    render(conn, :knockout, knockout_matches: matches)
  end

  # POST /api/admin/championships/:id/knockout
  def create_knockout_match(conn, %{"id" => championship_id} = params) do
    attrs = Map.take(params, ["round", "match_number", "team1_id", "team2_id", "match_id"])

    case Championships.create_knockout_match(championship_id, attrs) do
      {:ok, km} ->
        conn |> put_status(:created) |> render(:knockout_match, knockout_match: km)

      {:error, cs} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
    end
  end

  # PUT /api/admin/knockout/:id/winner
  def set_knockout_winner(conn, %{"id" => id, "winner_id" => winner_id}) do
    case SysFc.Repo.get(SysFc.Championships.KnockoutMatch, id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      km ->
        case Championships.set_knockout_winner(km, winner_id) do
          {:ok, updated} -> render(conn, :knockout_match, knockout_match: updated)
          {:error, cs}   -> conn |> put_status(:unprocessable_entity) |> json(%{error: "validation_failed", details: format_errors(cs)})
        end
    end
  end

  def set_knockout_winner(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "winner_id is required"})
  end

  # ── Private helpers ───────────────────────────────────────

  defp with_match(conn, id, fun) do
    case Championships.get_match(id) do
      nil   -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      match -> fun.(match)
    end
  end

  defp parse_status(nil), do: nil
  defp parse_status(s) when is_atom(s), do: s
  defp parse_status(s) when is_binary(s) do
    case s do
      "not_started"  -> :not_started
      "first_half"   -> :first_half
      "halftime"     -> :halftime
      "second_half"  -> :second_half
      "penalties"    -> :penalties
      "finished"     -> :finished
      _              -> nil
    end
  end

  defp parse_phase(nil), do: nil
  defp parse_phase("group_stage"), do: :group_stage
  defp parse_phase("knockout"), do: :knockout
  defp parse_phase(_), do: nil

  defp format_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
