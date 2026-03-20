defmodule SysFc.Championships.ChampionshipSub do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "championship_subs" do
    field :name, :string

    belongs_to :championship, SysFc.Championships.Championship

    timestamps(type: :utc_datetime)
  end

  def changeset(sub, attrs) do
    sub
    |> cast(attrs, [:championship_id, :name])
    |> validate_required([:championship_id, :name])
  end
end
