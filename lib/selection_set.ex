defmodule GraphQLDocument.SelectionSet do
  alias GraphQLDocument.{Argument, Directive, Fragment, Name}

  @typedoc """
  A SelectionSet defines the set of fields in an object to be returned.

  See: http://spec.graphql.org/October2021/#SelectionSet
  """
  @type t :: [field | Fragment.spread() | Fragment.inline()]

  @typedoc """
  A field describes one discrete piece of information available to request within a selection set.

  See: http://spec.graphql.org/October2021/#Field
  """
  @type field :: Name.t() | {Name.t(), [field]} | {Name.t(), {[Argument.t()], t}}

  @spec render(t, integer) :: iolist
  def render(selection, indent_level) when is_list(selection) or is_map(selection) do
    indent = List.duplicate("  ", indent_level)

    rendered =
      Enum.map_join(selection, "\n", fn
        field when is_binary(field) or is_atom(field) ->
          [
            indent,
            Name.valid_name!(field)
          ]

        {:__fragment__, fragment} ->
          {name, directives} =
            case fragment do
              {name, directives} -> {name, directives}
              name -> {name, []}
            end

          [
            indent,
            Fragment.render_spread(name, directives)
          ]

        {:__inline_fragment__, inline_fragment} ->
          {on, directives, selection} =
            case inline_fragment do
              {on, directives, selection} -> {on, directives, selection}
              {on, selection} -> {on, [], selection}
              selection -> {nil, [], selection}
            end

          [
            indent,
            Fragment.render_inline(
              on,
              directives,
              selection,
              indent_level + 1
            )
          ]

        {field, sub_fields} when is_list(sub_fields) ->
          [
            indent,
            Name.valid_name!(field),
            render(sub_fields, indent_level + 1)
          ]

        {field, {args, sub_fields}} ->
          [
            indent,
            Name.valid_name!(field),
            Argument.render(args),
            render(sub_fields, indent_level + 1)
          ]

        {field, {args, directives, sub_fields}}
        when (is_list(args) or is_map(args)) and is_list(directives) and is_list(sub_fields) ->
          [
            indent,
            Name.valid_name!(field),
            Argument.render(args),
            Directive.render(directives),
            render(sub_fields, indent_level + 1)
          ]

        {field_alias, {field, args, sub_fields}}
        when (is_atom(field) and is_map(args)) or is_list(args) ->
          [
            indent,
            Name.valid_name!(field_alias),
            ?:,
            ?\s,
            Name.valid_name!(field),
            Argument.render(args),
            render(sub_fields, indent_level + 1)
          ]

        {field_alias, {field, args, directives, sub_fields}}
        when is_atom(field) and (is_map(args) or is_list(args)) and is_list(directives) ->
          [
            indent,
            Name.valid_name!(field_alias),
            ?:,
            ?\s,
            Name.valid_name!(field),
            Argument.render(args),
            Directive.render(directives),
            render(sub_fields, indent_level + 1)
          ]
      end)

    if Enum.any?(selection) do
      [
        ?\s,
        ?{,
        ?\n,
        rendered,
        ?\n,
        List.duplicate("  ", indent_level - 1),
        ?}
      ]
    else
      []
    end
  end

  def render(selection, _indent_level) do
    raise ArgumentError,
      message: """
      [GraphQLDocument] Expected a list of fields.

      Received: `#{inspect(selection)}`
      Did you forget to enclose it in a list?
      """
  end
end
