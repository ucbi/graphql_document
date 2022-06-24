defmodule GraphQLDocument.Variable do
  @moduledoc """
  [Variables](http://spec.graphql.org/October2021/#sec-Language.Variables) are
  defined in [VariableDefinitions](http://spec.graphql.org/October2021/#VariableDefinition)
  alongside the
  [OperationType](http://spec.graphql.org/October2021/#OperationType) at the
  beginning of a GraphQL document.

  Any Variable that is defined in a Document can be used as the value of an
  Argument.
  """

  alias GraphQLDocument.{Name, Type, Value}

  @typedoc "Expresses the name of a Variable to be used as a Value (See `GraphQLDocument.Value`)"
  @type t :: {:var, Name.t()}

  @typedoc """
  These are given in the `variables` key of the Operation options. (See
  `t:GraphQLDocument.Operation.option/0`.)

  This is not the _usage_ of the Variable (as the Value of an Argument) but
  rather defining its Name and Type to be used in the rest of the Document.

  ### Examples

      GraphQLDocument.query(
        [...],
        variables: [
          yearOfBirth: Int,
          myId: {Int, null: false},
          status: {String, default: "active"},
          days: [String],
          daysOfWeek: {[String], default: ["Saturday", "Sunday"]}
        ]
      )

  """
  @type definition :: {Name.t(), Type.t() | {Type.t(), [option]}}

  @typedoc """
  Options that can be passed when defining a variable.

  For the `default` option, pass any `t:GraphQLDocument.Value.t/0`.

  See `t:definition/0` for examples.
  """
  @type option :: {:default, Value.t()} | Type.option()

  @doc """
  Returns a Variable as iodata to be inserted into a Document.

  ### Examples

      iex> render({:var, :expandedInfo})
      ...> |> IO.iodata_to_binary()
      "$expandedInfo"

      iex> render({:var, "username"})
      ...> |> IO.iodata_to_binary()
      "$username"

      iex> render({:var, ""})
      ...> |> IO.iodata_to_binary()
      ** (ArgumentError) [empty string] is not a valid GraphQL name

  """
  def render({:var, var}) do
    [
      ?$,
      Name.render!(var)
    ]
  end

  @doc """
  Returns Variable definitions as iodata to be inserted into a Document.

  > #### Leading Space {: .neutral}
  >
  > If any definitions are given, the returned iodata includes a leading space
  > so that the output can be inserted into a Document either way and generate
  > valid GraphQL syntax.

  ### Examples

      iex> render_definitions([])
      ...> |> IO.iodata_to_binary()
      ""

      iex> render_definitions([myInt: Int, debug: Boolean])
      ...> |> IO.iodata_to_binary()
      " ($myInt: Int, $debug: Boolean)"

      iex> render_definitions(lat: Float, lng: Float)
      ...> |> IO.iodata_to_binary()
      " ($lat: Float, $lng: Float)"

  """
  @spec render_definitions(definition) :: iodata
  def render_definitions(variables) when is_list(variables) do
    if Enum.any?(variables) do
      [
        ?\s,
        ?(,
        variables |> Enum.map(&render_definition/1) |> Enum.intersperse(", "),
        ?)
      ]
    else
      ""
    end
  end

  defp render_definition(variable) do
    {name, type, opts} =
      case variable do
        {name, {type, opts}} -> {name, type, opts}
        {name, type} -> {name, type, []}
      end

    [
      ?$,
      Name.render!(name),
      ?:,
      ?\s,
      Type.render({type, opts}),
      if default = Keyword.get(opts, :default) do
        [" = ", Value.render(default)]
      else
        []
      end
    ]
  end
end
