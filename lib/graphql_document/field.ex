defmodule GraphQLDocument.Field do
  @moduledoc """
  > A [Field](http://spec.graphql.org/October2021/#Field) describes one discrete
  piece of information available to request within a selection set.

  Scalar fields (e.g. Ints, Booleans, and Strings) are requested by their name.

      :name
      :email

  Whereas object fields must be given with child fields as well.

      [
        user: [:name, email]
      ]

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

  See `render/2` for examples of how different Elixir expressions are rendered
  as GraphQL syntax.
  """
  @type t :: Name.t() | {Name.t(), [t]} | {Name.t(), {[Argument.t()], [t]}} | spec

  @typedoc """
  An expression of a field with an alias or directives.
  """
  @type spec ::
          {:field,
           [
             as: atom,
             args: [Argument.t()],
             directives: [Directive.t()],
             select: [Selection.t()]
           ]}

  @typedoc """
           A struct containing all of the aspects of a Field expression.

           Instead of creating `%Field{}` structs manually, use the
           `GraphQLDocument.field/1` function or provide a structure from `t:t/0`.
           """ && false
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

  def new({name, selections}) when is_map(selections) or is_list(selections) do
    struct!(Field, %{
      name: Name.render!(name),
      select: selections
    })
  end

  def new({name, {args, selections}})
      when (is_map(args) or is_list(args)) and (is_map(selections) or is_list(selections)) do
    struct!(Field, %{
      name: Name.render!(name),
      args: args,
      select: selections
    })
  end

  def new({name, {:field, config}}) do
    config =
      config
      |> Enum.into([])
      |> Keyword.merge(name: name)

    struct!(Field, config)
  end

  def new({as, {:field, name, config}}) do
    config =
      config
      |> Enum.into([])
      |> Keyword.merge(name: name, as: as)

    struct!(Field, config)
  end

  def new(field) do
    raise ArgumentError, message: "Expected a field; received #{inspect(field)}"
  end

  @doc ~S'''
  Returns a Field as iodata to be inserted into a Document.

  ### Examples

      iex> render(:email, 1)
      ...> |> IO.iodata_to_binary()
      "email"

      iex> render({:self, [:name, :email]}, 1)
      ...> |> IO.iodata_to_binary()
      """
      self {
        name
        email
      }\
      """

      iex> {:user, {:field,
      ...>   args: [id: 100],
      ...>   select: [:name, :email]
      ...> }}
      ...> |> render(1)
      ...> |> IO.iodata_to_binary()
      """
      user(id: 100) {
        name
        email
      }\
      """

      iex> {:user, {:field,
      ...>   args: [id: 100],
      ...>   directives: [log: [level: "warn"]],
      ...>   select: [:name, :email]
      ...> }}
      ...> |> render(1)
      ...> |> IO.iodata_to_binary()
      """
      user(id: 100) @log(level: "warn") {
        name
        email
      }\
      """

      iex> {:me, {:field,
      ...>   :user,
      ...>   args: [id: 100],
      ...>   directives: [log: [level: "warn"]],
      ...>   select: [:name, :email]
      ...> }}
      ...> |> render(1)
      ...> |> IO.iodata_to_binary()
      """
      me: user(id: 100) @log(level: "warn") {
        name
        email
      }\
      """

  '''
  @spec render(t, pos_integer) :: iolist
  def render(field, indent_level) do
    # immediately coerce the expression into a `%Field{}` struct to standardize rendering below
    field = Field.new(field)

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
