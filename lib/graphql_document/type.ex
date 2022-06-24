defmodule GraphQLDocument.Type do
  @moduledoc """
  A [Type](http://spec.graphql.org/October2021/#sec-Type-References) is a
  reference to a
  [TypeDefinition](http://spec.graphql.org/October2021/#sec-Types)
  defined by a GraphQL service.

  Types are used in `GraphQLDocument` when defining Variables. (See `GraphQLDocument.Variable`)
  """

  alias GraphQLDocument.Name

  @typedoc """
  A named type or a list type.

  Can be wrapped in a tuple to provide options, which are used to specify if it
  can be null.

  See `render/1` for examples.
  """
  @type t :: Name.t() | [t] | {Name.t() | [t], [option]}

  @typedoc """
  Options to be passed along with a Type.

    - `null` - Whether it can be null

  """
  @type option :: {:null, boolean}

  @doc ~S'''
  Returns a Type as an iolist to be inserted into a Document.

  ### Examples

      iex> render(Int)
      ...> |> IO.iodata_to_binary()
      "Int"

      iex> render(Boolean)
      ...> |> IO.iodata_to_binary()
      "Boolean"

      iex> render([String])
      ...> |> IO.iodata_to_binary()
      "[String]"

      iex> render({Boolean, null: false})
      ...> |> IO.iodata_to_binary()
      "Boolean!"

      iex> render({[{Boolean, null: false}], null: false})
      ...> |> IO.iodata_to_binary()
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
        Name.render!(type)
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
