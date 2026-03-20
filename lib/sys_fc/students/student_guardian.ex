defmodule SysFc.Students.StudentGuardian do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "student_guardians" do
    field :is_primary, :boolean, default: true

    belongs_to :student, SysFc.Students.Student
    belongs_to :guardian, SysFc.Accounts.Guardian

    timestamps(type: :utc_datetime)
  end

  def changeset(sg, attrs) do
    sg
    |> cast(attrs, [:student_id, :guardian_id, :is_primary])
    |> validate_required([:student_id, :guardian_id])
    |> unique_constraint([:student_id, :guardian_id])
  end
end
