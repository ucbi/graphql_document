defmodule GraphQLDocument.Operation do
  alias GraphQLDocument.{Directive, Fragment, Selection, Variable}

  @typedoc "See: http://spec.graphql.org/October2021/#OperationType"
  @type operation_type :: :query | :mutation | :subscription

  @typedoc "Options that can be passed along with the operation."
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
