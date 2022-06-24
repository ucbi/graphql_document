defmodule GraphQLDocument.Argument do
  @moduledoc """
  [Arguments](http://spec.graphql.org/October2021/#sec-Language.Arguments)
  are specified in a keyword list.

      [width: 100, height: 50]

  See `render/1` for examples of more complicated argument sets.
  """

  alias GraphQLDocument.{Name, Value}

  @typedoc "A GraphQL argument."
  @type t :: {Name.t(), Value.t()}

  @doc ~S'''
  Returns a list of Arguments as iodata to be inserted into a Document.

  Any valid GraphQL Value can be sent as the value of an Argument.
  (See `t:GraphQLDocument.Value.t/0`.)

  ### Examples

      iex> render(height: 100, width: 50)
      ...> |> IO.iodata_to_binary()
      "(height: 100, width: 50)"

      iex> render(name: "Joshua", city: "Montreal", friendsOfFriends: true)
      ...> |> IO.iodata_to_binary()
      "(name: \"Joshua\", city: \"Montreal\", friendsOfFriends: true)"

      iex> render(%{person: [
      ...>   coordinates: [
      ...>     lat: 123.45,
      ...>     lng: 678.90
      ...>   ]
      ...> ]})
      ...> |> IO.iodata_to_binary()
      "(person: {coordinates: {lat: 123.45, lng: 678.9}})"

      iex> render(coordinates: [
      ...>   lat: {:var, :myLat},
      ...>   lng: {:var, :myLng}
      ...> ])
      ...> |> IO.iodata_to_binary()
      "(coordinates: {lat: $myLat, lng: $myLng})"

      iex> render(ids: [1, 2, 3])
      ...> |> IO.iodata_to_binary()
      "(ids: [1, 2, 3])"

  '''
  @spec render([t]) :: iolist
  def render(args) do
    unless is_map(args) or is_list(args) do
      raise "Expected a keyword list or map for args, received: #{inspect(args)}"
    end

    if Enum.any?(args) do
      [
        ?(,
        args
        |> Enum.map(fn {key, value} ->
          [
            Name.render!(key),
            ?:,
            ?\s,
            Value.render(value)
          ]
        end)
        |> Enum.intersperse(", "),
        ?)
      ]
    else
      []
    end
  end
end
