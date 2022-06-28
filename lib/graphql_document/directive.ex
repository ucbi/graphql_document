defmodule GraphQLDocument.Directive do
  @moduledoc """
  > [Directives](http://spec.graphql.org/October2021/#Directives) provide a way
  > to describe alternate runtime execution and type validation behavior in a
  > GraphQL document.

  A Directive might be simply a name, or it can have arguments.
  See `render/1` for examples.
  """

  alias GraphQLDocument.{Argument, Name}

  @typedoc """
  A GraphQL directive.

  ### Examples

      :debug
      [log: [level: "warn"]]

  """
  @type t :: Name.t() | {Name.t(), [Argument.t()]}

  @doc """
  Returns a list of directives as iodata to be inserted into a Document.

  ### Examples

      iex> render([log: [level: "warn"]]) |> IO.iodata_to_binary()
      " @log(level: \\"warn\\")"

      iex> render([:debug]) |> IO.iodata_to_binary()
      " @debug"

  """
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
              Name.render!(name),
              Argument.render(args)
            ]
          else
            [
              ?@,
              Name.render!(name)
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
