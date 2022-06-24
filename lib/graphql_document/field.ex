defmodule GraphQLDocument.Field do
  defstruct [
    :name,
    as: nil,
    args: [],
    directives: [],
    select: []
  ]

  alias __MODULE__
  alias GraphQLDocument.{Argument, Directive, Name, Selection}

  @type t :: %Field{
          as: atom,
          name: atom,
          args: [Argument.t()],
          directives: [Directive.t()]
        }

  def new(name) when is_binary(name) or is_atom(name) do
    struct!(Field, %{
      name: Name.render!(name)
    })
  end

  def new({name, selections}) when is_list(selections) do
    struct!(Field, %{
      name: Name.render!(name),
      select: selections
    })
  end

  def new({name, {args, selections}}) when is_list(args) and is_list(selections) do
    struct!(Field, %{
      name: Name.render!(name),
      args: args,
      select: selections
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
          Name.render!(field_alias),
          ?:,
          ?\s
        ]
      else
        []
      end,
      Name.render!(field.name),
      Argument.render(field.args),
      Directive.render(field.directives),
      Selection.render(field.select, indent_level)
    ]
  end
end
