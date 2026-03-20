defmodule SysFc.Uniforms.UniformOrder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "uniform_orders" do
    field :total_amount, :decimal
    field :status, Ecto.Enum,
      values: [:pedido_realizado, :pagamento_realizado, :pronto_retirada, :entregue],
      default: :pedido_realizado
    field :requested_at, :utc_datetime

    belongs_to :guardian, SysFc.Accounts.Guardian
    belongs_to :student, SysFc.Students.Student
    has_many :items, SysFc.Uniforms.UniformOrderItem, foreign_key: :uniform_order_id

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:guardian_id, :student_id, :total_amount, :status, :requested_at])
    |> validate_required([:guardian_id, :student_id, :total_amount, :requested_at])
    |> validate_number(:total_amount, greater_than_or_equal_to: 0)
  end
end
