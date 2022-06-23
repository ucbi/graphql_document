defmodule GraphQLDocument.Argument do
  alias GraphQLDocument.{Name, Value}

  @typedoc """
  A GraphQL argument.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type t :: {Name.t(), Value.t()}

  @doc "Render a list of arguments"
  @spec render([t]) :: iolist
  def render(args) do
    unless is_map(args) or is_list(args) do
      raise "Expected a keyword list or map for args, received: #{inspect(args)}"
    end

    if Enum.any?(args) do
      [
        ?(,
        args
        |> Enum.map(fn {key, value} ->
          [
            Name.valid_name!(key),
            ?:,
            ?\s,
            Value.render(value)
          ]
        end)
        |> Enum.intersperse(", "),
        ?)
      ]
    else
      []
    end
  end
end
