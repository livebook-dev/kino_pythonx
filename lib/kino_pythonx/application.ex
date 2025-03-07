defmodule KinoPythonx.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    KinoPythonx.register_built_in_renders()

    children = []

    opts = [strategy: :one_for_one, name: KinoPythonx.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
