Pythonx.uv_init("""
[project]
name = "project"
version = "0.0.0"
requires-python = "==3.13.*"
dependencies = [
  "numpy==2.2.3",
  "matplotlib==3.10.1",
  "pandas==2.2.3",
  "polars==1.24.0",
  "altair==5.5.0",
  "plotly==6.0.0",
  "seaborn==0.13.2"
]
""")

# Import modules upfront to compile them before first tests run.
Pythonx.eval(
  """
  import altair
  import matplotlib
  import pandas
  import plotly
  import polars
  import seaborn

  matplotlib.use("Agg")
  """,
  %{}
)

ExUnit.start()
