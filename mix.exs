defmodule KinoPythonx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "Pythonx integration with Livebook"

  def project do
    [
      app: :kino_pythonx,
      version: @version,
      description: @description,
      name: "KinoPythonx",
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      mod: {KinoPythonx.Application, []}
    ]
  end

  defp deps do
    [
      {:kino, "~> 0.11"},
      {:pythonx, "~> 0.4.0"},
      {:ex_doc, "~> 0.37", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Kino.Pythonx",
      source_url: "https://github.com/livebook-dev/kino_pythonx",
      source_ref: "v#{@version}"
    ]
  end

  def package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/livebook-dev/kino_pythonx"
      }
    ]
  end
end
