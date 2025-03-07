defmodule Kino.Pythonx do
  @moduledoc """
  Pythonx integration with Kino.

  This packages defines rendering for a number of Python types and
  allows for defining custom ones via `register_render/2`.
  """

  @doc ~S'''
  Registers a render function for Pythonx objects of the given class.

  The class name should be fully-qualified, that is, include the
  module name, for example `"pandas.DataFrame"`. The `render` applies
  to objects that are instances of the given class, inclusing derived
  classes.

  The `render` function receives a `Pythonx.Object` and should return
  any term, which is subsequently dispatched to `Kino.Render` protocol.

  In case you want to release custom render implementations as a
  package, you should call the registrations on application startup,
  and for consistency name the package `kino_pythonx_*`.

  ## Examples

      Kino.Pythonx.register_render("matplotlib.artist.Artist", fn value ->
        {result, %{}} =
          Pythonx.eval(
            """
            import io
            buffer = io.BytesIO()
            value.figure.savefig(buffer, format="png", bbox_inches="tight")
            data = buffer.getvalue()
            buffer.close()
            data
            """,
            %{"value" => value}
          )

        data = Pythonx.decode(result)
        Kino.Image.new(data, "image/png")
      end)

  '''
  @spec register_render(String.t() | list(String.t()), (Pythonx.Object.t() -> term())) :: :ok
  def register_render(class, render) do
    class =
      case split_at_last_occurrence(class, ".") do
        {:ok, module, class} ->
          {module, class}

        :error ->
          raise "expected fully qualified name in the format {module}.{class}, got: #{inspect(class)}. " <>
                  "For built-in types, use \"builtins\" as the module name"
      end

    KinoPythonx.add_render(class, render)

    :ok
  end

  defp split_at_last_occurrence(string, pattern) do
    case :binary.matches(string, pattern) do
      [] ->
        :error

      parts ->
        {start, length} = List.last(parts)
        <<left::binary-size(start), _::binary-size(length), right::binary>> = string
        {:ok, left, right}
    end
  end
end
