defmodule KinoPythonx.Altair do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/altair/build"

  @type t :: Kino.JS.t()

  @doc """
  Builds a kino rendering the given Vega-Lite spec, given as binary
  json.
  """
  @spec new(String.t()) :: t()
  def new(spec) when is_binary(spec) do
    Kino.JS.new(__MODULE__, spec, export: fn spec -> {"vega-lite", spec} end)
  end
end
