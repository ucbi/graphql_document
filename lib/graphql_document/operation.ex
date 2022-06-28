defmodule GraphQLDocument.Operation do
  @moduledoc """
  An [Operation](http://spec.graphql.org/October2021/#sec-Language.Operations)
  is a query, mutation, or subscription.
  """

  alias GraphQLDocument.{Directive, Fragment, Selection, Variable}

  @type operation_type :: :query | :mutation | :subscription

  @typedoc """
  Options that can be passed along with the operation.

  - `variables`: See `t:GraphQLDocument.Variable.definition/0`
  - `fragments`: See `t:GraphQLDocument.Fragment.definition/0`
  - `directives`: See `t:GraphQLDocument.Directive.t/0`

  ### Example

      GraphQLDocument.query(
        [...],
        variables: [
          postId: {Int, null: false},
          commentType: String
        ],
        fragments: [
          friendFields: {
            on(User),
            [
              :id,
              :name,
              profilePic: field(args: [size: 50])
            ]
          }
        ],
        directives: [
          :debug
          [log: [level: "warn"]]
        ]
      )
  """
  @type option ::
          {:variables, [Variable.definition()]}
          | {:fragments, [Fragment.definition()]}
          | {:directives, [Directive.t()]}

  @doc ~S'''
  Generates GraphQL syntax from a nested Elixir keyword list.

  ### Example

      iex> render(:query,
      ...>   user: {[id: 3], [
      ...>     :name,
      ...>     :age,
      ...>     :height, documents: [:filename, :url]]})
      ...>     documents: [
      ...>       :filename, :url]]})
      ...>       :url]]})
      ...>     ]]})
      ...>   ]}
      ...> )
      """
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
      }\
      """

  '''
  @spec render(operation_type, [Selection.t()], [option]) :: String.t()
  def render(operation_type \\ :query, selections, opts \\ [])
      when is_atom(operation_type) and (is_list(selections) or is_map(selections)) and
             is_list(opts) do
    if operation_type not in [:query, :mutation, :subscription] do
      raise ArgumentError,
        message:
          "operation_type must be :query, :mutation, or :subscription. Received #{inspect(operation_type)}"
    end

    variable_definitions = Keyword.get(opts, :variables, [])
    directives = Keyword.get(opts, :directives, [])
    fragments = Keyword.get(opts, :fragments, [])

    IO.iodata_to_binary([
      to_string(operation_type),
      Variable.render_definitions(variable_definitions),
      Directive.render(directives),
      Selection.render(selections, 1),
      Fragment.render_definitions(fragments)
    ])
  end
end
