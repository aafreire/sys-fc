defmodule SysFc.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(paid unpaid)

  schema "expenses" do
    field :title, :string
    field :amount, :decimal
    field :status, :string, default: "unpaid"
    field :reference_month, :integer
    field :reference_year, :integer
    field :is_recurring, :boolean, default: false
    field :recurrence_id, Ecto.UUID
    field :recurrence_total, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [
      :title, :amount, :status, :reference_month, :reference_year,
      :is_recurring, :recurrence_id, :recurrence_total
    ])
    |> validate_required([:title, :amount, :status, :reference_month, :reference_year])
    |> validate_inclusion(:status, @statuses, message: "deve ser paid ou unpaid")
    |> validate_inclusion(:reference_month, 1..12)
    |> validate_number(:amount, greater_than: 0, message: "deve ser maior que zero")
    |> validate_number(:reference_year, greater_than: 2000)
    |> unique_constraint([:recurrence_id, :reference_year, :reference_month])
  end

  @doc "Changeset para edição de uma ocorrência (título, valor, status)."
  def update_changeset(expense, attrs) do
    expense
    |> cast(attrs, [:title, :amount, :status])
    |> validate_required([:title, :amount, :status])
    |> validate_inclusion(:status, @statuses, message: "deve ser paid ou unpaid")
    |> validate_number(:amount, greater_than: 0, message: "deve ser maior que zero")
  end
end
