defmodule PiiGuardWeb.HealthControllerTest do
  use PiiGuardWeb.ConnCase

  describe "check" do
    test "returns health status as JSON", %{conn: conn} do
      conn = get(conn, ~p"/api/health")

      # Check that the response status is 200
      assert conn.status == 200
      # Parse the response body
      response = Jason.decode!(conn.resp_body)

      # Check that the response has the expected structure
      assert is_map(response)
      assert Map.has_key?(response, "status")
      assert Map.has_key?(response, "components")
      assert Map.has_key?(response, "timestamp")

      # Check that the status is either "ok" or "error"
      assert response["status"] in ["ok", "error"]

      # Check that the components map has the expected keys
      assert Map.has_key?(response["components"], "notion_api")
      assert Map.has_key?(response["components"], "slack_api")

      # Check that the notion_api component has the expected structure
      assert Map.has_key?(response["components"]["notion_api"], "status")
      assert Map.has_key?(response["components"]["notion_api"], "message")
      assert response["components"]["notion_api"]["status"] in ["ok", "error"]

      # Check that the slack_api component has the expected structure
      assert Map.has_key?(response["components"]["slack_api"], "status")
      assert Map.has_key?(response["components"]["slack_api"], "message")
      assert response["components"]["slack_api"]["status"] in ["ok", "error"]

      # Check that the timestamp is a string
      assert is_binary(response["timestamp"])
    end
  end
end
