defmodule SysFc.Championships.KnockoutMatch do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "knockout_matches" do
    field :round, Ecto.Enum, values: [:round_of_16, :quarter_finals, :semi_finals, :final]
    field :match_number, :integer

    belongs_to :championship, SysFc.Championships.Championship
    belongs_to :match, SysFc.Championships.Match
    belongs_to :team1, SysFc.Championships.Team, foreign_key: :team1_id
    belongs_to :team2, SysFc.Championships.Team, foreign_key: :team2_id
    belongs_to :winner, SysFc.Championships.Team, foreign_key: :winner_id

    timestamps(type: :utc_datetime)
  end

  def changeset(km, attrs) do
    km
    |> cast(attrs, [:championship_id, :match_id, :round, :match_number, :team1_id, :team2_id, :winner_id])
    |> validate_required([:championship_id, :round, :match_number])
  end
end
