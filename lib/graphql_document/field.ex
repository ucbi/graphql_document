defmodule GraphQLDocument.Field do
  defstruct [
    :name,
    as: nil,
    args: [],
    directives: [],
    select: []
  ]

  alias __MODULE__
  alias GraphQLDocument.{Argument, Directive, Name, SelectionSet}

  @type t :: %Field{
          as: atom,
          name: atom,
          args: [Argument.t()],
          directives: [Directive.t()]
        }

  def new(name) when is_binary(name) or is_atom(name) do
    struct!(Field, %{
      name: Name.valid_name!(name)
    })
  end

  def new({name, selection}) when is_list(selection) do
    struct!(Field, %{
      name: Name.valid_name!(name),
      select: selection
    })
  end

  def new({name, {args, selection}}) when is_list(args) and is_list(selection) do
    struct!(Field, %{
      name: Name.valid_name!(name),
      args: args,
      select: selection
    })
  end

  def new({name, {:__field__, config}}) do
    config =
      config
      |> Enum.into([])
      |> Keyword.merge(name: name)

    struct!(Field, config)
  end

  def new({as, {:__field__, name, config}}) do
    config =
      config
      |> Enum.into([])
      |> Keyword.merge(name: name, as: as)

    struct!(Field, config)
  end

  def new(field) do
    raise ArgumentError, message: "Expected a field; received #{inspect(field)}"
  end

  def render(field, indent_level) do
    [
      if field_alias = field.as do
        [
          Name.valid_name!(field_alias),
          ?:,
          ?\s
        ]
      else
        []
      end,
      Name.valid_name!(field.name),
      Argument.render(field.args),
      Directive.render(field.directives),
      SelectionSet.render(field.select, indent_level)
    ]
  end
end