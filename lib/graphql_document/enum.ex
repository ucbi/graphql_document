defmodule GraphQLDocument.Enum do
  @moduledoc """
  [Enums](http://spec.graphql.org/October2021/#sec-Enums) can be defined
  in the Type System side of GraphQL.

  For the purposes of making GraphQL requests, you can express
  [Enum Values](http://spec.graphql.org/October2021/#sec-Enum-Value) as Values
  given in Arguments.

  > #### Enums are expressed as atoms. {: .tip}
  >
  > You can use any valid atom syntax, such as `Person` or `:Person` or `:"Person"`.
  >
  > However, all enums must be valid GraphQL Names. See `GraphQLDocument.Name`.

  See `render/1` for examples.
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
