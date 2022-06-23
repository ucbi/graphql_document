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

  @typedoc """
  An inline fragment is a fragment that doesn't have a definition;
  the definition appears right in the middle of a selection set
  in the query/mutation/subscription.

  It exists to support requesting certain fields only if the
  object is a certain type (for objects of a union type),
  or to apply directives to only a subset of fields.
  """
  @type inline ::
          {:__inline_fragment__, SelectionSet.t()}
          | {:__inline_fragment__, {on, SelectionSet.t()}}
          | {:__inline_fragment__, {on | nil, [Directive.t()], SelectionSet.t()}}

  @spec render_definitions([definition]) :: iolist
  def render_definitions(fragments) do
    unless is_map(fragments) or is_list(fragments) do
      raise "Expected a keyword list or map for fragments, received: #{inspect(fragments)}"
    end

    for {name, definition} <- fragments do
      {on, directives, selection} =
        case definition do
          {on, selection} -> {on, [], selection}
          {on, directives, selection} -> {on, directives, selection}
        end

      [
        "\n\nfragment ",
        Name.valid_name!(name),
        " on ",
        Name.valid_name!(on),
        Directive.render(directives),
        SelectionSet.render(selection, 1)
      ]
    end
  end

  @spec render_spread(Name.t(), [Directive.t()]) :: iolist
  def render_spread(name, directives \\ []) do
    [
      "...",
      Name.valid_name!(name),
      Directive.render(directives)
    ]
  end

  @spec render_inline(Name.t(), [Directive.t()], SelectionSet.t(), integer) :: iolist
  def render_inline(on, directives, selection, indent_level) do
    [
      "...",
      if on do
        [" on ", Name.valid_name!(on)]
      else
        []
      end,
      Directive.render(directives),
      SelectionSet.render(selection, indent_level)
    ]
  end
end
