defmodule GraphQLDocument.Name do
  @moduledoc """
  The GraphQL specification defines a
  [Name](http://spec.graphql.org/October2021/#Name) as starting with a letter
  or underscore. It may only contain letters, underscores, and digits.

  [Fields](http://spec.graphql.org/October2021/#sec-Language.Fields),
  [Types](http://spec.graphql.org/October2021/#Type),
  [Arguments](http://spec.graphql.org/October2021/#sec-Language.Arguments),
  [Variables](http://spec.graphql.org/October2021/#sec-Language.Variables),
  [Directives](http://spec.graphql.org/October2021/#sec-Language.Directives),
  [Fragments](http://spec.graphql.org/October2021/#sec-Language.Fragments),
  and [Enums](http://spec.graphql.org/October2021/#sec-Enums) must all have
  names that conform to this definition.
  """

  @typedoc """
  A Name can be expressed as an atom or string.
  """
  @type t :: atom | String.t()

  @doc """
  Returns a Name as a string to be inserted into a Document.

  Raises an `ArgumentError` if the name doesn't start with a letter or
  underscore, or if it contains any characters other than letters, underscores,
  or digits.

  ### Examples

      iex> render!("_QuiGonJinn")
      "_QuiGonJinn"

      iex> render!(ObiWan)
      "ObiWan"

      iex> render!(:DinDjarin)
      "DinDjarin"

      iex> render!(:leia_organa)
      "leia_organa"

      iex> render!("0_StartingDigit")
      ** (ArgumentError) 0_StartingDigit is not a valid GraphQL name

      iex> render!("_Qui-Gon Jinn")
      ** (ArgumentError) _Qui-Gon Jinn is not a valid GraphQL name

      iex> render!("*;-!")
      ** (ArgumentError) *;-! is not a valid GraphQL name

  """
  @spec render!(atom | String.t()) :: String.t()
  def render!(name) when is_binary(name) do
    if valid?(name) do
      name
    else
      name_description =
        if name == "" do
          "[empty string]"
        else
          name
        end

      raise ArgumentError,
        message: "#{name_description} is not a valid GraphQL name"
    end
  end

  def render!(atom) when is_atom(atom) do
    case Kernel.to_string(atom) do
      "Elixir." <> _ -> render!(Macro.to_string(atom))
      string -> render!(string)
    end
  end

  # return whether a name is valid
  defp valid?(name) when is_binary(name) do
    String.match?(name, ~r/^[_A-Za-z][_0-9A-Za-z]*$/)
  end
end
