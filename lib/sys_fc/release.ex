defmodule SysFc.Release do
  @moduledoc """
  Tarefas para rodar em produção sem o Mix disponível.

  Uso:
    bin/sys_fc eval "SysFc.Release.migrate()"
    bin/sys_fc eval "SysFc.Release.seed_admin()"
  """

  @app :sys_fc

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed_admin do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          seed_file = Application.app_dir(@app, "priv/repo/seeds_admin.exs")
          Code.eval_file(seed_file)
        end)
    end
  end

  def seed_training_plans do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          seed_file = Application.app_dir(@app, "priv/repo/seeds_training_plans.exs")
          Code.eval_file(seed_file)
        end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(@app)
  end
end
