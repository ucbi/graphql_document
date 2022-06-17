# GraphQLDocument

[![Build Status](https://github.com/ucbi/graphql_document/workflows/CI/badge.svg)](https://github.com/ucbi/graphql_document/actions?query=workflow%3A%22CI%22)
[![hex.pm](https://img.shields.io/hexpm/v/graphql_document.svg)](https://hex.pm/packages/graphql_document)
[![hex.pm](https://img.shields.io/hexpm/l/graphql_document.svg)](https://hex.pm/packages/graphql_document)

Build [GraphQL](https://graphql.org/) document strings from Elixir primitives.

## Better DX for internal GraphQL queries

The goal of this package is to improve the developer experience of
making GraphQL calls in Elixir by calling directly into GraphQL libraries such
as [Absinthe](https://hex.pm/packages/absinthe) without making API calls.

For Elixir projects that utilize [LiveView](https://hex.pm/packages/phoenix_live_view)
and GraphQL, passing GraphQL queries as strings, `GraphQLDocument` can add value by
making it easier to:

- Compose separate GraphQL documents together.
- Dynamically build GraphQL documents, e.g. including or excluding various parts.
- Interpolate arguments safely.

## Installation

Add `:graphql_document` as a dependency in `mix.exs`:

```elixir
def deps do
  [
    {:graphql_document, "~> 1.0.0"}
  ]
end
```

## Usage

### With [Absinthe](https://hex.pm/packages/absinthe)

```elixir
[
  query: [
    user: {
      [id: 3],
      [:name, :age, :height, documents: [:filename, :url]]
    }
  ]
]
|> GraphQLDocument.to_string()
|> Absinthe.run(MyProject.Schema)
```

For more information on syntax and features, read the docs in `GraphQLDocument`.

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.
