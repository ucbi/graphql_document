defmodule GraphqlDocument.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/ucbi/graphql_document"

  def project do
    [
      app: :graphql_document,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: [],

      # Hex
      description: "Build GraphQL document strings from Elixir primitives",
      package: package(),

      # Docs
      name: "GraphqlDocument",
      docs: docs()
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{
        GitHub: @source_url
      }
    }
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end
end
