defmodule GraphQLDocument.Argument do
  alias GraphQLDocument.Name

  @typedoc """
  A GraphQL argument.

  See: http://spec.graphql.org/October2021/#Argument
  """
  @type t :: {Name.t(), GraphQLDocument.value()}

  @doc "Render a list of arguments"
  def render_all(args) do
    unless is_map(args) or is_list(args) do
      raise "Expected a keyword list or map for args, received: #{inspect(args)}"
    end

    if Enum.any?(args) do
      args_string =
        Enum.map_join(args, ", ", fn {key, value} ->
          "#{key}: #{render(value)}"
        end)

      "(#{args_string})"
    else
      ""
    end
  end

  @doc "Render a single argument"
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
    "$#{Name.valid_name!(var)}"
  end

  def render({:type, type}) do
    {type, opts} =
      case type do
        {type, opts} -> {type, opts}
        type -> {type, []}
      end

    {type, is_list} =
      case type do
        [type] -> {type, true}
        type -> {type, false}
      end

    required =
      if Keyword.get(opts, :null) == false do
        "!"
      end

    default =
      if default = Keyword.get(opts, :default) do
        " = #{render(default)}"
      end

    type = Name.valid_name!(type)

    rendered_type =
      if is_list do
        "[#{type}]"
      else
        Kernel.to_string(type)
      end

    "#{rendered_type}#{required}#{default}"
  end

  def render([]), do: "[]"

  def render(enum) when is_list(enum) or is_map(enum) do
    if is_map(enum) || Keyword.keyword?(enum) do
      nested_arguments =
        enum
        |> Enum.map_join(", ", fn {key, value} -> "#{key}: #{render(value)}" end)

      "{#{nested_arguments}}"
    else
      nested_arguments =
        enum
        |> Enum.map_join(", ", &"#{render(&1)}")

      "[#{nested_arguments}]"
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
      message: "[GraphQLDocument] Cannot pass an atom as an argument; received `#{value}`"
  end
end
