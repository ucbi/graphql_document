defmodule GraphQLDocument.Fragment do
  alias GraphQLDocument.{Directive, Name, SelectionSet}

  @type t :: {:..., spread | inline}

  @typedoc "A definition of a fragment"
  @type definition ::
          {name,
           {type_condition, SelectionSet.t()}
           | {type_condition, [Directive.t()], SelectionSet.t()}}

  @typedoc "The name of a fragment"
  @type name :: Name.t()

  @typedoc "The type to which the fragment applies"
  @type type_condition :: {:on, Name.t()}

  @typedoc """
  A fragment spread is injecting `...fragmentName` into a request to instruct
  the server to return the fields in the fragment.
  """
  @type spread :: {:..., name} | {:..., {name, [Directive.t()]}}

  @typedoc """
  An [inline fragment](http://spec.graphql.org/October2021/#sec-Inline-Fragments)
  is a fragment that doesn't have a definition; the definition appears right in
  the middle of a selection set in the query/mutation/subscription.

  It exists to support requesting certain fields only if the object is a
  certain type (for objects of a union type), or to apply directives to only a
  subset of fields.
  """
  @type inline ::
          SelectionSet.t()
          | {[Directive.t()], SelectionSet.t()}
          | {type_condition, SelectionSet.t()}
          | {type_condition, [Directive.t()], SelectionSet.t()}

  @typedoc "The 'envelope' that fragments are wrapped in: a 2-tuple where the first element is `:...`"
  @type envelope(t) :: {:..., t}

  @doc ~S'''
  Returns the fragment as an iolist ready to be rendered in a GraphQL document.

  ### Examples

      iex> render(:friendFields, 1)
      ...> |> IO.iodata_to_binary()
      "...friendFields"

      iex> render({:friendFields, [skip: [if: {:var, :antisocial}]]}, 1)
      ...> |> IO.iodata_to_binary()
      "...friendFields @skip(if: $antisocial)"

      iex> render(
      ...>   {
      ...>     :friendFields,
      ...>     [include: [if: {:var, :expanded}]]
      ...>   },
      ...>   1
      ...> )
      ...> |> IO.iodata_to_binary()
      "...friendFields @include(if: $expanded)"

      iex> render([:foo, :bar], 1)
      ...> |> IO.iodata_to_binary()
      """
      ... {
        foo
        bar
      }\
      """

      iex> render({[log: [level: "warn"]], [:foo, :bar]}, 1)
      ...> |> IO.iodata_to_binary()
      """
      ... @log(level: "warn") {
        foo
        bar
      }\
      """

      iex> render(
      ...>   {
      ...>     {:on, Person},
      ...>     [:name, friends: [:name, :city]]
      ...>   },
      ...>   1
      ...> )
      ...> |> IO.iodata_to_binary()
      """
      ... on Person {
        name
        friends {
          name
          city
        }
      }\
      """

      iex> render(
      ...>   {
      ...>     {:on, Person},
      ...>     [:log],
      ...>     [:name, friends: [:name, :city]]
      ...>   },
      ...>   1
      ...> )
      ...> |> IO.iodata_to_binary()
      """
      ... on Person @log {
        name
        friends {
          name
          city
        }
      }\
      """

  '''
  @spec render(t, non_neg_integer) :: iolist
  def render(fragment, indent_level) do
    case fragment do
      name when is_binary(name) or is_atom(name) ->
        render_spread(name)

      {name, directives} when (is_binary(name) or is_atom(name)) and is_list(directives) ->
        render_spread(name, directives)

      selection when is_list(selection) ->
        render_inline(nil, [], selection, indent_level)

      {directives, selection} when is_list(directives) and is_list(selection) ->
        render_inline(nil, directives, selection, indent_level)

      {{:on, on}, selection} when (is_atom(on) or is_atom(on)) and is_list(selection) ->
        render_inline(on, [], selection, indent_level)

      {{:on, on}, directives, selection}
      when (is_atom(on) or is_atom(on)) and is_list(directives) and is_list(selection) ->
        render_inline(on, directives, selection, indent_level)
    end
  end

  @doc ~S'''
  Returns the given fragment definitions as iodata to be rendered in a GraphQL document.

  ### Examples

      iex> render_definitions(friendFields: {
      ...>   User,
      ...>   [:id, :name, profilePic: {[size: 50], []}]
      ...> })
      ...> |> IO.iodata_to_binary()
      """
      \n\nfragment friendFields on User {
        id
        name
        profilePic(size: 50)
      }\
      """

  '''
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
  defp render_spread(name, directives \\ []) do
    [
      "...",
      Name.valid_name!(name),
      Directive.render(directives)
    ]
  end

  @spec render_inline(Name.t() | nil, [Directive.t()], SelectionSet.t(), integer) :: iolist
  defp render_inline(on, directives, selection, indent_level) when indent_level > 0 do
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
