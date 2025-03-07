defmodule KinoPythonxTest do
  use ExUnit.Case

  describe "Kino.Render" do
    test "pandas dataframe" do
      {result, %{}} =
        Pythonx.eval(
          """
          import pandas as pd

          pd.DataFrame({
            "x": [1, 2, 3],
            "y": [10, 20, 30],
            "name": ["foo", "bar", "baz"]
          })
          """,
          %{}
        )

      assert %{type: :js, js_view: js_view} = Kino.Render.to_livebook(result)

      ref = js_view.ref
      send(js_view.pid, {:connect, self(), %{ref: ref, origin: inspect(self())}})
      assert_receive {:connect_reply, data, %{ref: ^ref}}

      assert %{
               content: %{
                 columns: [
                   %{key: "0", label: "x"},
                   %{key: "1", label: "y"},
                   %{key: "2", label: "name"}
                 ],
                 data: [["1", "10", "foo"], ["2", "20", "bar"], ["3", "30", "baz"]],
                 total_rows: 3
               }
             } = data
    end

    test "polars dataframe" do
      {result, %{}} =
        Pythonx.eval(
          """
          import polars as pl

          pl.DataFrame({
            "x": [1, 2, 3],
            "y": [10, 20, 30],
            "name": ["foo", "bar", "baz"]
          })
          """,
          %{}
        )

      assert %{type: :js, js_view: js_view} = Kino.Render.to_livebook(result)

      ref = js_view.ref
      send(js_view.pid, {:connect, self(), %{ref: ref, origin: inspect(self())}})
      assert_receive {:connect_reply, data, %{ref: ^ref}}

      assert %{
               content: %{
                 columns: [
                   %{key: "0", label: "x"},
                   %{key: "1", label: "y"},
                   %{key: "2", label: "name"}
                 ],
                 data: [["1", "10", "foo"], ["2", "20", "bar"], ["3", "30", "baz"]],
                 total_rows: 3
               }
             } = data
    end

    test "matplotlib figure" do
      {result, %{}} =
        Pythonx.eval(
          """
          import matplotlib.pyplot as plt
          plt.plot([1, 2], [1, 2])
          plt.gcf()
          """,
          %{}
        )

      assert %{type: :image, mime_type: "image/png"} = Kino.Render.to_livebook(result)
    end

    test "seaborn grid" do
      {_result, globals} =
        Pythonx.eval(
          """
          import pandas as pd

          df = pd.DataFrame({
            "x": [1, 2, 3],
            "y": [10, 20, 30],
            "name": ["foo", "bar", "baz"]
          })
          """,
          %{}
        )

      # PairGrid
      {result, %{}} =
        Pythonx.eval(
          """
          import seaborn as sns
          sns.pairplot(df, hue="name")
          """,
          globals
        )

      assert %{type: :image, mime_type: "image/png"} = Kino.Render.to_livebook(result)

      # JointGrid
      {result, %{}} =
        Pythonx.eval(
          """
          import seaborn as sns
          sns.jointplot(data=df, x="x", y="y")
          """,
          globals
        )

      assert %{type: :image, mime_type: "image/png"} = Kino.Render.to_livebook(result)

      # FacetGrid
      {result, %{}} =
        Pythonx.eval(
          """
          import seaborn as sns
          sns.FacetGrid(df, col="name").map(sns.scatterplot, "x", "y")
          """,
          globals
        )

      assert %{type: :image, mime_type: "image/png"} = Kino.Render.to_livebook(result)
    end

    test "altair chart" do
      {result, %{}} =
        Pythonx.eval(
          """
          import altair as alt

          data = alt.Data(values=[{'x': 1, 'y': 1}, {'x': 2, 'y': 2}])

          alt.Chart(data).mark_line().encode(x='x:Q', y='y:Q')
          """,
          %{}
        )

      assert %{type: :js} = Kino.Render.to_livebook(result)
    end

    test "plotly chart" do
      {result, %{}} =
        Pythonx.eval(
          """
          import plotly.express as px
          import plotly.io as pio

          px.line(x=["a", "b", "c"], y=[1, 3, 2], title="sample figure")
          """,
          %{}
        )

      assert %{type: :js} = Kino.Render.to_livebook(result)
    end

    test "object with _repr_markdown_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class Markdown:
            def __init__(self, text):
              self.text = text

            def _repr_markdown_(self):
              return self.text

          Markdown("**Hello** `world`!")
          """,
          %{}
        )

      assert %{
               type: :markdown,
               text: "**Hello** `world`!",
               chunk: false
             } = Kino.Render.to_livebook(result)
    end

    test "object with _repr_latex_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class LaTeX:
            def __init__(self, text):
              self.text = text

            def _repr_latex_(self):
              return self.text

          LaTeX("x = x_0")
          """,
          %{}
        )

      assert %{
               type: :markdown,
               text: "$$\nx = x_0\n$$",
               chunk: false
             } = Kino.Render.to_livebook(result)
    end

    test "object with _repr_html_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class HTML:
            def __init__(self, text):
              self.text = text

            def _repr_html_(self):
              return self.text

          HTML("<div style='color: red'>Hello</div>")
          """,
          %{}
        )

      assert %{type: :js} = Kino.Render.to_livebook(result)
    end

    test "object with _repr_svg_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class SVG:
            def __init__(self, data):
              self.data = data

            def _repr_svg_(self):
              return self.data

          SVG(bytes([0, 1, 2]))
          """,
          %{}
        )

      assert %{
               type: :image,
               mime_type: "image/svg",
               content: <<0, 1, 2>>
             } = Kino.Render.to_livebook(result)
    end

    test "object with _repr_png_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class PNG:
            def __init__(self, data):
              self.data = data

            def _repr_png_(self):
              return self.data

          PNG(bytes([0, 1, 2]))
          """,
          %{}
        )

      assert %{
               type: :image,
               mime_type: "image/png",
               content: <<0, 1, 2>>
             } = Kino.Render.to_livebook(result)
    end

    test "object with _repr_jpeg_" do
      {result, %{}} =
        Pythonx.eval(
          """
          class JPEG:
            def __init__(self, data):
              self.data = data

            def _repr_jpeg_(self):
              return self.data

          JPEG(bytes([0, 1, 2]))
          """,
          %{}
        )

      assert %{
               type: :image,
               mime_type: "image/jpeg",
               content: <<0, 1, 2>>
             } = Kino.Render.to_livebook(result)
    end

    test "defaults to repr" do
      {result, %{}} =
        Pythonx.eval(
          """
          [1, "hello", 2]
          """,
          %{}
        )

      assert %{
               type: :terminal_text,
               text: ~S|[1, 'hello', 2]|,
               chunk: false
             } = Kino.Render.to_livebook(result)
    end
  end

  describe "Table.Reader" do
    test "pandas dataframe" do
      {result, %{}} =
        Pythonx.eval(
          """
          import pandas as pd

          data = {
            "x": [1, 2, 3],
            "y": [10, 20, 30],
            "name": ["foo", "bar", "baz"]
          }

          pd.DataFrame(data)
          """,
          %{}
        )

      assert Enum.to_list(Table.to_rows(result)) == [
               %{"x" => 1, "y" => 10, "name" => "foo"},
               %{"x" => 2, "y" => 20, "name" => "bar"},
               %{"x" => 3, "y" => 30, "name" => "baz"}
             ]
    end

    test "polars dataframe" do
      {result, %{}} =
        Pythonx.eval(
          """
          import polars as pl

          data = {
            "x": [1, 2, 3],
            "y": [10, 20, 30],
            "name": ["foo", "bar", "baz"]
          }

          pl.DataFrame(data)
          """,
          %{}
        )

      assert Enum.to_list(Table.to_rows(result)) == [
               %{"x" => 1, "y" => 10, "name" => "foo"},
               %{"x" => 2, "y" => 20, "name" => "bar"},
               %{"x" => 3, "y" => 30, "name" => "baz"}
             ]
    end
  end
end
