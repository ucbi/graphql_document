defmodule GraphQLDocument.Selection do
  @moduledoc """
  A [Selection](http://spec.graphql.org/October2021/#Selection) is
  the list of
  [Fields](http://spec.graphql.org/October2021/#sec-Language.Fields) or
  [Fragments](http://spec.graphql.org/October2021/#sec-Language.Fragments)
  to be returned in an object.
  """

  alias GraphQLDocument.{Field, Fragment}

  @typedoc """
  """
  @type t :: Field.t() | Fragment.spread() | Fragment.inline()

  @doc ~S'''
  Returns the list of selections in
  a [SelectionSet](http://spec.graphql.org/October2021/#SelectionSet) as iodata
  to be inserted into a Document.

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
            Field.render(field, indent_level + 1)
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
