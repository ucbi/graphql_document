defmodule GraphQLDocument.Variable do
  alias GraphQLDocument.{Name, Type, Value}

  @typedoc """
  The definition of a variable; goes alongside the `t:operation_type` in the document.

  This is not the _usage_ of the variable (injecting it into an arg somewhere)
  but rather defining its name and type.

  See: http://spec.graphql.org/October2021/#sec-Language.Variables

  ### Examples

      yearOfBirth: Int
      myId: {Int, null: false}
      status: {String, default: "active"}
      daysOfWeek: [String]
      daysOfWeek: {[String], default: ["Saturday", "Sunday"]}

  """
  @type t :: {Name.t(), Type.t() | {Type.t(), [option]}}

  @typedoc """
  Options that can be passed when defining a variable.

    - `default` sets the default value. (Pass any `t:GraphQLDocument.value/0`)
    - `null: false` makes it a non-nullable (required) variable.

  """
  @type option :: {:default, Value.t()} | Type.option()

  @doc """
  Returns variables as iodata to be inserted into a GraphQL document.

  ### Examples

      iex> render([myInt: Int, debug: Boolean]) |> IO.iodata_to_binary()
      " ($myInt: Int, $debug: Boolean)"

      iex> render(lat: Float, lng: Float) |> IO.iodata_to_binary()
      " ($lat: Float, $lng: Float)"

  """
  @spec render(t) :: iodata
  def render(variables) when is_list(variables) do
    if Enum.any?(variables) do
      [
        ?\s,
        ?(,
        variables |> Enum.map(&render_variable/1) |> Enum.intersperse(", "),
        ?)
      ]
    else
      ""
    end
  end

  defp render_variable(variable) do
    {name, type, opts} =
      case variable do
        {name, {type, opts}} -> {name, type, opts}
        {name, type} -> {name, type, []}
      end

    [
      ?$,
      Name.valid_name!(name),
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
