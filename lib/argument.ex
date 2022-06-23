defmodule GraphQLDocument.Argument do
  alias GraphQLDocument.{Name, Value}

  @typedoc """
  A GraphQL argument.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type t :: {Name.t(), Value.t()}

  @doc "Render a list of arguments"
  def render_all(args) do
    unless is_map(args) or is_list(args) do
      raise "Expected a keyword list or map for args, received: #{inspect(args)}"
    end

    if Enum.any?(args) do
      args_string =
        Enum.map_join(args, ", ", fn {key, value} ->
          "#{key}: #{Value.render(value)}"
        end)

      "(#{args_string})"
    else
      ""
    end
  end
end
