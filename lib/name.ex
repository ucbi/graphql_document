defmodule GraphQLDocument.Name do
  @typedoc """
  A GraphQL name. Must start with a letter or underscore. May contain letters, underscores, and digits.

  See: http://spec.graphql.org/October2021/#Name
  """
  @type t :: atom | String.t()

  @doc "Given a name, return it back as a string if it's valid. If it's not valid, crash."
  @spec valid_name!(atom | String.t()) :: String.t()
  def valid_name!(name) when is_binary(name) do
    if valid?(name) do
      name
    else
      raise ArgumentError,
        message:
          "[GraphQLDocument] Names must be a valid GraphQL name, matching this regex: /[_A-Za-z][_0-9A-Za-z]*/ (received #{name})"
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
