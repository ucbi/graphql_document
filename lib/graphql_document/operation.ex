defmodule GraphQLDocument.Operation do
  alias GraphQLDocument.{Directive, Fragment, SelectionSet, Variable}

  @typedoc "See: http://spec.graphql.org/October2021/#OperationType"
  @type operation_type :: :query | :mutation | :subscription

  @typedoc "Options that can be passed along with the operation."
  @type operation_option ::
          {:variables, [Variable.t()]}
          | {:directives, [Directive.t()]}
          | {:fragments, [Fragment.definition()]}

  @doc """
  Generates GraphQL syntax from a nested Elixir keyword list.

  ### Example

      iex> render(:query, [user: {[id: 3], [:name, :age, :height, documents: [:filename, :url]]}])
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
  @spec render(operation_type, SelectionSet.t(), [operation_option]) :: String.t()
  def render(operation_type \\ :query, selection, opts \\ [])
      when is_atom(operation_type) and is_list(selection) and is_list(opts) do
    if operation_type not in [:query, :mutation, :subscription] do
      raise ArgumentError,
        message:
          "[GraphQLDocument] operation_type must be :query, :mutation, or :subscription. Received #{inspect(operation_type)}"
    end

    unless is_list(selection) or is_map(selection) do
      raise ArgumentError,
        message: """
        [GraphQLDocument] Expected a list of fields.

        Received: `#{inspect(selection)}`
        Did you forget to enclose it in a list?
        """
    end

    variables = Keyword.get(opts, :variables, [])
    directives = Keyword.get(opts, :directives, [])
    fragments = Keyword.get(opts, :fragments, [])

    IO.iodata_to_binary([
      to_string(operation_type),
      Variable.render(variables),
      Directive.render(directives),
      SelectionSet.render(selection, 1),
      Fragment.render_definitions(fragments)
    ])
  end
end
