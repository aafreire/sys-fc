defmodule SysFcWeb.MatchJSON do
  def index(%{matches: list}), do: %{data: Enum.map(list, &match_data/1)}
  def show(%{match: m}), do: %{data: match_data(m)}
  def event(%{event: e}), do: %{data: event_data(e)}
  def shootout(%{shootout: s}), do: %{data: shootout_data(s)}
  def shot(%{shot: s}), do: %{data: shot_data(s)}
  def knockout(%{knockout_matches: list}), do: %{data: Enum.map(list, &knockout_match_data/1)}
  def knockout_match(%{knockout_match: km}), do: %{data: knockout_match_data(km)}

  # ── Match ─────────────────────────────────────────────────

  defp match_data(m) do
    %{
      id: m.id,
      championship_id: m.championship_id,
      date: m.date,
      time: m.time,
      location: m.location,
      status: m.status,
      phase: m.phase,
      knockout_round: m.knockout_round,
      match_number: m.match_number,
      total_duration: m.total_duration,
      first_half_injury_time: m.first_half_injury_time,
      second_half_injury_time: m.second_half_injury_time,
      locked: m.locked,
      home_team: team_ref(m.home_team),
      away_team: team_ref(m.away_team),
      home_score: m.home_score,
      away_score: m.away_score,
      group: group_ref(m.group),
      events: events_list(m.events),
      penalty_shootout: shootout_ref(m.penalty_shootout)
    }
  end

  # ── Event ─────────────────────────────────────────────────

  defp event_data(e) do
    %{
      id: e.id,
      match_id: e.match_id,
      type: e.type,
      minute: e.minute,
      team: team_ref(e.team),
      player: player_ref(e.player)
    }
  end

  # ── Penalty Shootout ──────────────────────────────────────

  defp shootout_data(s) do
    %{
      id: s.id,
      match_id: s.match_id,
      home_team_score: s.home_team_score,
      away_team_score: s.away_team_score,
      finished: s.finished,
      winner_team: team_ref(s.winner_team),
      shots: shots_list(s.shots)
    }
  end

  defp shot_data(s) do
    %{
      id: s.id,
      penalty_shootout_id: s.penalty_shootout_id,
      player_id: s.player_id,
      team_id: s.team_id,
      scored: s.scored,
      order: s.order
    }
  end

  # ── Knockout Match ────────────────────────────────────────

  defp knockout_match_data(km) do
    %{
      id: km.id,
      championship_id: km.championship_id,
      round: km.round,
      match_number: km.match_number,
      team1: team_ref(km.team1),
      team2: team_ref(km.team2),
      winner: team_ref(km.winner),
      match: match_ref(km.match)
    }
  end

  # ── Helpers ───────────────────────────────────────────────

  defp team_ref(nil), do: nil
  defp team_ref(%Ecto.Association.NotLoaded{}), do: nil
  defp team_ref(t), do: %{id: t.id, name: t.name}

  defp group_ref(nil), do: nil
  defp group_ref(%Ecto.Association.NotLoaded{}), do: nil
  defp group_ref(g), do: %{id: g.id, name: g.name}

  defp player_ref(nil), do: nil
  defp player_ref(%Ecto.Association.NotLoaded{}), do: nil
  defp player_ref(p), do: %{id: p.id, name: p.name, jersey_number: p.jersey_number}

  defp match_ref(nil), do: nil
  defp match_ref(%Ecto.Association.NotLoaded{}), do: nil
  defp match_ref(m) do
    %{
      id: m.id,
      status: m.status,
      home_score: m.home_score,
      away_score: m.away_score,
      home_team: team_ref(m.home_team),
      away_team: team_ref(m.away_team)
    }
  end

  defp events_list(%Ecto.Association.NotLoaded{}), do: []
  defp events_list(list) when is_list(list), do: Enum.map(list, &event_data/1)

  defp shots_list(%Ecto.Association.NotLoaded{}), do: []
  defp shots_list(list) when is_list(list), do: Enum.map(list, &shot_data/1)

  defp shootout_ref(nil), do: nil
  defp shootout_ref(%Ecto.Association.NotLoaded{}), do: nil
  defp shootout_ref(s), do: shootout_data(s)
end
