defmodule GraphQLDocument.Operation do
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
  @type variable_definition :: {Name.t(), GraphQLDocument.type | {GraphQLDocument.type, [variable_definition_opt]}}

  @typedoc """
  Options that can be passed when defining a variable.

    - `default` sets the default value. (Pass any `t:GraphQLDocument.value/0`)
    - `null: false` makes it a non-nullable (required) variable.

  """
  @type variable_definition_opt :: {:default, GraphQLDocument.value} | {:null, boolean}

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
  def render(operation_type, selection, opts) when is_atom(operation_type) and is_list(selection) and is_list(opts) do
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

    SelectionSet.render(
      [
        {
          operation_type,
          {variables_to_args(variables), selection}
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
