defmodule SysFc.Championships.Championship do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "championships" do
    field :name, :string
    field :status, Ecto.Enum, values: [:upcoming, :active, :finished], default: :upcoming
    field :phase, Ecto.Enum,
      values: [:group_stage, :knockout, :finished],
      default: :group_stage
    field :format, Ecto.Enum,
      values: [:groups_only, :groups_and_knockout, :knockout_only],
      default: :groups_and_knockout
    field :start_date, :date
    field :end_date, :date
    field :default_match_duration, :integer, default: 30

    has_many :subs, SysFc.Championships.ChampionshipSub, foreign_key: :championship_id
    has_many :groups, SysFc.Championships.Group
    has_many :teams, SysFc.Championships.Team
    has_many :matches, SysFc.Championships.Match
    has_many :knockout_matches, SysFc.Championships.KnockoutMatch

    timestamps(type: :utc_datetime)
  end

  def changeset(championship, attrs) do
    championship
    |> cast(attrs, [:name, :status, :phase, :format, :start_date, :end_date, :default_match_duration])
    |> validate_required([:name, :start_date])
    |> validate_number(:default_match_duration, greater_than: 0)
  end
end
