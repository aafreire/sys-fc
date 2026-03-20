defmodule SysFc.Finance.Fee do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "fees" do
    field :reference_month, :integer
    field :reference_year, :integer
    field :amount, :decimal
    field :due_date, :date
    field :payment_date, :date
    field :status, Ecto.Enum,
      values: [:pending, :paid, :overdue, :under_analysis],
      default: :pending
    field :receipt_url, :string
    field :notes, :string

    belongs_to :student, SysFc.Students.Student

    timestamps(type: :utc_datetime)
  end

  def changeset(fee, attrs) do
    fee
    |> cast(attrs, [
      :student_id, :reference_month, :reference_year, :amount,
      :due_date, :payment_date, :status, :receipt_url, :notes
    ])
    |> validate_required([:student_id, :reference_month, :reference_year, :amount, :due_date])
    |> validate_inclusion(:reference_month, 1..12)
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:reference_year, greater_than: 2000)
    |> unique_constraint([:student_id, :reference_month, :reference_year])
  end
end
