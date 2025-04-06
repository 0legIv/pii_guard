defmodule PiiGuard.PiiDetector do
  @moduledoc """
  Module for detecting Personally Identifiable Information (PII) in text using OpenAI.
  """

  require Logger

  @doc """
  Checks if the given text contains PII using OpenAI's API.
  Returns `{:ok, true}` if PII is detected, `{:ok, false}` if no PII is detected,
  or `{:error, reason}` if there was an error checking for PII.
  """
  def contains_pii?(text) when is_binary(text) do
    prompt = """
    You are a PII detection assistant. Analyze the following text and determine if it contains any Personally Identifiable Information (PII).

    Consider these as PII (even if partial or informal):
    - Full names (e.g. John Smith)
    - Email addresses (e.g. user.name@example.co.uk)
    - Phone numbers (e.g. +1-123-456-7890, 0888 123 456)
    - Physical addresses (e.g. General Kolev 83 vh. V)
    - Date of birth
    - ID numbers (EGN, SSN, Passport, Driver's License)
    - Credit card or bank account numbers
    - IP addresses or MAC addresses
    - Biometric or medical information

    Respond ONLY with:
    true — if the text contains any PII
    false — if the text does not contain any PII

    Text to analyze:
    #{text}
    """

    case OpenAI.chat_completion(
           model: "gpt-3.5-turbo",
           messages: [
             %{
               role: "system",
               content:
                 "You are a strict PII classifier. Respond ONLY with `true` or `false`. No explanation."
             },
             %{
               role: "user",
               content: prompt
             }
           ],
           temperature: 0.0,
           max_tokens: 10
         ) do
      {:ok, %{choices: [%{message: %{content: content}} | _]}} ->
        case String.trim(content) do
          "true" -> {:ok, true}
          "false" -> {:ok, false}
          _ -> {:error, "Unexpected response from OpenAI"}
        end

      {:ok, %{choices: [%{"message" => %{"content" => content}} | _]}} ->
        case String.trim(content) do
          "true" -> {:ok, true}
          "false" -> {:ok, false}
          _ -> {:error, "Unexpected response from OpenAI"}
        end

      {:error, error} ->
        Logger.error("OpenAI API error: #{inspect(error)}")
        {:error, "Failed to check for PII"}
    end
  end

  def contains_pii?(_), do: {:error, "Invalid input"}
end
