defmodule SysFc.Championships.Match do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "matches" do
    field :home_score, :integer, default: 0
    field :away_score, :integer, default: 0
    field :date, :date
    field :time, :time
    field :location, :string
    field :status, Ecto.Enum,
      values: [:not_started, :first_half, :halftime, :second_half, :penalties, :finished],
      default: :not_started
    field :phase, Ecto.Enum, values: [:group_stage, :knockout], default: :group_stage
    field :knockout_round, Ecto.Enum,
      values: [:round_of_16, :quarter_finals, :semi_finals, :final]
    field :match_number, :integer
    field :total_duration, :integer
    field :first_half_injury_time, :integer, default: 0
    field :second_half_injury_time, :integer, default: 0
    field :locked, :boolean, default: false

    belongs_to :championship, SysFc.Championships.Championship
    belongs_to :home_team, SysFc.Championships.Team, foreign_key: :home_team_id
    belongs_to :away_team, SysFc.Championships.Team, foreign_key: :away_team_id
    belongs_to :group, SysFc.Championships.Group
    has_many :events, SysFc.Championships.MatchEvent, foreign_key: :match_id
    has_one :penalty_shootout, SysFc.Championships.PenaltyShootout

    timestamps(type: :utc_datetime)
  end

  def changeset(match, attrs) do
    match
    |> cast(attrs, [
      :championship_id, :home_team_id, :away_team_id,
      :home_score, :away_score, :date, :time, :location,
      :status, :phase, :group_id, :knockout_round, :match_number,
      :total_duration, :first_half_injury_time, :second_half_injury_time, :locked
    ])
    |> validate_required([:championship_id, :home_team_id, :away_team_id])
    |> validate_number(:home_score, greater_than_or_equal_to: 0)
    |> validate_number(:away_score, greater_than_or_equal_to: 0)
  end
end
