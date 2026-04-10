defmodule SysFcWeb.StudentController do
  use SysFcWeb, :controller

  alias SysFc.Students

  # GET /api/admin/students
  def index(conn, params) do
    opts =
      []
      |> maybe_filter(:category, params["category"])
      |> maybe_filter(:search, params["search"])
      |> maybe_filter(:is_active, parse_bool(params["is_active"], true))
      |> maybe_filter(:guardian_id, params["guardian_id"])
      |> maybe_filter(:guardian_search, params["guardian_search"])
      |> maybe_filter(:page, parse_int(params["page"]))
      |> maybe_filter(:per_page, parse_int(params["per_page"]))

    %{data: students, meta: meta} = Students.list_students(opts)
    render(conn, :index, students: students, meta: meta)
  end

  # GET /api/admin/students/:id
  def show(conn, %{"id" => id}) do
    case Students.get_student(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "not_found"})
      student -> render(conn, :show, student: student)
    end
  end

  # POST /api/admin/students
  def create(conn, params) do
    guardian_id = params["guardian_id"]

    case Students.create_student(params, guardian_id) do
      {:ok, student} ->
        conn
        |> put_status(:created)
        |> render(:show, student: student)

      {:error, :guardian_required} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "guardian_id is required"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  # PUT /api/admin/students/:id
  def update(conn, %{"id" => id} = params) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        case Students.update_student(student, params) do
          {:ok, updated} ->
            render(conn, :show, student: updated)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # DELETE /api/admin/students/:id  (soft-delete: is_active = false)
  def delete(conn, %{"id" => id}) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        {:ok, _} = Students.deactivate_student(student)
        send_resp(conn, :no_content, "")
    end
  end

  # POST /api/admin/students/:id/link-guardian
  def link_guardian(conn, %{"id" => student_id, "guardian_id" => guardian_id}) do
    case Students.link_guardian(student_id, guardian_id) do
      {:ok, _} -> send_resp(conn, :no_content, "")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "validation_failed", details: format_errors(changeset)})
    end
  end

  def link_guardian(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "guardian_id is required"})
  end

  # GET /api/admin/students/pending
  def pending(conn, params) do
    opts =
      []
      |> maybe_filter(:page, parse_int(params["page"]))
      |> maybe_filter(:per_page, parse_int(params["per_page"]))

    %{data: students, meta: meta} = Students.list_pending_students(opts)
    render(conn, :index, students: students, meta: meta)
  end

  # PUT /api/admin/students/:id/confirm
  def confirm(conn, %{"id" => id} = params) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        # Accept optional extra attrs (e.g. rg) to update during confirmation
        extra = Map.take(params, ["rg"])

        case Students.confirm_student(student, extra) do
          {:ok, confirmed} ->
            render(conn, :show, student: confirmed)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # PUT /api/admin/students/:id/reject
  def reject(conn, %{"id" => id}) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        case Students.reject_student(student) do
          {:ok, rejected} ->
            render(conn, :show, student: rejected)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # PUT /api/admin/students/:id/freeze
  def freeze(conn, %{"id" => id}) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        case Students.freeze_student(student) do
          {:ok, frozen} -> render(conn, :show, student: frozen)
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # PUT /api/admin/students/:id/unfreeze
  def unfreeze(conn, %{"id" => id}) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        case Students.unfreeze_student(student) do
          {:ok, unfrozen} -> render(conn, :show, student: unfrozen)
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity)
            |> json(%{error: "validation_failed", details: format_errors(changeset)})
        end
    end
  end

  # PUT /api/guardian/students/:id/freeze
  def guardian_freeze(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    guardian = SysFc.Accounts.get_guardian_by_user_id(user.id)

    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        # Verify this student belongs to the guardian
        linked = Enum.any?(student.student_guardians, &(&1.guardian_id == guardian.id))

        if not linked do
          conn |> put_status(:forbidden) |> json(%{error: "not_your_student"})
        else
          action = if student.is_frozen, do: &Students.unfreeze_student/1, else: &Students.freeze_student/1
          case action.(student) do
            {:ok, updated} -> render(conn, :show, student: updated)
            {:error, changeset} ->
              conn |> put_status(:unprocessable_entity)
              |> json(%{error: "validation_failed", details: format_errors(changeset)})
          end
        end
    end
  end

  # PUT /api/guardian/students/:id
  def guardian_update(conn, %{"id" => id} = params) do
    user = conn.assigns.current_user
    guardian = SysFc.Accounts.get_guardian_by_user_id(user.id)

    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        linked = Enum.any?(student.student_guardians, &(&1.guardian_id == guardian.id))

        if not linked do
          conn |> put_status(:forbidden) |> json(%{error: "not_your_student"})
        else
          # Guardian can only update: name, rg, address fields, school, health plan
          allowed = Map.take(params, [
            "name", "rg", "school_name",
            "address", "address_number", "complement", "neighborhood", "city", "cep",
            "has_health_plan", "health_plan_name"
          ])

          case Students.update_student(student, allowed) do
            {:ok, updated} -> render(conn, :show, student: updated)
            {:error, changeset} ->
              conn |> put_status(:unprocessable_entity)
              |> json(%{error: "validation_failed", details: format_errors(changeset)})
          end
        end
    end
  end

  # POST /api/admin/students/:id/photo
  def upload_photo(conn, %{"id" => id, "photo" => %Plug.Upload{} = upload}) do
    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        binary = File.read!(upload.path)
        content_type = upload.content_type || "image/jpeg"

        case SysFc.Storage.upload_student_photo(student.id, binary, content_type) do
          {:ok, url} ->
            {:ok, updated} = Students.update_student(student, %{"photo_url" => url})
            render(conn, :show, student: updated)

          {:error, reason} ->
            conn |> put_status(:unprocessable_entity)
            |> json(%{error: "upload_failed", details: inspect(reason)})
        end
    end
  end

  def upload_photo(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "photo_required"})
  end

  # POST /api/guardian/students/:id/photo
  def guardian_upload_photo(conn, %{"id" => id, "photo" => %Plug.Upload{} = upload}) do
    user = conn.assigns.current_user
    guardian = SysFc.Accounts.get_guardian_by_user_id(user.id)

    case Students.get_student(id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "not_found"})

      student ->
        linked = Enum.any?(student.student_guardians, &(&1.guardian_id == guardian.id))

        if not linked do
          conn |> put_status(:forbidden) |> json(%{error: "not_your_student"})
        else
          binary = File.read!(upload.path)
          content_type = upload.content_type || "image/jpeg"

          case SysFc.Storage.upload_student_photo(student.id, binary, content_type) do
            {:ok, url} ->
              {:ok, updated} = Students.update_student(student, %{"photo_url" => url})
              render(conn, :show, student: updated)

            {:error, reason} ->
              conn |> put_status(:unprocessable_entity)
              |> json(%{error: "upload_failed", details: inspect(reason)})
          end
        end
    end
  end

  def guardian_upload_photo(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "photo_required"})
  end

  # POST /api/guardian/students
  def guardian_create(conn, params) do
    user = conn.assigns.current_user
    guardian = SysFc.Accounts.get_guardian_by_user_id(user.id)

    if is_nil(guardian) do
      conn |> put_status(:not_found) |> json(%{error: "guardian_profile_not_found"})
    else
      case Students.create_student_by_guardian(params, guardian.id) do
        {:ok, student} ->
          conn
          |> put_status(:created)
          |> render(:show, student: student)

        {:error, :guardian_required} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "guardian_required"})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "validation_failed", details: format_errors(changeset)})
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────────

  defp maybe_filter(opts, _key, nil), do: opts
  defp maybe_filter(opts, _key, ""), do: opts
  defp maybe_filter(opts, key, value), do: [{key, value} | opts]

  defp parse_int(nil), do: nil
  defp parse_int(s) when is_binary(s), do: String.to_integer(s)
  defp parse_int(n) when is_integer(n), do: n

  defp parse_bool(nil, default), do: default
  defp parse_bool("true", _), do: true
  defp parse_bool("false", _), do: false
  defp parse_bool(_, default), do: default

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
