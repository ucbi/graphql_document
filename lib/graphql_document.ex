defmodule GraphQLDocument do
  @moduledoc """
  Builds [GraphQL](https://graphql.org/)
  [Documents](http://spec.graphql.org/October2021/#sec-Document) from Elixir
  primitives.

  These functions take Elixir data in the same structure as GraphQL and return the analogous GraphQL Document as a `String`.

    - `GraphQLDocument.query/2`
    - `GraphQLDocument.mutation/2`
    - `GraphQLDocument.subscription/2`

  Using these abilities, developers can generate GraphQL queries programmatically.
  `GraphQLDocument` can be used to create higher-level
  [DSL](https://en.wikipedia.org/wiki/Domain-specific_language)s
  for writing GraphQL queries.

  ## Getting Started

  > #### Elixir & GraphQL Code Snippets {: .info}
  >
  > Each Elixir code snippet is immediately followed by the GraphQL that it
  > will produce.

  All functions called in the code snippets below are in `GraphQLDocument`.
  (`import GraphQLDocument` to directly use them.)

  ### Object Fields

  To request a list of fields in an object, include them in a list.

  ```
  query([
    human: [
      :name,
      :height
    ]
  ])
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

  Wrap arguments along with child fields in a tuple.

  ```
  {args, fields}
  ```

  ```
  query(
    human: {[id: "1000"], [
      :name,
      :height
    ]}
  )
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

  Elixir primitives (numbers, strings, lists, booleans, etc.) are translated
  into the analogous GraphQL primitive.

  Enums are expressed with atoms, like `MY_ENUM`, `:MY_ENUM`, or `:"MY_ENUM"`

  ```
  query(
    human: {[id: "1000"], [
      :name,
      height: {[unit: FOOT], []}
    ]}
  )
  ```

  ```gql
  query {
    human(id: "1000") {
      name
      height(unit: FOOT)
    }
  }
  ```

  > #### Expressing Arguments Without Sub-fields {: .tip}
  >
  > Notice the slightly complicated syntax above: `height: {[unit: FOOT], []}`
  >
  > Since `args` can be expressed in `{args, fields}` tuple, we put `[]` where
  > the sub-fields go because there are no sub-fields.
  >
  > This can also be expressed as `height: field(args: [unit: FOOT])`. See `field/1`.

  ### Mixing Lists and Keyword Lists

  Since GraphQL supports a theoretically infinite amount of nesting, you can also
  nest as much as needed in the Elixir structure.

  Furthermore, we can take advantage of Elixir's syntax feature that allows a
  regular list to be "mixed" with a keyword list. (The keyword pairs must be at
  the end.)

  ```
  # Elixir allows lists with a Keyword List as the final members
  [
    :name,
    :height,
    friends: [
      :name,
      :age
    ]
  ]
  ```

  Using this syntax, we can build a nested structure where we select primitive
  fields (like `:name` below) alongside object fields (like `:friends`).

  ```
  query(
    human: {[id: "1000"], [
      :name,
      :height,
      friends: {[olderThan: 30], [
        :name,
        :height
      ]}
    ]}
  )
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

  ### Variables

  To express a variable as a value, use `{:var, var_name}` syntax or the
  `var/1` function.

  The variable definition is passed as an option to `query/2`, `mutation/2`, or
  `subscription/2`.

  Variable types can take the form `Int`, `{Int, null: false}`, or `{Int, default: 1}`.

  ```
  query(
    [
      user: {
        [id: var(:myId)],
        [
          :name,
          friends: {
            [type: {:var, :friendType}],
            [:name]
          }
        ]
      }
    ],
    variables: [
      myId: {Int, null: false},
      friendType: {String, default: "best"}
    ]
  )
  ```

  ```gql
  query ($myId: Int!, $friendType: String = "best") {
    user(id: $myId) {
      name
      friends(type: $friendType) {
        name
      }
    }
  }
  ```

  ### Fragments

  To express a fragment, use the `:...` atom as the field name, similar to how
  you would in GraphQL.

  The fragment definition is passed as an option to `query/2`, `mutation/2`, or
  `subscription/2`.

  Inline fragments and fragment definitions use the `on/1` function to specify
  the type condition.

  ```
  query(
    [
      self: [
       ...: {
         on(User),
         [skip: [if: true]],
         [:password, :passwordHash]
       },
       friends: [
         ...: :friendFields
       ]
     ]
    ],
    fragments: [
      friendFields: {on(User), [
        :id,
        :name,
        profilePic: field(args: [size: 50])
      ]}
    ]
  )
  ```

  ```gql
  query {
    self {
      ... on User @skip(if: true) {
        password
        passwordHash
      }
      friends(first: 10) {
        ...friendFields
      }
    }
  }

  fragment friendFields on User {
    id
    name
    profilePic(size: 50)
  }
  ```

  ## Features That Require `field()`

  The `field/1` and `field/2` functions are required in order to express [Aliases](#module-aliases)
  and [Directives](#module-directives).

  ### Aliases

  Express an alias by putting the alias in place of the field name, and pass
  the field name as the first argument to `field/2`.

  In the example below, `me` is the alias and `user` is the field.

  > #### Spot the Keyword List {: .info}
  >
  > `args:` and `select:` below are members of an "invisible" keyword list
  > using Elixir's [call syntax](https://hexdocs.pm/elixir/Keyword.html#module-call-syntax).

  ```
  query(
    me: field(
      :user,
      args: [id: 100],
      select: [:name, :email]
    )
  )
  ```

  ```gql
  query {
    me: user(id: 100) {
      name
      email
    }
  }
  ```

  ### Directives

  Express a directive by passing `directives:` to `field/1` or `field/2`.

  A directive can be a single name (as an atom or string) or a tuple in
  `{name, args}` format.

  ```
  query(
    self: field(
      directives: [:debug, log: [level: "warn"]]
      select: [:name, :email]
    )
  )
  ```

  ```gql
  query {
    self @debug @log(level: "warn") {
      name
      email
    }
  }
  ```

  ## Not-yet-supported features

  `GraphQLDocument` does not currently have the ability to generate Type System
  definitions, although they technically belong in a Document.

  """

  alias GraphQLDocument.{Field, Fragment, Name, Operation, Selection}

  @type field_config :: [
          {:args, [Argument.t()]}
          | {:directives, [Directive.t()]}
          | {:select, [Selection.t()]}
        ]

  @doc """
  If you want to express a field with directives or an alias, you must use this
  function.

  See `field/2` if you want to specify an alias.

  ### Examples

      iex> field(
      ...>   args: [id: 2],
      ...>   directives: [:debug],
      ...>   select: [:name]
      ...> )
      {
        :field,
        [
          args: [id: 2],
          directives: [:debug],
          select: [:name]
        ]
      }

  """
  @spec field(field_config) :: Field.spec()
  def field(config), do: {:field, config}

  @doc """
  If you want to express a field with an alias, you must use this function.

  Put the alias where you would normally put the field name, and pass the
  field name as the first argument to `field/2`.

  See `field/1` if you want to specify directives without an alias.

  ### Examples

      iex> field(
      ...>   :user,
      ...>   args: [id: 2],
      ...>   directives: [:debug],
      ...>   select: [:name]
      ...> )
      {
        :field,
        :user,
        [
          args: [id: 2],
          directives: [:debug],
          select: [:name]
        ]
      }

  """
  @spec field(Name.t(), field_config) :: Field.spec()
  def field(name, config), do: {:field, name, config}

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

  See `GraphQLDocument.Fragment` for more details.

  ### Example

      iex> on(User)
      {:on, User}

  """
  @spec on(Name.t()) :: Fragment.type_condition()
  def on(name) when is_binary(name) or is_atom(name), do: {:on, name}

  @doc ~S'''
  Generate a GraphQL query document.

  See the **[Getting Started](#module-getting-started)** section for more details.

  ### Example

      iex> query(
      ...>   [
      ...>     customer: {[id: var(:customerId)], [
      ...>       :name,
      ...>       :email,
      ...>       phoneNumbers: field(args: [type: MOBILE]),
      ...>       cartItems: [
      ...>         :costPerItem,
      ...>         ...: :cartDetails
      ...>       ]
      ...>     ]}
      ...>   ],
      ...>   variables: [customerId: Int],
      ...>   fragments: [cartDetails: {
      ...>     on(CartItem),
      ...>     [:sku, :description, :count]
      ...>   }]
      ...> )
      """
      query ($customerId: Int) {
        customer(id: $customerId) {
          name
          email
          phoneNumbers(type: MOBILE)
          cartItems {
            costPerItem
            ...cartDetails
          }
        }
      }
      \nfragment cartDetails on CartItem {
        sku
        description
        count
      }\
      """
  '''
  @spec query([Selection.t()], [Operation.option()]) :: String.t()
  def query(selections, opts \\ []) do
    Operation.render(:query, selections, opts)
  end

  @doc ~S'''
  Generate a GraphQL mutation document.

  See the **[Getting Started](#module-getting-started)** section for more details.
  ### Example

      iex> mutation(
      ...>   registerUser: {
      ...>     [
      ...>       name: "Ben",
      ...>       hexUsername: "benwilson512",
      ...>       packages: ["absinthe", "ex_aws"]
      ...>     ],
      ...>     [
      ...>       :id,
      ...>     ]
      ...>   }
      ...> )
      """
      mutation {
        registerUser(name: "Ben", hexUsername: "benwilson512", packages: ["absinthe", "ex_aws"]) {
          id
        }
      }\
      """
  '''
  @spec mutation([Selection.t()], [Operation.option()]) :: String.t()
  def mutation(selections, opts \\ []) do
    Operation.render(:mutation, selections, opts)
  end

  @doc """
  Generate a GraphQL subscription document.

  Works like `query/2` and `mutation/2`, except that it generates a
  subscription.

  See the **[Getting Started](#module-getting-started)** section for more details.
  """
  @spec subscription([Selection.t()], [Operation.option()]) :: String.t()
  def subscription(selections, opts \\ []) do
    Operation.render(:subscription, selections, opts)
  end
end
