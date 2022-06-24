defmodule GraphQLDocument.Enum do
  @moduledoc """
  [Enums](http://spec.graphql.org/October2021/#sec-Enums) can be defined
  in the type system side of GraphQL. `GraphQLDocument` does not currently
  provide the ability to emit GraphQL type system syntax.

  However, if your GraphQL server defines any Enums, you can express
  the [Enum Values](http://spec.graphql.org/October2021/#sec-Enum-Value)
  they define as Values given in Arguments.

  **Enums are expressed as atoms.** See `render/1` for examples.
  """

  alias GraphQLDocument.Name

  @typedoc """
  Enums are specified as atoms. They must be a valid GraphQL Name.

  (See `GraphQLDocument.Name`)
  """
  @type t :: atom

  @doc """
  Return an Enum as iodata to be inserted into a Document.

  ### Examples

      iex> render(User)
      "User"

      iex> render(:User)
      "User"

      iex> render(:user)
      "user"

      iex> render(:_user)
      "_user"

      iex> render(:__user__)
      "__user__"

      iex> render(:"--user--")
      ** (ArgumentError) --user-- is not a valid GraphQL name

  """
  def render(enum) when is_atom(enum) do
    Name.render!(enum)
  end
end
