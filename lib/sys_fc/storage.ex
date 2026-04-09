defmodule SysFc.Storage do
  @moduledoc "Upload de arquivos para o S3."

  def upload_student_photo(student_id, binary_data, content_type) do
    bucket = Application.get_env(:sys_fc, :s3_bucket, "nebula-imagens")
    ext = ext_from_content_type(content_type)
    ts = System.system_time(:millisecond)
    key = "students/#{student_id}/photo_#{ts}#{ext}"

    case ExAws.S3.put_object(bucket, key, binary_data,
           content_type: content_type,
           acl: :public_read
         )
         |> ExAws.request() do
      {:ok, _} ->
        url = "https://#{bucket}.s3.amazonaws.com/#{key}"
        {:ok, url}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ext_from_content_type("image/jpeg"), do: ".jpg"
  defp ext_from_content_type("image/png"), do: ".png"
  defp ext_from_content_type("image/webp"), do: ".webp"
  defp ext_from_content_type(_), do: ".jpg"
end
