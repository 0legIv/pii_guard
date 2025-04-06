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
    Analyze the following text and determine if it contains any Personally Identifiable Information (PII).
    PII includes but is not limited to:
    - Full names
    - Social security numbers
    - Credit card numbers
    - Bank account numbers
    - Email addresses
    - Phone numbers
    - Physical addresses
    - Date of birth
    - Driver's license numbers
    - Passport numbers
    - IP addresses
    - Medical records
    - Biometric data

    Respond with ONLY "true" if PII is detected, or "false" if no PII is detected.

    Text to analyze:
    #{text}
    """

    case OpenAI.chat_completion(
           model: "gpt-3.5-turbo",
           messages: [
             %{
               role: "system",
               content:
                 "You are a PII detection assistant. Your only job is to return 'true' or 'false' based on whether the input contains any kind of PII. Be conservative: even informal PII should be flagged as true."
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
