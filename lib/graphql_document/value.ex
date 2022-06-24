defmodule GraphQLDocument.Value do
  @moduledoc """
  A [Value](http://spec.graphql.org/October2021/#Value) can be any of the
  following Elixir types:

    - number
    - boolean
    - `nil`
    - `String`
    - `List`
    - `Map`
    - `Atom` (an [Enum](http://spec.graphql.org/October2021/#sec-Enum-Value); see `GraphQLDocument.Enum`)
    - `{:var, var}` (to represent a [Variable](http://spec.graphql.org/October2021/#sec-Language.Variables); see `GraphQLDocument.Variable`)

  Values are sent inside Arguments (see `GraphQLDocument.Argument`) or as
  default values in Variable Definitions (see `t:GraphQLDocument.Variable.definition/0`).
  """

  alias GraphQLDocument.{Name, Variable}

  @type t ::
          integer
          | float
          | String.t()
          | boolean
          | nil
          | atom
          | [t]
          | %{optional(atom) => t}
          | Variable.t()

  @doc """
  Returns a Value as iodata to be inserted into a Document.

  Returns native Elixir date and datetime structures as strings in ISO8601 format.

  ### Examples

      iex> render(~D[2019-11-12])
      "\\"2019-11-12\\""

      iex> render(~N[2019-11-12T10:30:25])
      "\\"2019-11-12T10:30:25\\""

      iex> render(DateTime.from_naive!(~N[2019-11-12T10:30:25], "Etc/UTC"))
      "\\"2019-11-12T10:30:25Z\\""

      iex> render(Jedi)
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

  def render({:var, var}) do
    [
      ?$,
      Name.render!(var)
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
            Name.render!(key),
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
    GraphQLDocument.Enum.render(value)
  end
end
