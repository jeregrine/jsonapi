defmodule JSONAPI.Utils.List do
  @moduledoc false

  @doc """
  Transforms a Map into a List of Tuples that can be converted into a query string via URI.encode_query/1

  - if values are terms that implements the String.Chars protocol it returns [{key1, value1}, {key2, value2}]
  - if any value is a list es. %{key1: ["a", "b"]} it returns [{key1[], "a"}, {key1[], "b"}]
  - if any value is a map es. %{key1: %{key2: "c", key3: "d"}} it returns [{key1[key2], "c"}, {key1[key3], "d"}]

  ## Examples

      iex> to_list_of_query_string_components(%{"number" => 5})
      [{"number", 5}]

      iex> to_list_of_query_string_components(%{color: "red"})
      [{:color, "red"}]

      iex> to_list_of_query_string_components(%{"alphabet" => ["a", "b", "c"]})
      [{"alphabet[]", "a"}, {"alphabet[]", "b"}, {"alphabet[]", "c"}]

      iex> to_list_of_query_string_components(%{"filters" => %{"age" => 18, "name" => "John"}})
      [{"filters[age]", 18}, {"filters[name]", "John"}]

  """
  @spec to_list_of_query_string_components(map()) :: list(tuple())
  def to_list_of_query_string_components(map) when is_map(map) do
    Enum.flat_map(map, &do_to_list_of_query_string_components/1)
  end

  defp do_to_list_of_query_string_components({key, value}) when is_list(value) do
    into_tuple_and_put_in_list(key, value)
  end

  defp do_to_list_of_query_string_components({key, value}) when is_map(value) do
    Enum.flat_map(value, fn {k, v} -> into_tuple_and_put_in_list("#{key}[#{k}]", v) end)
  end

  defp do_to_list_of_query_string_components({key, value}), do: into_tuple_and_put_in_list(key, value)

  defp into_tuple_and_put_in_list(key, value) when is_list(value) do
    Enum.map(value, &{"#{key}[]", &1})
  end

  defp into_tuple_and_put_in_list(key, value) do
    [{key, value}]
  end
end
