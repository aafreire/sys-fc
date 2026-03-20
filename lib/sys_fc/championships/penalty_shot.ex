defmodule SysFc.Championships.PenaltyShot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "penalty_shots" do
    field :scored, :boolean
    field :order, :integer

    belongs_to :penalty_shootout, SysFc.Championships.PenaltyShootout
    belongs_to :player, SysFc.Championships.Player
    belongs_to :team, SysFc.Championships.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(shot, attrs) do
    shot
    |> cast(attrs, [:penalty_shootout_id, :player_id, :team_id, :scored, :order])
    |> validate_required([:penalty_shootout_id, :player_id, :team_id, :scored, :order])
    |> validate_number(:order, greater_than: 0)
  end
end
