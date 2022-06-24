defmodule GraphQLDocument.Selection do
  alias GraphQLDocument.{Argument, Field, Fragment, Name}

  @typedoc """
  A [Selection](http://spec.graphql.org/October2021/#Selection) is
  a field or fragment to be returned.
  """
  @type t :: field | Fragment.spread() | Fragment.inline()

  @typedoc """
  A [field](http://spec.graphql.org/October2021/#Field) describes one discrete
  piece of information available to request within a selection set.
  """
  @type field :: Name.t() | {Name.t(), [field]} | {Name.t(), {[Argument.t()], t}}

  @doc ~S'''
  Return a [SelectionSet](http://spec.graphql.org/October2021/#SelectionSet) as
  iodata to be rendered in a GraphQL document.

  ### Examples

      iex> render([lightsaber: [:color, :style]], 1) |> IO.iodata_to_binary()
      """
       {
        lightsaber {
          color
          style
        }
      }\
      """

      iex> render(
      ...>   [
      ...>     invoices: {
      ...>       [customer: "123456"],
      ...>       [
      ...>         :id,
      ...>         :total,
      ...>         items: ~w(description amount),
      ...>         payments: {[after: "2021-01-01", posted: true], ~w(amount date)}
      ...>       ]
      ...>     }
      ...>   ],
      ...>   1
      ...> )
      ...> |> IO.iodata_to_binary()
      """
       {
        invoices(customer: \"123456\") {
          id
          total
          items {
            description
            amount
          }
          payments(after: \"2021-01-01\", posted: true) {
            amount
            date
          }
        }
      }\
      """

      iex> render([foo: :bar], 1)
      ** (ArgumentError) Expected a field; received {:foo, :bar}

      iex> render([foo: [:bar]], 0)
      ** (ArgumentError) indent_level must be at least 1; received 0

  '''
  @spec render([t], integer) :: iolist
  def render(selections, indent_level)
      when (is_list(selections) or is_map(selections)) and indent_level > 0 do
    indent = List.duplicate("  ", indent_level)

    rendered =
      selections
      |> Enum.map(fn
        {:..., fragment} ->
          [
            indent,
            Fragment.render(fragment, indent_level + 1)
          ]

        field ->
          [
            indent,
            field
            |> Field.new()
            |> Field.render(indent_level + 1)
          ]
      end)
      |> Enum.intersperse(?\n)

    if Enum.any?(selections) do
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

  def render(_selection, indent_level) when indent_level < 1 do
    raise ArgumentError,
      message: "indent_level must be at least 1; received #{inspect(indent_level)}"
  end

  def render(selections, _indent_level) do
    raise ArgumentError,
      message: """
      Expected a list of fields.

      Received: `#{inspect(selections)}`
      Did you forget to enclose it in a list?
      """
  end
end
