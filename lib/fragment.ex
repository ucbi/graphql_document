defmodule GraphQLDocument.Fragment do
  alias GraphQLDocument.{Directive, Name, SelectionSet}

  @typedoc "The name of a fragment"
  @type name :: Name.t()

  @typedoc "The type to which the fragment applies"
  @type on :: Name.t()

  @typedoc "A definition of a fragment"
  @type definition :: {name, {on, SelectionSet.t()} | {on, [Directive.t()], SelectionSet.t()}}

  @typedoc """
  A fragment spread is injecting `...fragmentName` into a request to instruct
  the server to return the fields in the fragment.
  """
  @type spread :: {:__fragment__, name} | {:__fragment__, {name, [Directive.t()]}}

  def render_definitions(fragments) do
    unless is_map(fragments) or is_list(fragments) do
      raise "Expected a keyword list or map for fragments, received: #{inspect(fragments)}"
    end

    Enum.map_join(fragments, "", fn {name, definition} ->
      {on, directives, selection} =
        case definition do
          {on, selection} -> {on, [], selection}
          {on, directives, selection} -> {on, directives, selection}
        end

      "\n\nfragment #{name} on #{on}#{Directive.render(directives)}#{SelectionSet.render(selection, 1)}"
    end)
  end

  def render_spread(name, directives \\ []) do
    "...#{name}#{Directive.render(directives)}"
  end
end
