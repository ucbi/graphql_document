defmodule GraphQLDocument.Directive do
  alias GraphQLDocument.{Argument, Name}

  @typedoc """
  A GraphQL directive.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type t :: Name.t() | {Name.t(), [Argument.t()]}

  @doc "Render a list of directives"
  @spec render([Directive.t()]) :: iolist
  def render(directives) do
    unless is_map(directives) or is_list(directives) do
      raise "Expected a keyword list or map for directives, received: #{inspect(directives)}"
    end

    if Enum.any?(directives) do
      rendered =
        directives
        |> Enum.map(fn directive ->
          {name, args} =
            case directive do
              {name, args} -> {name, args}
              name -> {name, []}
            end

          if Enum.any?(args) do
            [
              ?@,
              Name.valid_name!(name),
              Argument.render(args)
            ]
          else
            [
              ?@,
              Name.valid_name!(name)
            ]
          end
        end)
        |> Enum.intersperse(?\s)

      [
        ?\s,
        rendered
      ]
    else
      []
    end
  end
end
