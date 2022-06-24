defmodule GraphQLDocument.Type do
  alias GraphQLDocument.Name

  @typedoc """
  A GraphQL Type.

  See: http://spec.graphql.org/October2021/#Type
  """
  @type t :: Name.t() | [t] | {Name.t() | [t], [option]}

  @typedoc """
  Options to be passed along with a type.

    - `null` - Whether it can be null

  """
  @type option :: {:null, boolean}

  @doc ~S'''
  Returns a type as an iolist ready to be rendered in a GraphQL document.

  ### Examples

      iex> render(Int) |> IO.iodata_to_binary()
      "Int"

      iex> render(Boolean) |> IO.iodata_to_binary()
      "Boolean"

      iex> render({Boolean, null: false}) |> IO.iodata_to_binary()
      "Boolean!"

      iex> render({[{Boolean, null: false}], null: false}) |> IO.iodata_to_binary()
      "[Boolean!]!"

  '''
  @spec render(t) :: iolist
  def render(type) do
    {type, opts} =
      case type do
        {type, opts} -> {type, opts}
        type -> {type, []}
      end

    {type, is_list} =
      case type do
        [type] -> {type, true}
        type -> {type, false}
      end

    [
      if is_list do
        ?[
      else
        []
      end,
      # types can be lists of lists, ad infinitum, so we must recurse
      if is_list do
        render(type)
      else
        Name.valid_name!(type)
      end,
      if is_list do
        ?]
      else
        []
      end,
      if Keyword.get(opts, :null) == false do
        ?!
      else
        []
      end
    ]
  end
end
