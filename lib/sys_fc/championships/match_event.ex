defmodule SysFc.Championships.MatchEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "match_events" do
    field :type, Ecto.Enum, values: [:goal, :yellow_card, :red_card]
    field :minute, :integer

    belongs_to :match, SysFc.Championships.Match
    belongs_to :team, SysFc.Championships.Team
    belongs_to :player, SysFc.Championships.Player

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:match_id, :type, :team_id, :player_id, :minute])
    |> validate_required([:match_id, :type, :team_id, :player_id, :minute])
    |> validate_number(:minute, greater_than_or_equal_to: 0)
  end
end
