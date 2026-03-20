defmodule SysFc.Championships.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "players" do
    field :name, :string
    field :jersey_number, :integer

    belongs_to :team, SysFc.Championships.Team
    belongs_to :student, SysFc.Students.Student
    has_many :match_events, SysFc.Championships.MatchEvent
    has_many :penalty_shots, SysFc.Championships.PenaltyShot

    timestamps(type: :utc_datetime)
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:team_id, :student_id, :name, :jersey_number])
    |> validate_required([:team_id, :name])
  end
end
