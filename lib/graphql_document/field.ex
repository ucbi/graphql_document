defmodule GraphQLDocument.Field do
  @moduledoc """
  A [Field](http://spec.graphql.org/October2021/#Field) describes one discrete
  piece of information available to request within a selection set.
  """

  defstruct [
    :name,
    as: nil,
    args: [],
    directives: [],
    select: []
  ]

  alias __MODULE__
  alias GraphQLDocument.{Argument, Directive, Name, Selection}

  @typedoc """
  Fields can be expressed a number of different ways.

  If the field is a scalar type, provide a `String` or `Atom`:

      [:id, :firstName, :lastName]


  If the field is an object type, express it as a keyword list with either
  `[fields]` or `{args, fields}` as the value of each key:

      [
        friends: {[first: 10], [:name]}, # with args
        birthday: [:month, :day], # with sub-fields, but no args
      ]

  See `render/2` for examples of how the different Elixir expressions are
  rendered as GraphQL syntax.
  """
  @type t :: Name.t() | {Name.t(), [t]} | {Name.t(), {[Argument.t()], [t]}} | field_struct

  @typedoc """
  A struct containing all of the aspects of a Field expression.

  If you want to express a field with directives or an alias, you must use
  one of these.

  Instead of creating `%Field{}` structs manually, use the `GraphQLDocument.field/1`
  function.

  See `render/2` for examples of how to use it.
  """
  @type field_struct :: %Field{
          as: atom,
          name: atom,
          args: [Argument.t()],
          directives: [Directive.t()],
          select: [Selection.t()]
        }

  @doc """
  Allows you to specify a complex Field expression with Arguments, Directives,
  Selections, and an Alias.
  """
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

  @doc """
  Returns a Field as iodata to be inserted into a Document.

  ### Examples

      iex> render([])
      ...> |> IO.iodata_to_binary()
      ""

      iex> render_definitions([myInt: Int, debug: Boolean])
      ...> |> IO.iodata_to_binary()
      " ($myInt: Int, $debug: Boolean)"

      iex> render_definitions(lat: Float, lng: Float)
      ...> |> IO.iodata_to_binary()
      " ($lat: Float, $lng: Float)"

  """
  @spec render(t, pos_integer) :: iolist
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
