defmodule JSONAPI.Utils.String do
  @moduledoc """
  String manipulation helpers.
  """

  @allowed_transformations [:camelize, :dasherize, :underscore]

  @doc """
  Replace dashes between words in `value` with underscores

  Ignores dashes that are not between letters/numbers

  ## Examples

      iex> underscore("top-posts")
      "top_posts"

      iex> underscore(:top_posts)
      "top_posts"

      iex> underscore("-top-posts")
      "-top_posts"

      iex> underscore("-top--posts-")
      "-top--posts-"

      iex> underscore("corgiAge")
      "corgi_age"

  """
  @spec underscore(String.t()) :: String.t()
  def underscore(value) when is_binary(value) do
    value
    |> String.replace(~r/([a-zA-Z\d])-([a-zA-Z\d])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.downcase()
  end

  @spec underscore(atom) :: String.t()
  def underscore(value) when is_atom(value) do
    value
    |> to_string()
    |> underscore()
  end

  @doc """
  Replace underscores between words in `value` with dashes

  Ignores underscores that are not between letters/numbers

  ## Examples

      iex> dasherize("top_posts")
      "top-posts"

      iex> dasherize("_top_posts")
      "_top-posts"

      iex> dasherize("_top__posts_")
      "_top__posts_"

  """
  @spec dasherize(atom) :: String.t()
  def dasherize(value) when is_atom(value) do
    value
    |> to_string()
    |> dasherize()
  end

  @spec dasherize(String.t()) :: String.t()
  def dasherize(value) when is_binary(value) do
    String.replace(value, ~r/([a-zA-Z0-9])_([a-zA-Z0-9])/, "\\1-\\2")
  end

  @doc """
  Replace underscores or dashes between words in `value` with camelCasing

  Ignores underscores or dashes that are not between letters/numbers

  ## Examples

      iex> camelize("top_posts")
      "topPosts"

      iex> camelize(:top_posts)
      "topPosts"

      iex> camelize("_top_posts")
      "_topPosts"

      iex> camelize("_top__posts_")
      "_top__posts_"

      iex> camelize("")
      ""

  """
  @spec camelize(atom) :: String.t()
  def camelize(value) when is_atom(value) do
    value
    |> to_string()
    |> camelize()
  end

  @spec camelize(String.t()) :: String.t()
  def camelize(value) when value == "", do: value

  def camelize(value) when is_binary(value) do
    with words <-
           Regex.split(
             ~r{(?<=[a-zA-Z0-9])[-_](?=[a-zA-Z0-9])},
             to_string(value)
           ) do
      [h | t] = words |> Enum.filter(&(&1 != ""))

      [String.downcase(h) | camelize_list(t)]
      |> Enum.join()
    end
  end

  defp camelize_list([]), do: []

  defp camelize_list([h | t]) do
    [String.capitalize(h)] ++ camelize_list(t)
  end

  @doc """

  ## Examples

      iex> expand_fields(%{"foo-bar" => "baz"}, &underscore/1)
      %{"foo_bar" => "baz"}

      iex> expand_fields(%{"foo_bar" => "baz"}, &dasherize/1)
      %{"foo-bar" => "baz"}

      iex> expand_fields(%{"foo-bar" => "baz"}, &camelize/1)
      %{"fooBar" => "baz"}

      iex> expand_fields({"foo-bar", "dollar-sol"}, &underscore/1)
      {"foo_bar", "dollar-sol"}

      iex> expand_fields({"foo-bar", %{"a-d" => "z-8"}}, &underscore/1)
      {"foo_bar", %{"a_d" => "z-8"}}

      iex> expand_fields(%{"f-b" => %{"a-d" => "z"}, "c-d" => "e"}, &underscore/1)
      %{"f_b" => %{"a_d" => "z"}, "c_d" => "e"}

      iex> expand_fields(%{"f-b" => %{"a-d" => %{"z-w" => "z"}}, "c-d" => "e"}, &underscore/1)
      %{"f_b" => %{"a_d" => %{"z_w" => "z"}}, "c_d" => "e"}

      iex> expand_fields(:"foo-bar", &underscore/1)
      "foo_bar"

      iex> expand_fields(:foo_bar, &dasherize/1)
      "foo-bar"

      iex> expand_fields(:"foo-bar", &camelize/1)
      "fooBar"

      iex> expand_fields(%{"f-b" => "a-d"}, &underscore/1)
      %{"f_b" => "a-d"}

      iex> expand_fields(%{"inserted-at" => ~N[2019-01-17 03:27:24.776957]}, &underscore/1)
      %{"inserted_at" => ~N[2019-01-17 03:27:24.776957]}

      iex> expand_fields(%{"xValue" => 123}, &underscore/1)
      %{"x_value" => 123}

      iex> expand_fields(%{"attributes" => %{"corgiName" => "Wardel"}}, &underscore/1)
      %{"attributes" => %{"corgi_name" => "Wardel"}}

      iex> expand_fields(%{"attributes" => %{"corgiName" => ["Wardel"]}}, &underscore/1)
      %{"attributes" => %{"corgi_name" => ["Wardel"]}}

      iex> expand_fields(%{"attributes" => %{"someField" => ["SomeValue", %{"nestedField" => "Value"}]}}, &underscore/1)
      %{"attributes" => %{"some_field" => ["SomeValue", %{"nested_field" => "Value"}]}}

      iex> expand_fields([%{"fooBar" => "a"}, %{"fooBar" => "b"}], &underscore/1)
      [%{"foo_bar" => "a"}, %{"foo_bar" => "b"}]

      iex> expand_fields([%{"foo_bar" => "a"}, %{"foo_bar" => "b"}], &camelize/1)
      [%{"fooBar" => "a"}, %{"fooBar" => "b"}]

      iex> expand_fields(%{"fooAttributes" => [%{"fooBar" => "a"}, %{"fooBar" => "b"}]}, &underscore/1)
      %{"foo_attributes" => [%{"foo_bar" => "a"}, %{"foo_bar" => "b"}]}

      iex> expand_fields(%{"foo_attributes" => [%{"foo_bar" => "a"}, %{"foo_bar" => "b"}]}, &camelize/1)
      %{"fooAttributes" => [%{"fooBar" => "a"}, %{"fooBar" => "b"}]}

      iex> expand_fields(%{"foo_attributes" => [%{"foo_bar" => [1, 2]}]}, &camelize/1)
      %{"fooAttributes" => [%{"fooBar" => [1, 2]}]}

  """
  @spec expand_fields(map, function) :: map
  def expand_fields(%{__struct__: _} = value, _fun), do: value

  def expand_fields(map, fun) when is_map(map) do
    Enum.into(map, %{}, &expand_fields(&1, fun))
  end

  @spec expand_fields(list, function) :: list
  def expand_fields(values, fun) when is_list(values) do
    Enum.map(values, &expand_fields(&1, fun))
  end

  @spec expand_fields(tuple, function) :: tuple
  def expand_fields({key, value}, fun) when is_map(value) do
    {fun.(key), expand_fields(value, fun)}
  end

  def expand_fields({key, value}, fun) when is_list(value) do
    {fun.(key), maybe_expand_fields(value, fun)}
  end

  def expand_fields({key, value}, fun) do
    {fun.(key), value}
  end

  @spec expand_fields(String.t() | atom(), function) :: String.t()
  def expand_fields(value, fun) when is_binary(value) or is_atom(value) do
    fun.(value)
  end

  def expand_fields(value, _fun) do
    value
  end

  defp maybe_expand_fields(values, fun) when is_list(values) do
    Enum.map(values, fn
      string when is_binary(string) -> string
      value -> expand_fields(value, fun)
    end)
  end

  @doc """
  The configured transformation for the API's fields. JSON:API v1.1 recommends
  using camlized fields (e.g. "goodDog", versus "good_dog").  However, we don't hold a strong
  opinion, so feel free to customize it how you would like (e.g. "good-dog", versus "good_dog").

  This library currently supports camelized, dashed and underscored fields.

  ## Configuration examples

  camelCase fields:

  ```
  config :jsonapi, field_transformation: :camelize
  ```

  Dashed fields:

  ```
  config :jsonapi, field_transformation: :dasherize
  ```

  Underscored fields:

  ```
  config :jsonapi, field_transformation: :underscore
  ```
  """
  def field_transformation do
    field_transformation(Application.get_env(:jsonapi, :field_transformation))
  end

  @doc false
  def field_transformation(nil), do: nil

  def field_transformation(transformation) when transformation in @allowed_transformations,
    do: transformation
end
