defmodule SysFcWeb.ChampionshipJSON do
  def index(%{championships: list}), do: %{data: Enum.map(list, &champ_data/1)}
  def show(%{championship: c}), do: %{data: champ_data(c)}

  def subs(%{subs: list}), do: %{data: Enum.map(list, &sub_data/1)}
  def sub(%{sub: s}), do: %{data: sub_data(s)}

  def groups(%{groups: list}), do: %{data: Enum.map(list, &group_data/1)}
  def group(%{group: g}), do: %{data: group_data(g)}

  def teams(%{teams: list}), do: %{data: Enum.map(list, &team_data/1)}
  def team(%{team: t}), do: %{data: team_data(t)}

  def players(%{players: list}), do: %{data: Enum.map(list, &player_data/1)}
  def player(%{player: p}), do: %{data: player_data(p)}

  def standings(%{standings: list}) do
    %{
      data:
        Enum.map(list, fn entry ->
          %{
            group: group_data(entry.group),
            standings: Enum.map(entry.standings, &standing_row/1)
          }
        end)
    }
  end

  def group_standings(%{group: g, standings: rows}) do
    %{data: %{group: group_data(g), standings: Enum.map(rows, &standing_row/1)}}
  end

  # ── Private helpers ───────────────────────────────────────

  defp champ_data(c) do
    %{
      id: c.id,
      name: c.name,
      status: c.status,
      phase: c.phase,
      format: c.format,
      start_date: c.start_date,
      end_date: c.end_date,
      default_match_duration: c.default_match_duration,
      inserted_at: c.inserted_at
    }
  end

  defp sub_data(s), do: %{id: s.id, name: s.name, championship_id: s.championship_id}

  defp group_data(g) do
    base = %{id: g.id, name: g.name, championship_id: g.championship_id}

    base
    |> maybe_put(:championship_sub, g, fn s -> %{id: s.id, name: s.name} end)
    |> maybe_put(:teams, g, fn teams ->
      case teams do
        %Ecto.Association.NotLoaded{} -> nil
        list -> Enum.map(list, &team_summary/1)
      end
    end)
  end

  defp team_data(t) do
    %{
      id: t.id,
      name: t.name,
      championship_id: t.championship_id,
      group: maybe_assoc(t.group, &group_summary/1),
      championship_sub: maybe_assoc(t.championship_sub, fn s -> %{id: s.id, name: s.name} end),
      players: players_list(t.players)
    }
  end

  defp team_summary(t), do: %{id: t.id, name: t.name}

  defp group_summary(g), do: %{id: g.id, name: g.name}

  defp player_data(p) do
    %{
      id: p.id,
      name: p.name,
      jersey_number: p.jersey_number,
      team_id: p.team_id,
      student_id: p.student_id
    }
  end

  defp standing_row(row) do
    %{
      team: team_summary(row.team),
      played: row.played,
      wins: row.wins,
      draws: row.draws,
      losses: row.losses,
      goals_for: row.goals_for,
      goals_against: row.goals_against,
      goal_difference: row.goal_difference,
      points: row.points
    }
  end

  defp players_list(%Ecto.Association.NotLoaded{}), do: []
  defp players_list(list) when is_list(list), do: Enum.map(list, &player_data/1)

  defp maybe_put(map, key, struct, fun) do
    val = Map.get(struct, key)

    case val do
      nil -> map
      %Ecto.Association.NotLoaded{} -> map
      v -> Map.put(map, key, fun.(v))
    end
  end

  defp maybe_assoc(nil, _fun), do: nil
  defp maybe_assoc(%Ecto.Association.NotLoaded{}, _fun), do: nil
  defp maybe_assoc(val, fun), do: fun.(val)
end
