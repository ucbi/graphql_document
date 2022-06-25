# GraphQLDocument

[![Build Status](https://github.com/ucbi/graphql_document/workflows/CI/badge.svg)](https://github.com/ucbi/graphql_document/actions?query=workflow%3A%22CI%22)
[![hex.pm](https://img.shields.io/hexpm/v/graphql_document.svg)](https://hex.pm/packages/graphql_document)
[![hex.pm](https://img.shields.io/hexpm/l/graphql_document.svg)](https://hex.pm/packages/graphql_document)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/graphql_document/)

Build [GraphQL](https://graphql.org/) documents from simple Elixir data structures.

## A Power Tool for generating GraphQL Documents in Elixir

The goal of GraphQLDocument is to give the developer superpowers when it comes
to writing GraphQL document strings in Elixir.

Using the functions in this library, developers can:

- Build documents programmatically, enabling higher level tooling and DSLs.
- Compose separate chunks of GraphQL documents together with ease.
- Dynamically build GraphQL documents on the fly. (For example, including or excluding sections.)

The complete documentation for GraphQLDocument is located [here](https://hexdocs.pm/graphql_document/).

## Installation

Add `:graphql_document` as a dependency in `mix.exs`:

```elixir
def deps do
  [
    {:graphql_document, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
query(
  [
    customer: {[id: var(:customerId)], [
      :name,
      :email,
      phoneNumbers: field(args: [type: MOBILE]),
      cartItems: [
        :costPerItem,
        ...: :cartDetails
      ]
    ]}
  ],
  variables: [customerId: Int],
  fragments: [cartDetails: {
    on(CartItem),
    [:sku, :description, :count]
  }]
)
```

```gql
query ($customerId: Int) {
  customer(id: $customerId) {
    name
    email
    phoneNumbers(type: MOBILE)
    cartItems {
      costPerItem
      ...cartDetails
    }
  }
}

fragment cartDetails on CartItem {
  sku
  description
  count
}
```

For more information on syntax and features, [read the docs here](https://hexdocs.pm/graphql_document/).

## License

Copyright 2022 United Community Bank

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.
