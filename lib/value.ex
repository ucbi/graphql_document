defmodule GraphQLDocument.Value do
  alias GraphQLDocument.Name

  @typedoc """
  A value in GraphQL can be a number, string, boolean, null, an Enum, or a List or Object.

  See: http://spec.graphql.org/October2021/#Value
  """
  @type t ::
          integer
          | float
          | String.t()
          | boolean
          | nil
          | {:enum, String.t()}
          | [t]
          | %{optional(atom) => t}
          | variable

  @typedoc "A usage of a defined variable within an operation"
  @type variable :: {:var, Name.t()}

  @doc "Render a single value"
  @spec render(t) :: iodata
  def render(%Date{} = date), do: inspect(Date.to_iso8601(date))
  def render(%DateTime{} = date_time), do: inspect(DateTime.to_iso8601(date_time))
  def render(%Time{} = time), do: inspect(Time.to_iso8601(time))

  def render(%NaiveDateTime{} = naive_date_time),
    do: inspect(NaiveDateTime.to_iso8601(naive_date_time))

  if Code.ensure_loaded?(Decimal) do
    def render(%Decimal{} = decimal), do: Decimal.to_string(decimal)
  end

  def render({:enum, enum}) do
    Name.valid_name!(enum)
  end

  def render({:var, var}) do
    [
      ?$,
      Name.valid_name!(var)
    ]
  end

  def render([]), do: "[]"

  def render(enum) when is_list(enum) or is_map(enum) do
    if is_map(enum) || Keyword.keyword?(enum) do
      [
        ?{,
        enum
        |> Enum.map(fn {key, value} ->
          [
            Name.valid_name!(key),
            ?:,
            ?\s,
            render(value)
          ]
        end)
        |> Enum.intersperse(", "),
        ?}
      ]
    else
      [
        ?[,
        enum
        |> Enum.map(&render/1)
        |> Enum.intersperse(", "),
        ?]
      ]
    end
  end

  def render(value) when is_binary(value) do
    inspect(value, printable_limit: :infinity)
  end

  def render(value) when is_number(value) do
    inspect(value, printable_limit: :infinity)
  end

  def render(value) when is_boolean(value) do
    inspect(value)
  end

  def render(value) when is_atom(value) do
    raise ArgumentError,
      message: "[GraphQLDocument] Cannot pass an atom as a value; received `#{value}`"
  end
end
