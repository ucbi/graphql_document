defmodule GraphQLDocument do
  @moduledoc """
  A utility for building GraphQL documents. (Strings that contain a GraphQL query/mutation.)

  ## Syntax

  The functions in this library take **nested [keyword] lists** in the same
  structure as GraphQL, and return that GraphQL document as a `String`.

  These functions are available:

    - `GraphQLDocument.query/2`
    - `GraphQLDocument.mutation/2`
    - `GraphQLDocument.subscription/2`

  Let's take a look at some examples.

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

  GraphQL enums can be expressed using `GraphQLDocument.var/1` or in a tuple
  syntax, like this.

  ```
  {:enum, "FOOT"}
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
  """

  alias GraphQLDocument.Operation

  def field(config), do: {:__field__, config}

  def field(name, config), do: {:__field__, name, config}

  @doc """
  Wraps an enum string value (such as user input from a form) in a
  `GraphQLDocument`-friendly tuple.

  ### Example

      iex> enum("soundex")
      {:enum, "soundex"}

  """
  def enum(str) when is_binary(str), do: {:enum, str}

  @doc """
  Wraps a variable name in a `GraphQLDocument`-friendly tuple.

  ### Example

      iex> var(:foo)
      {:var, :foo}

  """
  def var(name) when is_binary(name) or is_atom(name), do: {:var, name}

  @doc """
  Wraps a fragment spread in `GraphQLDocument`-friendly tuple.

  TODO: Document usage with directives.

  ### Example

      iex> fragment(:foo)
      {:__fragment__, :foo}

  """
  def fragment(name) when is_binary(name) or is_atom(name), do: {:__fragment__, name}

  @doc """
  Wraps an inline fragment in `GraphQLDocument`-friendly tuple.

  TODO: Document usage with directives.

  ### Example

      iex> inline_fragment({User, [:name, :email]})
      {:__inline_fragment__, {User, [:name, :email]}}

  """
  def inline_fragment(inline), do: {:__inline_fragment__, inline}

  @doc """
  Generate a GraphQL query document.
  """
  def query(selection, opts \\ []) do
    operation(:query, selection, opts)
  end

  @doc """
  Generate a GraphQL mutation document.
  """
  def mutation(selection, opts \\ []) do
    operation(:mutation, selection, opts)
  end

  @doc """
  Generate a GraphQL subscription document.
  """
  def subscription(selection, opts \\ []) do
    operation(:subscription, selection, opts)
  end

  defdelegate operation(operation_type, selection, opts), to: Operation, as: :render
  defdelegate operation(operation_type, selection), to: Operation, as: :render
  defdelegate operation(selection), to: Operation, as: :render
end
