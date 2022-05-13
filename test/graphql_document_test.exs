defmodule GraphqlDocumentTest do
  use ExUnit.Case
  doctest GraphqlDocument

  test "greets the world" do
    assert GraphqlDocument.hello() == :world
  end
end
