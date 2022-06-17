defmodule GraphQLDocumentTest do
  use ExUnit.Case
  doctest GraphQLDocument

  describe "to_string/1" do
    test "builds a GraphQL syntax string from an Elixir data structure" do
      result =
        GraphQLDocument.to_string(
          query: [
            invoices:
              {[customer: "123456"],
               [
                 :id,
                 :total,
                 items: ~w(description amount),
                 payments: {
                   [after: "2021-01-01"],
                   ~w(amount date)
                 }
               ]}
          ]
        )

      expected = """
      query {
        invoices(customer: "123456") {
          id
          total
          items {
            description
            amount
          }
          payments(after: "2021-01-01") {
            amount
            date
          }
        }
      }\
      """

      assert result == expected
    end

    test "it's possible to build a query for a mutation that returns a scalar rather than an object" do
      result =
        GraphQLDocument.to_string(
          mutation: [
            launch_rockets: {[where: "outer space"], []}
          ]
        )

      expected = """
      mutation {
        launch_rockets(where: "outer space")
      }\
      """

      assert result == expected

      result =
        GraphQLDocument.to_string(
          query: [
            getThings: {
              [
                zip: "123",
                test: %{
                  "bar" => "ASDF",
                  "nested" => %{
                    baz: "bazzz"
                  }
                }
              ],
              [:city]
            }
          ]
        )

      expected = """
      query {
        getThings(zip: "123", test: {bar: "ASDF", nested: {baz: "bazzz"}}) {
          city
        }
      }\
      """

      assert result == expected
    end

    test "nested arguments are supported" do
      result =
        GraphQLDocument.to_string(
          mutation: [
            launch_rockets: {
              [when: %{day: "tomorrow", time: [hour: 9, minute: 3, second: 30]}],
              [:status]
            }
          ]
        )

      expected = """
      mutation {
        launch_rockets(when: {day: "tomorrow", time: {hour: 9, minute: 3, second: 30}}) {
          status
        }
      }\
      """

      assert result == expected
    end

    test "empty args" do
      result =
        GraphQLDocument.to_string(
          query: [{"app_stats", {[], [:registrations, :logins, :complaints]}}]
        )

      expected = """
      query {
        app_stats {
          registrations
          logins
          complaints
        }
      }\
      """

      assert result == expected
    end

    test "return values that are an empty list are ignored" do
      result = GraphQLDocument.to_string(mutation: [launch_rockets: {[when: "now"], []}])

      expected = """
      mutation {
        launch_rockets(when: "now")
      }\
      """

      assert result == expected

      result = GraphQLDocument.to_string(mutation: [launch_rockets: {[], []}])

      expected = """
      mutation {
        launch_rockets
      }\
      """

      assert result == expected
    end

    test "pass enum argument as an {:enum, string} tuple" do
      result =
        GraphQLDocument.to_string(
          query: [
            get_rockets: {
              [rocket_type: {:enum, "MASSIVE"}],
              [:status]
            }
          ]
        )

      expected = """
      query {
        get_rockets(rocket_type: MASSIVE) {
          status
        }
      }\
      """

      assert result == expected
    end

    test "query injection is not possible via enums" do
      assert_raise ArgumentError, fn ->
        GraphQLDocument.to_string(
          mutation: [
            createPost: {
              [title: "Test", category: {:enum, "MUSIC) {\n    id\n  } \n  launchRockets(when: NOW"}],
              [:id]
            }
          ]
        )
      end
    end

    test "cannot pass atoms as arguments" do
      assert_raise ArgumentError, fn ->
        GraphQLDocument.to_string(
          query: [
            posts: {
              [category: MUSIC],
              [:id, :title]
            }
          ]
        )
      end
    end

    test "list and object arguments" do
      result =
        GraphQLDocument.to_string(
          query: [
            users: {
              [ids: [1, 2, 3], filters: [status: "active"]],
              [:name]
            }
          ]
        )

      expected = """
      query {
        users(ids: [1, 2, 3], filters: {status: "active"}) {
          name
        }
      }\
      """

      assert result == expected
    end
  end
end
