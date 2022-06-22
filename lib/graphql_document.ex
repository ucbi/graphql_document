defmodule GraphQLDocument do
  @moduledoc """
  A utility for building GraphQL documents. (Strings that contain a GraphQL query/mutation.)

  ## Syntax

  `GraphQLDocument.to_string` converts nested lists/keyword lists into the analogous
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

  `GraphQLDocument.to_string/1` will take that Elixir structure and return

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

  For example, `GraphQLDocument.to_string/1` will take this Elixir structure

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

  `GraphQLDocument.to_string/1` will translate Elixir primitives into the
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

  ### Aliases

  In order to name a field with an alias, follow the syntax below, where `me`
  is the alias and `user` is the field:

  ```elixir
  [query: [
    me: {
      :user
      [id: 100],
      [:name, :email]
    }
  ]]
  ```

  Which will emit this GraphQL document:

  ```elixir
  query {
    me: user(id: 100) {
      name
      email
    }
  }
  ```
  """

  @typedoc "See: http://spec.graphql.org/October2021/#OperationType"
  @type operation_type :: :query | :mutation | :subscription

  @typedoc "Options that can be passed along with the operation."
  @type operation_option :: {:variables, [variable_definition]}

  @typedoc """
  The definition of a variable; goes alongside the `t:operation_type` in the document.

  This is not the _usage_ of the variable (injecting it into an arg somewhere)
  but rather defining its name and type.

  ### Examples

      yearOfBirth: Int
      myId: {Int, null: false}
      status: {String, default: "active"}
      daysOfWeek: [String]
      daysOfWeek: {[String], default: ["Saturday", "Sunday"]}
  """
  @type variable_definition :: {name, type | {type, [variable_definition_opt]}}

  @typedoc """
  Options that can be passed when defining a variable.

    - `default` sets the default value. (Pass any `t:value/0`)
    - `null: false` makes it a non-nullable (required) variable.

  """
  @type variable_definition_opt :: {:default, value} | {:null, boolean}

  @typedoc "A usage of a defined variable within an operation"
  @type variable :: {:var, name}

  @typedoc """
  A GraphQL Type.

  See: http://spec.graphql.org/October2021/#Type
  """
  @type type :: name | [type]

  @typedoc """
  A GraphQL name. Must start with a letter or underscore. May contain letters, underscores, and digits.

  See: http://spec.graphql.org/October2021/#Name
  """
  @type name :: atom | String.t()

  @typedoc """
  A field describes one discrete piece of information available to request within a selection set.

  See: http://spec.graphql.org/October2021/#Field
  """
  @type field :: name | {name, [field]} | {name, {[argument], selection_set}}

  @typedoc """
  A GraphQL argument.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type argument :: {name, value}

  @typedoc """
  A value in GraphQL can be a number, string, boolean, null, an Enum, or a List or Object.

  See: http://spec.graphql.org/October2021/#Value
  """
  @type value ::
          integer
          | float
          | String.t()
          | boolean
          | nil
          | {:enum, String.t()}
          | [value]
          | %{optional(atom) => value}
          | variable

  @typedoc """
  A SelectionSet defines the set of fields in an object to be returned.

  See: http://spec.graphql.org/October2021/#SelectionSet
  """
  @type selection_set :: [field]

  @doc """
  Wraps an enum string value (such as user input from a form) into a
  `GraphQLDocument`-friendly tuple.

  ### Example

      iex> enum("soundex")
      {:enum, "soundex"}

  """
  def enum(str) when is_binary(str), do: {:enum, str}

  @doc """
  Wraps a variable name into a `GraphQLDocument`-friendly tuple.

  ### Example

      iex> var(:foo)
      {:var, :foo}

  """
  def var(name) when is_binary(name) or is_atom(name), do: {:var, name}

  @doc """
  Generates GraphQL syntax from a nested Elixir keyword list.

  ### Example

      iex> GraphQLDocument.to_string(:query, [user: {[id: 3], [:name, :age, :height, documents: [:filename, :url]]}])
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
  @spec to_string(operation_type, selection_set, [operation_option]) :: String.t()
  def to_string(operation_type \\ :query, params, opts \\ []) do
    if operation_type not in [:query, :mutation, :subscription] do
      raise ArgumentError,
        message:
          "[GraphQLDocument] operation_type must be :query, :mutation, or :subscription. Received #{operation_type}"
    end

    unless is_list(params) or is_map(params) do
      raise ArgumentError,
        message: """
        [GraphQLDocument] Expected a list of fields.

        Received: `#{inspect(params)}`
        Did you forget to enclose it in a list?
        """
    end

    variables = Keyword.get(opts, :variables, [])

    selection_set_to_string(
      [
        {
          operation_type,
          {variables_to_args(variables), params}
        }
      ],
      0
    )
  end

  defp variables_to_args(variables) when is_list(variables) do
    for {name, type} <- variables do
      {"$#{valid_name!(name)}", {:type, type}}
    end
  end

  def selection_set_to_string(params, indent_level) when is_list(params) or is_map(params) do
    indent = String.duplicate("  ", indent_level)

    params
    |> Enum.map_join("\n", fn
      field when is_binary(field) or is_atom(field) ->
        "#{indent}#{field}"

      {field, sub_fields} when is_list(sub_fields) ->
        "#{indent}#{field}#{sub_fields(sub_fields, indent, indent_level)}"

      {field, {args, sub_fields}} ->
        "#{indent}#{field}#{args(args)}#{sub_fields(sub_fields, indent, indent_level)}"

      {field_alias, {field, args, sub_fields}} when is_map(args) or is_list(args) ->
        "#{indent}#{field_alias}: #{field}#{args(args)}#{sub_fields(sub_fields, indent, indent_level)}"
    end)
  end

  def selection_set_to_string(params, _indent_level) do
    raise ArgumentError,
      message: """
      [GraphQLDocument] Expected a list of fields.

      Received: `#{inspect(params)}`
      Did you forget to enclose it in a list?
      """
  end

  defp args(args) do
    unless is_map(args) or is_list(args) do
      raise "Expected a keyword list or map for args, received: #{inspect(args)}"
    end

    if Enum.any?(args) do
      args_string =
        Enum.map_join(args, ", ", fn {key, value} ->
          "#{key}: #{argument(value)}"
        end)

      "(#{args_string})"
    else
      ""
    end
  end

  defp sub_fields(sub_fields, indent, indent_level) do
    if Enum.any?(sub_fields) do
      " {\n#{selection_set_to_string(sub_fields, indent_level + 1)}\n#{indent}}"
    else
      ""
    end
  end

  defp argument(%Date{} = date), do: inspect(Date.to_iso8601(date))
  defp argument(%DateTime{} = date_time), do: inspect(DateTime.to_iso8601(date_time))
  defp argument(%Time{} = time), do: inspect(Time.to_iso8601(time))

  defp argument(%NaiveDateTime{} = naive_date_time),
    do: inspect(NaiveDateTime.to_iso8601(naive_date_time))

  if Code.ensure_loaded?(Decimal) do
    defp argument(%Decimal{} = decimal), do: Decimal.to_string(decimal)
  end

  defp argument({:enum, enum}) do
    valid_name!(enum)
  end

  defp argument({:var, var}) do
    "$#{valid_name!(var)}"
  end

  defp argument({:type, type}) do
    {type, opts} =
      case type do
        {type, opts} -> {type, opts}
        type -> {type, []}
      end

    {type, is_list} =
      case type do
        [type] -> {type, true}
        type -> {type, false}
      end

    required =
      if Keyword.get(opts, :null) == false do
        "!"
      end

    default =
      if default = Keyword.get(opts, :default) do
        " = #{argument(default)}"
      end

    type = valid_name!(type)

    rendered_type =
      if is_list do
        "[#{type}]"
      else
        Kernel.to_string(type)
      end

    "#{rendered_type}#{required}#{default}"
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

  defp argument(value) when is_binary(value) do
    inspect(value, printable_limit: :infinity)
  end

  defp argument(value) when is_number(value) do
    inspect(value, printable_limit: :infinity)
  end

  defp argument(value) when is_boolean(value) do
    inspect(value)
  end

  defp argument(value) when is_atom(value) do
    raise ArgumentError,
      message: "[GraphQLDocument] Cannot pass an atom as an argument; received `#{value}`"
  end

  # A GraphQL "Name" matches the following regex.
  # See: http://spec.graphql.org/June2018/#sec-Names
  defp valid_name?(name) when is_binary(name) do
    String.match?(name, ~r/^[_A-Za-z][_0-9A-Za-z]*$/)
  end

  # A GraphQL "Name" matches the following regex.
  # See: http://spec.graphql.org/June2018/#sec-Names
  @spec valid_name!(atom | String.t()) :: String.t()
  defp valid_name!(name) when is_binary(name) do
    if valid_name?(name) do
      name
    else
      raise ArgumentError,
        message:
          "[GraphQLDocument] Names must be a valid GraphQL name, matching this regex: /[_A-Za-z][_0-9A-Za-z]*/ (received #{name})"
    end
  end

  defp valid_name!(atom) when is_atom(atom) do
    case Kernel.to_string(atom) do
      "Elixir." <> _ -> valid_name!(Macro.to_string(atom))
      string -> valid_name!(string)
    end
  end
end
