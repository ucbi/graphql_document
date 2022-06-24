defmodule GraphQLDocument.Fragment do
  @moduledoc """
  > [Fragments](http://spec.graphql.org/October2021/#sec-Language.Fragments)
  > are the primary unit of composition in GraphQL.
  >
  > Fragments allow for the reuse of common repeated selections of fields,
  > reducing duplicated text in the document. Inline Fragments can be used
  > directly within a selection to condition upon a type condition when querying
  > against an interface or union.

  See `render_definitions/1` for details about rendering
  [FragmentDefinitions](http://spec.graphql.org/October2021/#FragmentDefinition).

  See `render/2` for details about rendering a
  [FragmentSpread](http://spec.graphql.org/October2021/#FragmentSpread) or
  [InlineFragment](http://spec.graphql.org/October2021/#sec-Inline-Fragments).
  """
  alias GraphQLDocument.{Directive, Name, Selection}

  @type t :: {:..., spread | inline}

  @typedoc """
  These are given in the `fragments` key of the Operation options. (See
  `t:GraphQLDocument.Operation.option/0`.)

  This is not the _usage_ of the Fragment (in a Selection set) but
  rather defining to be used in the rest of the Document.

  ### Examples

      GraphQLDocument.query(
        [...],
        fragments: [
          friendFields: {
            on(User),
            [
              :id,
              :name,
              profilePic: field(args: [size: 50])
            ]
          }
        ]
      )

  """
  @type definition ::
          {name,
           {type_condition, [Selection.t()]}
           | {type_condition, [Directive.t()], [Selection.t()]}}

  @typedoc """
  The name of a fragment. An atom or string.
  """
  @type name :: Name.t()

  @typedoc """
  The type to which the fragment applies.

  `{:on, Person}` is rendered as `"on Person"`.

  Instead of using `{:on, type}` tuples directly, you can use `GraphQLDocument.on/1`:

      iex> import GraphQLDocument
      iex> on(Person)
      {:on, Person}

  """
  @type type_condition :: {:on, Name.t()}

  @typedoc """
  A fragment spread is injecting `...fragmentName` into a request to instruct
  the server to return the fields in the fragment.

  Fragment spreads are expressed with the `:...` atom to match GraphQL syntax.
  They are often inserted among other fields as in `...: :friendFields` below.

      GraphQLDocument.query(
        [
          self: [
            :name,
            :email,
            ...: :friendFields
          ]
        ],
        fragments: [
          friendFields: {...}
        ]
      )
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
          [Selection.t()]
          | {[Directive.t()], [Selection.t()]}
          | {type_condition, [Selection.t()]}
          | {type_condition, [Directive.t()], [Selection.t()]}

  @doc ~S'''
  Returns a
  [FragmentSpread](http://spec.graphql.org/October2021/#FragmentSpread) or
  [InlineFragment](http://spec.graphql.org/October2021/#sec-Inline-Fragments)
  as an iolist to be inserted in a Document.

  ## Fragment Spreads

  To express a Fragment Spread, provide the name of the fragment as an atom or string.
  If there are directives, provide a `{name, directives}` tuple.

  ### Examples

      iex> render(:friendFields, 1)
      ...> |> IO.iodata_to_binary()
      "...friendFields"

      iex> render({:friendFields, [skip: [if: {:var, :antisocial}]]}, 1)
      ...> |> IO.iodata_to_binary()
      "...friendFields @skip(if: $antisocial)"

  ## Inline Fragments

  To express an Inline Fragment, provide an `{{:on, Type}, selections}` tuple.
  If there are directives, provide `{{:on, Type}, directives, selections}`.

  The `{:on, Type}` syntax can be substituted with `GraphQLDocument.on/1`:

      on(Type)

  ### Examples

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
      ...>   {:on, User},
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
          {{:on, on}, selection} -> {on, [], selection}
          {{:on, on}, directives, selection} -> {on, directives, selection}
        end

      [
        "\n\nfragment ",
        Name.render!(name),
        " on ",
        Name.render!(on),
        Directive.render(directives),
        Selection.render(selection, 1)
      ]
    end
  end

  @spec render_spread(Name.t(), [Directive.t()]) :: iolist
  defp render_spread(name, directives \\ []) do
    [
      "...",
      Name.render!(name),
      Directive.render(directives)
    ]
  end

  @spec render_inline(Name.t() | nil, [Directive.t()], [Selection.t()], integer) :: iolist
  defp render_inline(on, directives, selection, indent_level) when indent_level > 0 do
    [
      "...",
      if on do
        [" on ", Name.render!(on)]
      else
        []
      end,
      Directive.render(directives),
      Selection.render(selection, indent_level)
    ]
  end
end
