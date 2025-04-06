defmodule PiiGuardWeb.DataUpdateControllerTest do
  use PiiGuardWeb.ConnCase
  import Mock

  describe "create" do
    test "returns success for valid payload", %{conn: conn} do
      # Create a valid payload
      payload = %{
        "type" => "page_updated",
        "id" => "123",
        "parent" => %{
          "type" => "database",
          "database_id" => "456"
        }
      }

      with_mocks [
        {PiiGuard.DataUpdateHandler, [],
         [
           handle_update: fn payload ->
             if is_map(payload) and Map.has_key?(payload, "type") do
               {:ok, :processed}
             else
               {:error, "Invalid payload"}
             end
           end
         ]}
      ] do
        # Send a POST request to the data update endpoint
        conn = post(conn, ~p"/api/data-updates", payload)
        assert conn.status == 200
      end
    end

    test "returns error for unprocessable entity", %{conn: conn} do
      payload = %{
        "invalid" => "payload"
      }

      with_mocks [
        {PiiGuard.DataUpdateHandler, [],
         [
           handle_update: fn payload ->
             if is_map(payload) and Map.has_key?(payload, "type") do
               {:ok, "Update processed successfully"}
             else
               {:error, "Invalid payload"}
             end
           end
         ]}
      ] do
        # Send a POST request to the data update endpoint
        conn = post(conn, ~p"/api/data-updates", payload)

        assert conn.status == 422

        assert conn.resp_body == "Failed to process update"
      end
    end
  end
end
