defmodule GraphqlDocument do
  @moduledoc """
  A utility for building GraphQL documents. (Strings that contain a GraphQL query/mutation.)

  ## Syntax

  `GraphqlDocument.to_string` converts nested lists/keyword lists into the analogous
  GraphQL syntax.

  Simply write lists and keyword lists "as they look in GraphQL".

  Let's take a look at some examples.

  ### Object Fields

  To request a list of fields in an object, include them in a list:

  ```elixir
  [query: [
    human: [:name, :height]
  ]]
  ```

  `GraphqlDocument.to_string/1` will take that Elixir structure and return

  ```elixir
  \"\"\"
  query {
    human {
      name
      height
    }
  }
  \"\"\"
  ```

  ### Arguments

  When a field includes arguments, wrap the arguments and child fields in a
  tuple, like this:

  ```elixir
  {args, fields}
  ```

  For example, `GraphqlDocument.to_string/1` will take this Elixir structure

  ```elixir
  [query: [
    human: {
      [id: "1000"],
      [:name, :height]
    }
  ]]
  ```

  and return this GraphQL document:

  ```elixir
  \"\"\"
  query {
    human(id: "1000") {
      name
      height
    }
  }
  \"\"\"
  ```

  #### Argument types and Enums

  `GraphqlDocument.to_string/1` will translate Elixir primitives into the
  analogous GraphQL primitive type for arguments.

  GraphQL enums can be expressed as an atom (e.g. `FOOT`) or in a tuple
  syntax, `{:enum, "FOOT"}`.

  For example:

  ```elixir
  [query: [
    human: {
      [id: "1000"],
      [:name, height: {[unit: FOOT], []}]
    }
  ]]
  ```

  becomes

  ```elixir
  query {
    human(id: "1000") {
      name
      height(unit: FOOT)
    }
  }
  ```

  We can specify `[unit: FOOT]` as `[unit: {:enum, "FOOT"}]`, which
  is useful for interpolating dynamic values into the query.

  > #### Expressing arguments without sub-fields {: .tip}
  >
  > Notice the slightly complicated syntax above: `height: {[unit: FOOT], []}`
  >
  > The way to include arguments is in an `{args, fields}` tuple. So if a
  > field has arguments but no sub-fields, put `[]` where the sub-fields go.

  ### Nesting Fields

  Since GraphQL supports a theoretically infinite amount of nesting, you can also
  nest as much as needed in the Elixir structure.

  Furthermore, we can take advantage of Elixir's syntax feature that allows a
  regular list to be "mixed" with a keyword list:

  ```elixir
  # Elixir allows lists with a Keyword List as the final members
  [:name, :height, friends: [:name, :age]]
  ```

  Using this syntax, we can build a nested structure like this:

  ```elixir
  [query: [
    human: {
      [id: "1000"],
      [
        :name,
        :height,
        friends: {
          [olderThan: 30],
          [:name, :height]
        }
      ]
    }
  ]]
  ```

  ```elixir
  query {
    human(id: "1000") {
      name
      height
      friends(olderThan: 30) {
        name
        height
      }
    }
  }
  ```
  """

  @doc """
  Generates GraphQL syntax from a nested Elixir keyword list.

  ### Example

      iex> GraphqlDocument.to_string(query: [user: {[id: 3], [:name, :age, :height, documents: [:filename, :url]]}])
      \"\"\"
      query {
        user(id: 3) {
          name
          age
          height
          documents {
            filename
            url
          }
        }
      }\\
      \"\"\"

  """
  def to_string(params, indent_level \\ 0)

  def to_string(params, indent_level) when is_list(params) or is_map(params) do
    indent = String.duplicate("  ", indent_level)

    params
    |> Enum.map(fn
      {field, {[] = _args, sub_fields}} ->
        # empty arguments were passed in; remove them because `field() { subfield }` isn't valid GraphQL
        {field, sub_fields}

      {field, {%{} = args, sub_fields}} when map_size(args) == 0 ->
        # empty arguments were passed in; remove them because `field() { subfield }` isn't valid GraphQL
        {field, sub_fields}

      field ->
        field
    end)
    |> Enum.map_join("\n", fn
      field when is_binary(field) or is_atom(field) ->
        "#{indent}#{field}"

      {field, {args, sub_fields}} when is_map(args) or is_list(args) ->
        args_string =
          args
          |> Enum.map_join(", ", fn {key, value} ->
            "#{key}: #{argument(value)}"
          end)

        sub_fields_string =
          if Enum.any?(sub_fields) do
            " {\n#{to_string(sub_fields, indent_level + 1)}\n#{indent}}"
          else
            ""
          end

        "#{indent}#{field}(#{args_string})#{sub_fields_string}"

      {field, {args, _sub_fields}} ->
        raise "Expected a keyword list or map for args for field #{inspect(field)}, received: #{inspect(args)}"

      {field, [] = _sub_fields} ->
        "#{indent}#{field}"

      {field, sub_fields} ->
        "#{indent}#{field} {\n#{to_string(sub_fields, indent_level + 1)}\n#{indent}}"
    end)
  end

  def to_string(params, _indent_level) do
    raise RuntimeError,
      message: """
      [GraphqlDocument] Expected a list of fields but received `#{inspect(params)}`.

      Did you forget to enclose it in a list?
      """
  end

  defp argument({:enum, enum}), do: String.upcase(enum)
  defp argument(%Date{} = date), do: inspect(Date.to_iso8601(date))
  defp argument(%DateTime{} = date_time), do: inspect(DateTime.to_iso8601(date_time))
  defp argument(%Time{} = time), do: inspect(Time.to_iso8601(time))

  defp argument(%NaiveDateTime{} = naive_date_time),
    do: inspect(NaiveDateTime.to_iso8601(naive_date_time))

  if Code.ensure_loaded?(Decimal) do
    defp argument(%Decimal{} = decimal), do: Decimal.to_string(decimal)
  end

  defp argument([]), do: "[]"

  defp argument(enum) when is_list(enum) or is_map(enum) do
    if is_map(enum) || Keyword.keyword?(enum) do
      nested_arguments =
        enum
        |> Enum.map_join(", ", fn {key, value} -> "#{key}: #{argument(value)}" end)

      "{#{nested_arguments}}"
    else
      nested_arguments =
        enum
        |> Enum.map_join(", ", &"#{argument(&1)}")

      "[#{nested_arguments}]"
    end
  end

  defp argument(value) do
    inspect(value, printable_limit: :infinity)
  end
end
