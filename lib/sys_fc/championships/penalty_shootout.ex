defmodule SysFc.Championships.PenaltyShootout do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "penalty_shootouts" do
    field :home_team_score, :integer, default: 0
    field :away_team_score, :integer, default: 0
    field :finished, :boolean, default: false

    belongs_to :match, SysFc.Championships.Match
    belongs_to :winner_team, SysFc.Championships.Team, foreign_key: :winner_team_id
    has_many :shots, SysFc.Championships.PenaltyShot, foreign_key: :penalty_shootout_id

    timestamps(type: :utc_datetime)
  end

  def changeset(shootout, attrs) do
    shootout
    |> cast(attrs, [:match_id, :home_team_score, :away_team_score, :finished, :winner_team_id])
    |> validate_required([:match_id])
    |> validate_number(:home_team_score, greater_than_or_equal_to: 0)
    |> validate_number(:away_team_score, greater_than_or_equal_to: 0)
    |> unique_constraint(:match_id)
  end
end
