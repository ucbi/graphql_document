defmodule GraphQLDocument.Name do
  @typedoc """
  A GraphQL name. Must start with a letter or underscore. May contain letters, underscores, and digits.

  See: http://spec.graphql.org/October2021/#Name
  """
  @type t :: atom | String.t()

  @doc """
  Given a name, returns it back as a string if it's valid.

  Raises an `ArgumentError` if it's not valid.

  ### Examples

      iex> valid_name!("_QuiGonJinn")
      "_QuiGonJinn"

      iex> valid_name!(ObiWan)
      "ObiWan"

      iex> valid_name!(:DinDjarin)
      "DinDjarin"

      iex> valid_name!(:leia_organa)
      "leia_organa"

      iex> valid_name!("0_StartingDigit")
      ** (ArgumentError) 0_StartingDigit is not a valid GraphQL name

      iex> valid_name!("_Qui-Gon Jinn")
      ** (ArgumentError) _Qui-Gon Jinn is not a valid GraphQL name

      iex> valid_name!("*;-!")
      ** (ArgumentError) *;-! is not a valid GraphQL name

  """
  @spec valid_name!(atom | String.t()) :: String.t()
  def valid_name!(name) when is_binary(name) do
    if valid?(name) do
      name
    else
      raise ArgumentError,
        message: "#{name} is not a valid GraphQL name"
    end
  end

  def valid_name!(atom) when is_atom(atom) do
    case Kernel.to_string(atom) do
      "Elixir." <> _ -> valid_name!(Macro.to_string(atom))
      string -> valid_name!(string)
    end
  end

  # return whether a name is valid
  defp valid?(name) when is_binary(name) do
    String.match?(name, ~r/^[_A-Za-z][_0-9A-Za-z]*$/)
  end
end
