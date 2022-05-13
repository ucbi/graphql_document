defmodule GraphqlDocumentTest do
  use ExUnit.Case
  doctest GraphqlDocument

  describe "to_string/1" do
    test "builds a GraphQL syntax string from an Elixir data structure" do
      result =
        GraphqlDocument.to_string(
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
        GraphqlDocument.to_string(
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
        GraphqlDocument.to_string(
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
        GraphqlDocument.to_string(
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
        GraphqlDocument.to_string(
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
      result = GraphqlDocument.to_string(mutation: [launch_rockets: {[when: "now"], []}])

      expected = """
      mutation {
        launch_rockets(when: "now")
      }\
      """

      assert result == expected

      result = GraphqlDocument.to_string(mutation: [launch_rockets: {[], []}])

      expected = """
      mutation {
        launch_rockets
      }\
      """

      assert result == expected
    end

    test "pass enum argument as all caps" do
      result =
        GraphqlDocument.to_string(
          query: [
            get_rockets: {
              [rocket_type: MASSIVE],
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

    test "pass enum argument as an {:enum, string} tuple" do
      result =
        GraphqlDocument.to_string(
          query: [
            get_rockets: {
              [rocket_type: {:enum, "massive"}],
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
  end
end
