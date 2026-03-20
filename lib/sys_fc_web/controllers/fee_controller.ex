defmodule SysFcWeb.FeeController do
  use SysFcWeb, :controller

  alias SysFc.Finance
  alias SysFc.Accounts
  alias SysFc.Students

  # ── Admin: visão global (admin_master) ────────────────────

  # GET /api/admin/fees
  def index(conn, params) do
    opts =
      []
      |> maybe_filter(:student_id, params["student_id"])
      |> maybe_filter(:status, parse_status(params["status"]))
      |> maybe_filter(:year, parse_int(params["year"]))
      |> maybe_filter(:month, parse_int(params["month"]))
      |> maybe_filter(:page, parse_int(params["page"]))
      |> maybe_filter(:per_page, parse_int(params["per_page"]))

    %{data: fees, meta: meta} = Finance.list_fees(opts)
    render(conn, :index, fees: fees, meta: meta)
  end

  # GET /api/admin/fees/home
  def home_fees(conn, _params) do
    fees = Finance.list_home_fees()
    render(conn, :index, fees: fees)
  end

  # PUT /api/admin/fees/batch-mark-paid
  def batch_mark_paid(conn, %{"fee_ids" => fee_ids}) when is_list(fee_ids) do
    fees = Enum.map(fee_ids, &Finance.get_fee/1)

    if Enum.any?(fees, &is_nil/1) do
      conn |> put_status(:not_found) |> json(%{error: "fee_not_found"})
    else
      results = Enum.map(fees, &Finance.mark_as_paid/1)
      errors = Enum.filter(results, &match?({:error, _}, &1))

      if Enum.empty?(errors) do
        paid = Enum.map(results, fn {:ok, f} -> f end)
        render(conn, :index, fees: paid)
      else
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "batch_mark_paid_failed"})
      end
    end
  end

  def batch_mark_paid(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "fee_ids is required"})
  end

  # GET /api/admin/fees/:id
  def show(conn, %{"id" => id}) do
    case Finance.get_fee(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      fee -> render(conn, :show, fee: fee)
    end
  end

  # GET /api/admin/students/:student_id/fees
  def by_student(conn, %{"student_id" => student_id}) do
    case Students.get_student(student_id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "student_not_found"})

      _student ->
        fees = Finance.list_fees(student_id: student_id)
        render(conn, :index, fees: fees)
    end
  end

  # PUT /api/admin/fees/:id/mark-paid
  def mark_paid(conn, %{"id" => id} = params) do
    case Finance.get_fee(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      fee ->
        payment_date = parse_date(params["payment_date"])

        case Finance.mark_as_paid(fee, payment_date) do
          {:ok, updated} -> render(conn, :show, fee: updated)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # POST /api/admin/fees/generate-monthly  (admin_master only)
  def generate_monthly(conn, _params) do
    :ok = Finance.generate_monthly_fees()
    conn |> put_status(:ok) |> json(%{message: "monthly fees generated for all active students"})
  end

  # ── Guardian: visão própria ────────────────────────────────

  # GET /api/guardian/fees
  def guardian_index(conn, params) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    if is_nil(guardian) do
      conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    else
      opts =
        []
        |> maybe_filter(:status, parse_status(params["status"]))
        |> maybe_filter(:year, parse_int(params["year"]))
        |> maybe_filter(:month, parse_int(params["month"]))
        |> maybe_filter(:page, parse_int(params["page"]))
        |> maybe_filter(:per_page, parse_int(params["per_page"]))

      %{data: fees, meta: meta} = Finance.list_fees_by_guardian(guardian.id, opts)
      render(conn, :index, fees: fees, meta: meta)
    end
  end

  # GET /api/guardian/fees/:id
  def guardian_show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    with %{} = fee <- Finance.get_fee(id),
         true <- fee_belongs_to_guardian?(fee, guardian) do
      render(conn, :show, fee: fee)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      false -> conn |> put_status(:forbidden) |> json(%{error: "forbidden"})
    end
  end

  # PUT /api/guardian/fees/:id/upload-receipt
  # Recebe receipt_url (URL do comprovante já enviado para storage pelo frontend)
  # e muda status para :under_analysis
  def upload_receipt(conn, %{"id" => id, "receipt_url" => receipt_url}) do
    user = conn.assigns.current_user
    guardian = Accounts.get_guardian_by_user_id(user.id)

    with %{} = fee <- Finance.get_fee(id),
         true <- fee_belongs_to_guardian?(fee, guardian),
         {:ok, updated} <- Finance.mark_as_under_analysis(fee, receipt_url) do
      render(conn, :show, fee: updated)
    else
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      false -> conn |> put_status(:forbidden) |> json(%{error: "forbidden"})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  def upload_receipt(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "receipt_url is required"})
  end

  # POST /api/guardian/fees/pay
  # Simulated card payment: marks fees as paid without a real gateway call.
  # card_id is recorded for audit; charge is simulated (no external API).
  def guardian_pay(conn, params) do
    fee_ids = Map.get(params, "fee_ids", [])

    if fee_ids == [] do
      conn |> put_status(:bad_request) |> json(%{error: "fee_ids is required"})
    else
      user = conn.assigns.current_user
      guardian = Accounts.get_guardian_by_user_id(user.id)

      if is_nil(guardian) do
        conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
      else
        fees = Enum.map(fee_ids, &Finance.get_fee/1)

        cond do
          Enum.any?(fees, &is_nil/1) ->
            conn |> put_status(:not_found) |> json(%{error: "fee_not_found"})

          not Enum.all?(fees, &fee_belongs_to_guardian?(&1, guardian)) ->
            conn |> put_status(:forbidden) |> json(%{error: "forbidden"})

          true ->
            results =
              fees
              |> Enum.filter(fn f -> f.status in [:pending, :overdue, :under_analysis] end)
              |> Enum.map(&Finance.mark_as_paid/1)

            errors = Enum.filter(results, &match?({:error, _}, &1))

            if Enum.empty?(errors) do
              paid = Enum.map(results, fn {:ok, f} -> f end)
              conn |> put_status(:ok) |> render(:index, fees: paid)
            else
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "payment_failed"})
            end
        end
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp fee_belongs_to_guardian?(fee, guardian) when not is_nil(guardian) do
    alias SysFc.Students.StudentGuardian
    import Ecto.Query
    alias SysFc.Repo

    Repo.exists?(
      from sg in StudentGuardian,
        where: sg.student_id == ^fee.student_id and sg.guardian_id == ^guardian.id
    )
  end

  defp fee_belongs_to_guardian?(_, _), do: false

  defp maybe_filter(opts, _key, nil), do: opts
  defp maybe_filter(opts, _key, ""), do: opts
  defp maybe_filter(opts, key, value), do: [{key, value} | opts]

  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n) when is_integer(n), do: n

  defp parse_date(nil), do: nil
  defp parse_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_status(nil), do: nil
  defp parse_status(s) when is_binary(s) do
    case s do
      "pending" -> :pending
      "paid" -> :paid
      "overdue" -> :overdue
      "under_analysis" -> :under_analysis
      _ -> nil
    end
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
