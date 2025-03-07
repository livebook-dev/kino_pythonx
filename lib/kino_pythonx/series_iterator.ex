defmodule KinoPythonx.SeriesIterator do
  @moduledoc false

  # Wrapper around dataframe series that implements the Enumerable
  # protocol.
  #
  # Supports pandas and polars series.

  defstruct [:type, :series, :size]

  @type t :: %__MODULE__{
          type: String.t(),
          series: Pythonx.Object.t(),
          size: non_neg_integer()
        }

  defimpl Enumerable do
    def count(%{size: size}), do: {:ok, size}

    def member?(_iterator, _value), do: {:error, __MODULE__}

    def slice(%{size: size, series: series}) do
      {:ok, size,
       fn start, size, step ->
         if step != 1 do
           raise "series can only be sliced with step of 1"
         end

         {list, %{}} =
           Pythonx.eval(
             """
             series[start:(start + size)].to_list()
             """,
             %{"series" => series, "start" => start, "size" => size}
           )

         Pythonx.decode(list)
       end}
    end

    def reduce(%{series: series, size: size}, acc, fun) do
      reduce(series, size, 0, acc, fun)
    end

    defp reduce(_series, _size, _offset, {:halt, acc}, _fun), do: {:halted, acc}

    defp reduce(series, size, offset, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(series, size, offset, &1, fun)}
    end

    defp reduce(_series, size, size, {:cont, acc}, _fun), do: {:done, acc}

    defp reduce(series, size, offset, {:cont, acc}, fun) do
      {item, %{}} =
        Pythonx.eval(
          """
          series[offset:(offset + 1)].to_list()[0]
          """,
          %{"series" => series, "offset" => offset}
        )

      value = Pythonx.decode(item)

      reduce(series, size, offset + 1, fun.(value, acc), fun)
    end
  end
end
