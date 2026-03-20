defmodule SysFc.Championships do
  @moduledoc """
  Contexto de campeonatos.
  Gerencia campeonatos, grupos, times, jogadores, partidas,
  eventos de partida, pênaltis e fase eliminatória.
  """
  import Ecto.Query

  alias SysFc.Repo
  alias SysFc.Championships.{
    Championship, ChampionshipSub, Group, Team, Player,
    Match, MatchEvent, PenaltyShootout, PenaltyShot, KnockoutMatch
  }

  # ── Championships ─────────────────────────────────────────

  def list_championships(opts \\ []) do
    Championship
    |> apply_champ_filters(opts)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def get_championship(id), do: Repo.get(Championship, id)

  def get_championship!(id), do: Repo.get!(Championship, id)

  def create_championship(attrs) do
    %Championship{}
    |> Championship.changeset(attrs)
    |> Repo.insert()
  end

  def update_championship(%Championship{} = c, attrs) do
    c |> Championship.changeset(attrs) |> Repo.update()
  end

  def advance_phase(%Championship{phase: :group_stage} = c) do
    c |> Championship.changeset(%{phase: :knockout}) |> Repo.update()
  end

  def advance_phase(%Championship{phase: :knockout} = c) do
    c |> Championship.changeset(%{phase: :finished, status: :finished}) |> Repo.update()
  end

  def advance_phase(%Championship{}), do: {:error, :already_finished}

  # ── Subs ──────────────────────────────────────────────────

  def list_subs(championship_id) do
    ChampionshipSub
    |> where([s], s.championship_id == ^championship_id)
    |> order_by([s], s.name)
    |> Repo.all()
  end

  def create_sub(championship_id, attrs) do
    %ChampionshipSub{}
    |> ChampionshipSub.changeset(Map.put(attrs, "championship_id", championship_id))
    |> Repo.insert()
  end

  # ── Groups ────────────────────────────────────────────────

  def list_groups(championship_id) do
    Group
    |> where([g], g.championship_id == ^championship_id)
    |> order_by([g], g.name)
    |> preload([:championship_sub, teams: []])
    |> Repo.all()
  end

  def get_group(id), do: Repo.get(Group, id)

  def create_group(championship_id, attrs) do
    %Group{}
    |> Group.changeset(Map.put(attrs, "championship_id", championship_id))
    |> Repo.insert()
  end

  # ── Teams ─────────────────────────────────────────────────

  def list_teams(championship_id, opts \\ []) do
    Team
    |> where([t], t.championship_id == ^championship_id)
    |> apply_team_filters(opts)
    |> order_by([t], t.name)
    |> preload([:group, :championship_sub, players: []])
    |> Repo.all()
  end

  def get_team(id) do
    Team
    |> preload([:group, :championship_sub, players: []])
    |> Repo.get(id)
  end

  def create_team(championship_id, attrs) do
    %Team{}
    |> Team.changeset(Map.put(attrs, "championship_id", championship_id))
    |> Repo.insert()
  end

  # ── Players ───────────────────────────────────────────────

  def list_players(team_id) do
    Player
    |> where([p], p.team_id == ^team_id)
    |> order_by([p], p.name)
    |> Repo.all()
  end

  def create_player(team_id, attrs) do
    %Player{}
    |> Player.changeset(Map.put(attrs, "team_id", team_id))
    |> Repo.insert()
  end

  # ── Standings ─────────────────────────────────────────────

  def group_standings(group_id) do
    teams =
      Team
      |> where([t], t.group_id == ^group_id)
      |> Repo.all()

    matches =
      Match
      |> where([m], m.group_id == ^group_id and m.status == :finished)
      |> Repo.all()

    teams
    |> Enum.map(fn team ->
      team_matches =
        Enum.filter(matches, fn m ->
          m.home_team_id == team.id or m.away_team_id == team.id
        end)

      stats =
        Enum.reduce(team_matches, %{w: 0, d: 0, l: 0, gf: 0, ga: 0}, fn match, acc ->
          {gf, ga} =
            if match.home_team_id == team.id,
              do: {match.home_score, match.away_score},
              else: {match.away_score, match.home_score}

          cond do
            gf > ga -> %{acc | w: acc.w + 1, gf: acc.gf + gf, ga: acc.ga + ga}
            gf == ga -> %{acc | d: acc.d + 1, gf: acc.gf + gf, ga: acc.ga + ga}
            gf < ga -> %{acc | l: acc.l + 1, gf: acc.gf + gf, ga: acc.ga + ga}
          end
        end)

      points = stats.w * 3 + stats.d

      %{
        team: team,
        played: length(team_matches),
        wins: stats.w,
        draws: stats.d,
        losses: stats.l,
        goals_for: stats.gf,
        goals_against: stats.ga,
        goal_difference: stats.gf - stats.ga,
        points: points
      }
    end)
    |> Enum.sort_by(&{-&1.points, -&1.goal_difference, -&1.goals_for})
  end

  def championship_standings(championship_id) do
    groups = list_groups(championship_id)

    Enum.map(groups, fn group ->
      %{group: group, standings: group_standings(group.id)}
    end)
  end

  # ── Matches ───────────────────────────────────────────────

  def list_matches(championship_id, opts \\ []) do
    Match
    |> where([m], m.championship_id == ^championship_id)
    |> apply_match_filters(opts)
    |> order_by([m], [asc: m.date, asc: m.time])
    |> preload([:home_team, :away_team, :group, events: [:team, :player],
                penalty_shootout: [:shots, :winner_team]])
    |> Repo.all()
  end

  def get_match(id) do
    Match
    |> preload([:home_team, :away_team, :group,
                events: [:team, :player],
                penalty_shootout: [:shots, :winner_team]])
    |> Repo.get(id)
  end

  def create_match(championship_id, attrs) do
    %Match{}
    |> Match.changeset(Map.put(attrs, "championship_id", championship_id))
    |> Repo.insert()
    |> case do
      {:ok, m} -> {:ok, Repo.preload(m, [:home_team, :away_team, :group])}
      error -> error
    end
  end

  def update_match(%Match{} = match, attrs) do
    match
    |> Match.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, m} ->
        {:ok, Repo.preload(m, [:home_team, :away_team, :group,
                                events: [:team, :player],
                                penalty_shootout: [:shots, :winner_team]])}
      error -> error
    end
  end

  def update_match_status(%Match{} = match, status) do
    update_match(match, %{status: status})
  end

  def add_event(match_id, attrs) do
    case Repo.get(Match, match_id) do
      nil ->
        {:error, :match_not_found}

      %Match{locked: true} ->
        {:error, :match_locked}

      match ->
        result =
          %MatchEvent{}
          |> MatchEvent.changeset(Map.put(attrs, "match_id", match_id))
          |> Repo.insert()

        case result do
          {:ok, event} ->
            if event.type == :goal, do: increment_score(match, event)
            {:ok, Repo.preload(event, [:team, :player])}

          error ->
            error
        end
    end
  end

  defp increment_score(match, event) do
    field =
      if event.team_id == match.home_team_id,
        do: :home_score,
        else: :away_score

    current = Map.get(match, field)

    match
    |> Match.changeset(%{field => current + 1})
    |> Repo.update()
  end

  # ── Penalty Shootout ──────────────────────────────────────

  def create_shootout(match_id, attrs) do
    %PenaltyShootout{}
    |> PenaltyShootout.changeset(Map.put(attrs, "match_id", match_id))
    |> Repo.insert()
    |> case do
      {:ok, s} -> {:ok, Repo.preload(s, [:shots, :winner_team])}
      error -> error
    end
  end

  def update_shootout(%PenaltyShootout{} = s, attrs) do
    s
    |> PenaltyShootout.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, s} -> {:ok, Repo.preload(s, [:shots, :winner_team])}
      error -> error
    end
  end

  def add_penalty_shot(shootout_id, attrs) do
    case Repo.get(PenaltyShootout, shootout_id) do
      nil ->
        {:error, :shootout_not_found}

      shootout ->
        result =
          %PenaltyShot{}
          |> PenaltyShot.changeset(Map.put(attrs, "penalty_shootout_id", shootout_id))
          |> Repo.insert()

        case result do
          {:ok, shot} ->
            if shot.scored, do: bump_shootout_score(shootout, shot)
            {:ok, shot}

          error ->
            error
        end
    end
  end

  defp bump_shootout_score(shootout, shot) do
    match = Repo.get!(Match, shootout.match_id)

    field =
      if shot.team_id == match.home_team_id,
        do: :home_team_score,
        else: :away_team_score

    current = Map.get(shootout, field)

    shootout
    |> PenaltyShootout.changeset(%{field => current + 1})
    |> Repo.update()
  end

  # ── Knockout Matches ──────────────────────────────────────

  def list_knockout_matches(championship_id) do
    KnockoutMatch
    |> where([km], km.championship_id == ^championship_id)
    |> order_by([km], [km.round, km.match_number])
    |> preload([:team1, :team2, :winner, match: [:home_team, :away_team]])
    |> Repo.all()
  end

  def create_knockout_match(championship_id, attrs) do
    %KnockoutMatch{}
    |> KnockoutMatch.changeset(Map.put(attrs, "championship_id", championship_id))
    |> Repo.insert()
    |> case do
      {:ok, km} -> {:ok, Repo.preload(km, [:team1, :team2, :winner, match: [:home_team, :away_team]])}
      error -> error
    end
  end

  def set_knockout_winner(%KnockoutMatch{} = km, winner_id) do
    km
    |> KnockoutMatch.changeset(%{winner_id: winner_id})
    |> Repo.update()
    |> case do
      {:ok, km} -> {:ok, Repo.preload(km, [:team1, :team2, :winner, match: [:home_team, :away_team]])}
      error -> error
    end
  end

  # ── Private filters ───────────────────────────────────────

  defp apply_champ_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:status, s}, q -> where(q, [c], c.status == ^s)
      _, q -> q
    end)
  end

  defp apply_team_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:group_id, gid}, q -> where(q, [t], t.group_id == ^gid)
      {:sub_id, sid}, q -> where(q, [t], t.championship_sub_id == ^sid)
      _, q -> q
    end)
  end

  defp apply_match_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:group_id, gid}, q -> where(q, [m], m.group_id == ^gid)
      {:status, s}, q -> where(q, [m], m.status == ^s)
      {:phase, p}, q -> where(q, [m], m.phase == ^p)
      _, q -> q
    end)
  end
end
