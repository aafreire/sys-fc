defmodule SysFc.Repo do
  use Ecto.Repo,
    otp_app: :sys_fc,
    adapter: Ecto.Adapters.Postgres
end
