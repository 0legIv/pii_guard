defmodule PiiGuard.PiiDetectorTest do
  use ExUnit.Case
  alias PiiGuard.PiiDetector

  describe "contains_pii?/1" do
    test "detects email addresses" do
      assert {:ok, true} = PiiDetector.contains_pii?("My email is user@example.com")
      assert {:ok, true} = PiiDetector.contains_pii?("Contact me at user.name@example.co.uk")
      assert {:ok, false} = PiiDetector.contains_pii?("This is not an email")
    end

    test "detects phone numbers" do
      assert {:ok, true} = PiiDetector.contains_pii?("My phone number is 123-456-7890")
      assert {:ok, true} = PiiDetector.contains_pii?("Call me at (123) 456-7890")
      assert {:ok, true} = PiiDetector.contains_pii?("International: +1-123-456-7890")
      assert {:ok, false} = PiiDetector.contains_pii?("This is not a phone number")
    end

    test "detects social security numbers" do
      assert {:ok, true} = PiiDetector.contains_pii?("My SSN is 123-45-6789")
      assert {:ok, false} = PiiDetector.contains_pii?("This is not an SSN")
    end

    test "detects credit card numbers" do
      assert {:ok, true} = PiiDetector.contains_pii?("My credit card is 4111-1111-1111-1111")
      assert {:ok, true} = PiiDetector.contains_pii?("Card number: 4111111111111111")
      assert {:ok, false} = PiiDetector.contains_pii?("This is not a credit card number")
    end

    test "detects multiple PII types in the same text" do
      text = "My name is John Doe, email is john@example.com, phone is 123-456-7890"
      assert {:ok, true} = PiiDetector.contains_pii?(text)
    end

    test "handles empty strings" do
      assert {:ok, false} = PiiDetector.contains_pii?("")
    end

    test "handles nil input" do
      assert {:error, "Invalid input"} = PiiDetector.contains_pii?(nil)
    end
  end
end
