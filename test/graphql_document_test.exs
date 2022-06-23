defmodule GraphQLDocumentTest do
  use ExUnit.Case
  doctest GraphQLDocument, import: true

  describe "operation/1" do
    test "builds a GraphQL syntax string from an Elixir data structure" do
      result =
        GraphQLDocument.operation(
          invoices:
            {[customer: "123456"],
             [
               :id,
               :total,
               items: ~w(description amount),
               payments: {
                 [after: "2021-01-01", posted: true],
                 ~w(amount date)
               }
             ]}
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
          payments(after: "2021-01-01", posted: true) {
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
        GraphQLDocument.operation(
          :mutation,
          launch_rockets: {[where: "outer space"], []}
        )

      expected = """
      mutation {
        launch_rockets(where: "outer space")
      }\
      """

      assert result == expected

      result =
        GraphQLDocument.operation(
          :query,
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
        GraphQLDocument.operation(
          :mutation,
          launch_rockets: {
            [when: %{day: "tomorrow", time: [hour: 9, minute: 3, second: 30]}],
            [:status]
          }
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
        GraphQLDocument.operation([{"app_stats", {[], [:registrations, :logins, :complaints]}}])

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
      result = GraphQLDocument.operation(:mutation, launch_rockets: {[when: "now"], []})

      expected = """
      mutation {
        launch_rockets(when: "now")
      }\
      """

      assert result == expected

      result = GraphQLDocument.operation(:mutation, launch_rockets: {[], []})

      expected = """
      mutation {
        launch_rockets
      }\
      """

      assert result == expected
    end

    test "pass enum argument as an {:enum, string} tuple" do
      result =
        GraphQLDocument.operation(
          get_rockets: {
            [rocket_type: {:enum, "MASSIVE"}],
            [:status]
          }
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
        GraphQLDocument.operation(
          :mutation,
          createPost: {
            [
              title: "Test",
              category: {:enum, "MUSIC) {\n    id\n  } \n  launchRockets(when: NOW"}
            ],
            [:id]
          }
        )
      end
    end

    test "cannot pass atoms as arguments" do
      assert_raise ArgumentError, fn ->
        GraphQLDocument.operation(
          :query,
          posts: {
            [category: MUSIC],
            [:id, :title]
          }
        )
      end
    end

    test "list and object arguments" do
      result =
        GraphQLDocument.operation(
          users: {
            [ids: [1, 2, 3], filters: [status: "active"]],
            [:name]
          }
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

    test "field aliases" do
      result =
        GraphQLDocument.operation(
          me: {
            :user,
            [id: 1],
            [:name]
          },
          friend: {
            :user,
            [id: 2],
            [:name]
          }
        )

      expected = """
      query {
        me: user(id: 1) {
          name
        }
        friend: user(id: 2) {
          name
        }
      }\
      """

      assert result == expected
    end

    test "variables" do
      result =
        GraphQLDocument.operation(
          :query,
          [
            me: {
              :user,
              [id: GraphQLDocument.var(:myId)],
              [:name]
            },
            friend: {
              :user,
              [id: {:var, :friendId}, type: {:var, :friendType}],
              [:name]
            }
          ],
          variables: [
            myId: {Int, null: false},
            friendId: Int,
            friendType: {String, default: "best"}
          ]
        )

      expected = """
      query ($myId: Int!, $friendId: Int, $friendType: String = "best") {
        me: user(id: $myId) {
          name
        }
        friend: user(id: $friendId, type: $friendType) {
          name
        }
      }\
      """

      assert result == expected
    end

    test "directives" do
      result =
        GraphQLDocument.operation(
          :query,
          [experimentalField: {[], [skip: [if: {:var, :someTest}]], []}],
          variables: [someTest: {Boolean, null: false}]
        )

      expected = """
      query ($someTest: Boolean!) {
        experimentalField @skip(if: $someTest)
      }\
      """

      assert result == expected
    end
  end
end
