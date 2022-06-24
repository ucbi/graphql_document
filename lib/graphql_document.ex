defmodule GraphQLDocument do
  @moduledoc """
  Builds [GraphQL](https://graphql.org/)
  [Documents](http://spec.graphql.org/October2021/#sec-Document) from Elixir
  primitives.

  These functions take Elixir data in the same structure as GraphQL and return the analogous GraphQL Document as a `String`.

    - `GraphQLDocument.query/2`
    - `GraphQLDocument.mutation/2`
    - `GraphQLDocument.subscription/2`

  ## Syntax

  ### Object Fields

  To request a list of fields in an object, include them in a list.

  `GraphQLDocument.query/2` will take this Elixir structure and return the
  GraphQL document below.

  ```elixir
  [
    human: [:name, :height]
  ]
  ```

  ```gql
  query {
    human {
      name
      height
    }
  }
  ```

  ### Arguments

  When a field includes arguments, wrap the arguments and child fields in a
  tuple, like this.

  ```elixir
  {args, fields}
  ```

  `GraphQLDocument.query/2` will take this Elixir structure and return the
  GraphQL document below.

  ```elixir
  [human: {
    [id: "1000"],
    [:name, :height]
  }]
  ```

  ```gql
  query {
    human(id: "1000") {
      name
      height
    }
  }
  ```

  #### Argument types and Enums

  Provide Elixir primitives (numbers, strings, lists, booleans, etc.) as
  arguments, and they'll be translated into the analogous GraphQL primitive.

  GraphQL enums can be expressed using atoms:

  ```
  FOOT
  ```

  For example, this Elixir structure becomes the following GraphQL document.

  ```elixir
  [human: {
    [id: "1000"],
    [:name, height: {[unit: FOOT], []}]
  }]
  ```

  ```gql
  query {
    human(id: "1000") {
      name
      height(unit: FOOT)
    }
  }
  ```

  > #### Expressing arguments without sub-fields {: .tip}
  >
  > Notice the slightly complicated syntax above: `height: {[unit: FOOT], []}`
  >
  > The way to include arguments is in an `{args, fields}` tuple. So if a
  > field has arguments but no sub-fields, put `[]` where the sub-fields go.
  >
  > Alternatively, use the `GraphQLDocument.field/1` helper.

  ### Nesting Fields

  Since GraphQL supports a theoretically infinite amount of nesting, you can also
  nest as much as needed in the Elixir structure.

  Furthermore, we can take advantage of Elixir's syntax feature that allows a
  regular list to be "mixed" with a keyword list.

  ```elixir
  # Elixir allows lists with a Keyword List as the final members
  [:name, :height, friends: [:name, :age]]
  ```

  Using this syntax, we can build a nested structure like this, which
  translates to the GraphQL below.

  ```elixir
  [human: {
    [id: "1000"],
    [
      :name,
      :height,
      friends: {
        [olderThan: 30],
        [:name, :height]
      }
    ]
  }]
  ```

  ```gql
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

  In order to name a field with an alias, follow the syntax below using
  `GraphQLDocument.field/1`, where `me` is the alias and `user` is the field:

  ```elixir
  [me: field(
    :user,
    args: [id: 100],
    select: [:name, :email]
  )]
  ```

  Which will emit this GraphQL document:

  ```gql
  query {
    me: user(id: 100) {
      name
      email
    }
  }
  ```

  ## Not-yet-supported features

  `GraphQLDocument` does not currently have the ability to generate Type System
  definitions, although they technically go in a Document.

  """

  alias GraphQLDocument.{Name, Operation, Fragment}

  @doc """
  If you want to express a field with directives or an alias, you must use
  this function.

  ### Examples

      iex> field(args: [id: 2], select: [:name])
      {:__field__, [args: [id: 2], select: [:name]]}

      iex> field(:user, args: [id: 2], select: [:name])
      {:__field__, :user, [args: [id: 2], select: [:name]]}

  """
  def field(config), do: {:__field__, config}

  def field(name, config), do: {:__field__, name, config}

  @doc """
  Wraps a variable name in a `GraphQLDocument`-friendly tuple.

  ### Example

      iex> var(:foo)
      {:var, :foo}

  """
  def var(name) when is_binary(name) or is_atom(name), do: {:var, name}

  @doc """
  Creates a [TypeCondition](http://spec.graphql.org/October2021/#TypeCondition)
  for a [Fragment](http://spec.graphql.org/October2021/#sec-Language.Fragments).

  ### Example

      iex> on(User)
      {:on, User}

  """
  @spec on(Name.t()) :: Fragment.type_condition()
  def on(name) when is_binary(name) or is_atom(name), do: {:on, name}

  @doc """
  Generate a GraphQL query document.
  """
  def query(selections, opts \\ []) do
    operation(:query, selections, opts)
  end

  @doc """
  Generate a GraphQL mutation document.
  """
  def mutation(selections, opts \\ []) do
    operation(:mutation, selections, opts)
  end

  @doc """
  Generate a GraphQL subscription document.
  """
  def subscription(selections, opts \\ []) do
    operation(:subscription, selections, opts)
  end

  defdelegate operation(operation_type, selections, opts), to: Operation, as: :render
  defdelegate operation(operation_type, selections), to: Operation, as: :render
  defdelegate operation(selections), to: Operation, as: :render
end
