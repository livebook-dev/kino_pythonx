defmodule KinoPythonx do
  @moduledoc false

  @renders_key {__MODULE__, :renders}

  @doc false
  def renders() do
    :persistent_term.get(@renders_key, {[], []})
  end

  @doc false
  def add_render(class, render) do
    # Normally we would have a process that serializes the persistent
    # term updates, because the update is not atomic. However, we
    # expect the registrations to be done at application startup,
    # so in practice the calls should not be concurrent.
    {classes, renders} = renders()
    :persistent_term.put(@renders_key, {classes ++ [class], renders ++ [render]})

    :ok
  end

  @doc """
  Registers render implementations for a predefined set of Python
  types.
  """
  @spec register_built_in_renders() :: :ok
  def register_built_in_renders() do
    for class <- ["pandas.DataFrame", "polars.DataFrame"] do
      Kino.Pythonx.register_render(class, fn value ->
        formatter = fn
          _key, %Pythonx.Object{} = value ->
            {result, %{}} = Pythonx.eval("str(value)", %{"value" => value})
            {:ok, Pythonx.decode(result)}

          _key, _value ->
            :default
        end

        Kino.DataTable.new(value, formatter: formatter)
      end)
    end

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

    for class <- ["seaborn.FacetGrid", "seaborn.JointGrid", "seaborn.PairGrid"] do
      Kino.Pythonx.register_render(class, fn value ->
        {result, %{}} =
          Pythonx.eval(
            """
            # Seaborn grids have savefig that wraps matplotlib savefig.
            import io
            buffer = io.BytesIO()
            value.savefig(buffer, format="png", bbox_inches="tight")
            data = buffer.getvalue()
            buffer.close()
            data
            """,
            %{"value" => value}
          )

        data = Pythonx.decode(result)
        Kino.Image.new(data, "image/png")
      end)
    end

    Kino.Pythonx.register_render("altair.TopLevelMixin", fn value ->
      {result, %{}} =
        Pythonx.eval(
          """
          import json
          # There is chart.to_json(), but we use chart.to_dict() to
          # dump the JSON without whitespace.
          json.dumps(value.to_dict(), separators=(',', ':'))
          """,
          %{"value" => value}
        )

      json = Pythonx.decode(result)
      KinoPythonx.Altair.new(json)
    end)
  end
end

defimpl Kino.Render, for: Pythonx.Object do
  def to_livebook(object) do
    {classes, renders} = KinoPythonx.renders()

    code = """
    import sys

    def render(value):
      for (index, (mod_name, cls_name)) in enumerate(classes):
        mod_name = mod_name.decode("utf-8")
        cls_name = cls_name.decode("utf-8")
        # If there is any object of this class, the module must have
        # been imported, so we check for it in the imported modules,
        # instead of trying to find and import it. This is important
        # because importing a module for the first time can be time
        # consuming, due to compilation.
        if mod_name in sys.modules:
          mod = sys.modules[mod_name]
          cls = getattr(mod, cls_name)
          if isinstance(value, cls):
            return ("renderer", index)

      if hasattr(value, "_repr_html_"):
        html = value._repr_html_()
        return ("html", html)

      if hasattr(value, "_repr_png_"):
        data = value._repr_png_()
        return ("image", "png", data)

      if hasattr(value, "_repr_jpeg_"):
        data = value._repr_jpeg_()
        return ("image", "jpeg", data)

      if hasattr(value, "_repr_svg_"):
        data = value._repr_svg_()
        return ("image", "svg", data)

      if hasattr(value, "_repr_markdown_"):
        text = value._repr_markdown_()
        return ("markdown", text)

      if hasattr(value, "_repr_latex_"):
        text = value._repr_latex_()
        return ("latex", text)

      return ("text", repr(value))

    render(value)
    """

    {result, %{}} = Pythonx.eval(code, %{"value" => object, "classes" => classes})

    kino =
      case Pythonx.decode(result) do
        {"text", text} -> Kino.Text.new(text, terminal: true)
        {"html", html} -> Kino.HTML.new(html)
        {"image", format, data} -> Kino.Image.new(data, "image/#{format}")
        {"markdown", text} -> Kino.Markdown.new(text)
        {"latex", text} -> Kino.Markdown.new("$$\n#{text}\n$$")
        {"renderer", index} -> Enum.fetch!(renders, index).(object)
      end

    Kino.Render.to_livebook(kino)
  end
end

defimpl Table.Reader, for: Pythonx.Object do
  def init(object) do
    {columns, %{}} =
      Pythonx.eval(
        """
        import sys

        def dataframe_info(df):
          if "pandas" in sys.modules:
            import pandas as pd
            if isinstance(df, pd.DataFrame):
              columns = df.columns.to_list()
              series = [(df[col], df[col].shape[0]) for col in df.columns]
              count = df.shape[0]
              return ("pandas", columns, series, count)

          if "polars" in sys.modules:
            import polars as pl
            if isinstance(df, pl.DataFrame):
              columns = df.columns
              series = [(df[col], df[col].shape[0]) for col in df.columns]
              count = df.shape[0]
              return ("polars", columns, series, count)

          return None

        dataframe_info(df)
        """,
        %{"df" => object}
      )

    case Pythonx.decode(columns) do
      nil ->
        :none

      {type, columns, series, count} ->
        data =
          Enum.map(series, fn {series, size} ->
            %KinoPythonx.SeriesIterator{type: type, series: series, size: size}
          end)

        {:columns, %{columns: columns, count: count}, data}
    end
  end
end
