defmodule ApplescriptsEx.Validations do
  @moduledoc """
  Validations for `ApplescriptsEx`.
  """

  @type validator() :: :file | :chat_id | :email | :tel
  @type error_msg() :: {:invalid, any(), [validator()]}
  @type error() :: {:error, error_msg()}
  @type result() :: :ok | error()

  @type opt() :: {:at_least_one, any()}
  @type opts() :: [opt(), ...]

  @validators [:file, :chat_id, :email, :tel]

  @doc """
  Validation aggregates.

  ## Examples

      iex> validate("mix.exs", at_least_one: [:file])
      :ok

      iex> validate("email@email.com", at_least_one: [:email, :tel])
      :ok

      iex> validate("email@email.com", at_least_one: [:file, :tel])
      {:error, {:invalid, "email@email.com", [:file, :tel]}}
  """
  @spec validate(any(), opts()) :: result()
  def validate(value, at_least_one: types) do
    if Enum.any?(types, &valid?(value, &1)) do
      :ok
    else
      {:error, {:invalid, value, types}}
    end
  end

  @doc """
  Individual validators.

  ## Examples

      iex> valid?("mix.exs", :file)
      true

      iex> valid?("chat1234", :chat_id)
      true

      iex> valid?("email@email.com", :email)
      true

      iex> valid?("555-555-5555", :tel)
      true

      iex> valid?("missing_file", :file)
      false

      iex> valid?("invalid", :chat_id)
      false

      iex> valid?("invalid", :email)
      false

      iex> valid?("invalid", :tel)
      false
  """
  @spec valid?(any(), validator()) :: boolean()
  def valid?(file, :file) when is_binary(file) do
    File.exists?(file)
  end

  def valid?(recipient, :chat_id) when is_binary(recipient) do
    String.match?(recipient, ~r/^chat[0-9]+$/)
  end

  def valid?(recipient, :email) when is_binary(recipient) do
    String.match?(recipient, ~r/@/)
  end

  def valid?(recipient, :tel) when is_binary(recipient) do
    String.match?(recipient, ~r/[\+0-9]/)
  end

  def valid?(_, validator) when validator in @validators do
    false
  end
end
