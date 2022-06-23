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

  @doc """
  Given a single value of a variety of types, (see `t:t/0`) returns it as as iodata to be
  inserted into a GraphQL document.

  Returns native Elixir date and datetime structures as strings in ISO8601 format.

  ### Examples

      iex> render(~D[2019-11-12])
      "\\"2019-11-12\\""

      iex> render(~N[2019-11-12T10:30:25])
      "\\"2019-11-12T10:30:25\\""

      iex> render(DateTime.from_naive!(~N[2019-11-12T10:30:25], "Etc/UTC"))
      "\\"2019-11-12T10:30:25Z\\""

      iex> render({:enum, Jedi})
      "Jedi"

      iex> render({:var, :allegiance})
      [?$, "allegiance"]

      iex> render([])
      "[]"

      iex> render("sOmE-sTrInG")
      "\\"sOmE-sTrInG\\""

      iex> render(true)
      "true"

      iex> render(false)
      "false"

      iex> render(%{map: %{with: [nested: ["data"]]}})
      [?{, [["map", ?:, 32, [?{, [["with", ?:, 32, [?{, [["nested", ?:, 32, [?[, ["\\"data\\""], ?]]]], ?}]]], ?}]]], ?}]

      iex> render(%{map: %{with: [nested: ["data"]]}}) |> IO.iodata_to_binary()
      "{map: {with: {nested: [\\"data\\"]}}}"

  """
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
