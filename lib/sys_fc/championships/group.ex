defmodule SysFc.Championships.Group do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "groups" do
    field :name, :string

    belongs_to :championship, SysFc.Championships.Championship
    belongs_to :championship_sub, SysFc.Championships.ChampionshipSub
    has_many :teams, SysFc.Championships.Team
    has_many :matches, SysFc.Championships.Match

    timestamps(type: :utc_datetime)
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:championship_id, :championship_sub_id, :name])
    |> validate_required([:championship_id, :name])
  end
end
