defmodule GraphQLDocument.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ucbi/graphql_document"

  def project do
    [
      app: :graphql_document,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Build GraphQL document strings from Elixir primitives",
      package: package(),

      # Docs
      name: "GraphQLDocument",
      docs: docs()
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.19.0", only: [:dev, :docs], runtime: false}
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
