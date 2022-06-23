defmodule GraphQLDocument.Directive do
  alias GraphQLDocument.{Argument, Name}

  @typedoc """
  A GraphQL directive.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type t :: Name.t() | {Name.t(), [Argument.t()]}

  @doc "Render a list of directives"
  def render_all(directives) do
    unless is_map(directives) or is_list(directives) do
      raise "Expected a keyword list or map for directives, received: #{inspect(directives)}"
    end

    if Enum.any?(directives) do
      directives_string =
        Enum.map_join(directives, " ", fn directive ->
          {name, args} =
            case directive do
              {name, args} -> {name, args}
              name -> {name, []}
            end

          if Enum.any?(args) do
            "@#{name}#{Argument.render_all(args)}"
          else
            "@#{name}"
          end
        end)

      " #{directives_string}"
    else
      ""
    end
  end
end
