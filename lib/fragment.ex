defmodule GraphQLDocument.Fragment do
  alias GraphQLDocument.{Directive, Name, SelectionSet}

  @typedoc "The name of a fragment"
  @type name :: Name.t()

  @typedoc "The type to which the fragment applies"
  @type on :: Name.t()

  @typedoc "A definition of a fragment"
  @type definition :: {name, {on, SelectionSet.t()} | {on, [Directive.t()], SelectionSet.t()}}

  def render_definitions(fragments) do
    unless is_map(fragments) or is_list(fragments) do
      raise "Expected a keyword list or map for fragments, received: #{inspect(fragments)}"
    end

    Enum.map_join(fragments, "", fn {name, definition} ->
      {on, directives, selection} = case definition do
        {on, selection} -> {on, [], selection}
        {on, directives, selection} -> {on, directives, selection}
      end

      "\n\nfragment #{name} on #{on}#{SelectionSet.render(selection, 1)}"
    end)
  end
end
