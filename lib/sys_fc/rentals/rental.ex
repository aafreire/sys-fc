defmodule SysFc.Rentals.Rental do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @pricing_types ~w(hourly daily flat monthly)
  @payment_methods ~w(pix credit_card on_site)
  @statuses ~w(requested confirmed cancelled completed)
  @courts ~w(court_1 court_2)

  schema "rentals" do
    field :date, :date
    field :hours, :integer
    field :pricing_type, :string
    field :amount, :decimal
    field :payment_method, :string
    field :status, :string, default: "requested"
    field :notes, :string

    field :court, :string, default: "court_1"
    field :start_time, :time
    field :end_time, :time

    field :renter_name, :string
    field :renter_email, :string
    field :renter_phone, :string

    field :is_recurring, :boolean, default: false
    field :recurrence_weekdays, {:array, :integer}, default: []
    field :recurrence_start_date, :date
    field :recurrence_end_date, :date
    field :monthly_amount, :decimal

    field :created_by_admin, :boolean, default: false

    belongs_to :guardian, SysFc.Accounts.Guardian
    has_many :rental_fees, SysFc.Rentals.RentalFee, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset usado pelo fluxo do responsável (locação única, com guardian).
  """
  def changeset(rental, attrs) do
    rental
    |> cast(attrs, [
      :date, :hours, :pricing_type, :amount, :payment_method,
      :status, :notes, :guardian_id, :court, :start_time, :end_time
    ])
    |> validate_required([:date, :pricing_type, :amount, :payment_method, :guardian_id])
    |> validate_inclusion(:pricing_type, @pricing_types,
        message: "deve ser hourly, daily, flat ou monthly"
      )
    |> validate_inclusion(:payment_method, @payment_methods,
        message: "deve ser pix, credit_card ou on_site"
      )
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:court, @courts, message: "deve ser court_1 ou court_2")
    |> validate_number(:amount, greater_than: 0, message: "deve ser maior que zero")
    |> validate_hours()
    |> foreign_key_constraint(:guardian_id)
    |> unique_constraint([:date, :court],
        name: :rentals_date_court_active,
        message: "Esta quadra já está reservada nesta data"
      )
  end

  @doc """
  Changeset usado pelo admin para cadastrar uma locação manual (única ou recorrente).
  - guardian_id é opcional
  - renter_name é obrigatório (representa o locatário externo)
  - se is_recurring=true: exige recurrence_start_date e recurrence_weekdays
  - se is_recurring=false: exige date
  """
  def admin_changeset(rental, attrs) do
    rental
    |> cast(attrs, [
      :date, :hours, :pricing_type, :amount, :payment_method,
      :status, :notes, :guardian_id, :court, :start_time, :end_time,
      :renter_name, :renter_email, :renter_phone,
      :is_recurring, :recurrence_weekdays, :recurrence_start_date,
      :recurrence_end_date, :monthly_amount, :created_by_admin
    ])
    |> validate_required([:court, :renter_name, :amount, :pricing_type])
    |> validate_inclusion(:pricing_type, @pricing_types,
        message: "deve ser hourly, daily, flat ou monthly"
      )
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:court, @courts, message: "deve ser court_1 ou court_2")
    |> validate_number(:amount, greater_than: 0, message: "deve ser maior que zero")
    |> maybe_validate_payment_method()
    |> validate_recurrence()
    |> validate_single()
    |> foreign_key_constraint(:guardian_id)
    |> unique_constraint([:date, :court],
        name: :rentals_date_court_active,
        message: "Esta quadra já está reservada nesta data"
      )
  end

  defp maybe_validate_payment_method(changeset) do
    case get_field(changeset, :payment_method) do
      nil -> changeset
      _ ->
        validate_inclusion(changeset, :payment_method, @payment_methods,
          message: "deve ser pix, credit_card ou on_site"
        )
    end
  end

  defp validate_recurrence(changeset) do
    if get_field(changeset, :is_recurring) do
      changeset
      |> validate_required([:recurrence_start_date, :recurrence_weekdays, :monthly_amount],
        message: "obrigatório para locação recorrente"
      )
      |> validate_weekdays()
      |> validate_number(:monthly_amount,
        greater_than: 0,
        message: "deve ser maior que zero"
      )
    else
      changeset
    end
  end

  defp validate_single(changeset) do
    if get_field(changeset, :is_recurring) do
      changeset
    else
      validate_required(changeset, [:date], message: "informe a data da locação")
    end
  end

  defp validate_weekdays(changeset) do
    case get_field(changeset, :recurrence_weekdays) do
      nil -> changeset
      [] ->
        add_error(changeset, :recurrence_weekdays, "selecione ao menos um dia da semana")
      days ->
        if Enum.all?(days, &(&1 in 0..6)) do
          changeset
        else
          add_error(changeset, :recurrence_weekdays, "valores inválidos")
        end
    end
  end

  defp validate_hours(changeset) do
    case get_field(changeset, :pricing_type) do
      "hourly" ->
        changeset
        |> validate_required([:hours], message: "informe a quantidade de horas")
        |> validate_number(:hours,
            greater_than: 0,
            less_than_or_equal_to: 24,
            message: "deve ser entre 1 e 24"
          )

      _ ->
        changeset
    end
  end
end
