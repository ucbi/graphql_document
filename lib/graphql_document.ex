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

  alias GraphQLDocument.{Name, SelectionSet}

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
  @type variable_definition :: {Name.t(), type | {type, [variable_definition_opt]}}

  @typedoc """
  Options that can be passed when defining a variable.

    - `default` sets the default value. (Pass any `t:value/0`)
    - `null: false` makes it a non-nullable (required) variable.

  """
  @type variable_definition_opt :: {:default, value} | {:null, boolean}

  @typedoc "A usage of a defined variable within an operation"
  @type variable :: {:var, Name.t()}

  @typedoc """
  A GraphQL Type.

  See: http://spec.graphql.org/October2021/#Type
  """
  @type type :: Name.t() | [type]

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
  @spec to_string(operation_type, SelectionSet.t(), [operation_option]) :: String.t()
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

    SelectionSet.render(
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
      {"$#{Name.valid_name!(name)}", {:type, type}}
    end
  end
end
