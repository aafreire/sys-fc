defmodule SysFc.Championships.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string

    belongs_to :championship, SysFc.Championships.Championship
    belongs_to :championship_sub, SysFc.Championships.ChampionshipSub
    belongs_to :group, SysFc.Championships.Group
    has_many :players, SysFc.Championships.Player
    has_many :match_events, SysFc.Championships.MatchEvent

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:championship_id, :championship_sub_id, :name, :group_id])
    |> validate_required([:championship_id, :name])
  end
end
