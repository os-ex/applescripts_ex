defmodule ApplescriptsEx.Commands do
  @moduledoc """
  Documentation for `ApplescriptsEx.Commands`.
  """

  alias ApplescriptsEx.Validations

  @type cmd() ::
          :send_text_direct
          | :send_text_group
          | :send_attachment_direct
          | :send_attachment_group

  @type args() ::
          Keyword.t()
          | %{to: String.t(), text: String.t()}
          | %{to: String.t(), attachment: String.t()}

  @type error() :: any()
  @type result() :: {:ok, stdout :: String.t()} | {:error, error()}

  @default_dir Path.join(:code.priv_dir(:applescripts_ex), "applescripts/")
  @dir Application.get_env(:applescripts_ex, :applescripts_dir, @default_dir)

  @script_paths %{
    send_text_group: Path.expand(@dir, "SendText.scpt"),
    send_text_direct: Path.expand(@dir, "SendTextSingleBuddy.scpt"),
    send_attachment_group: Path.expand(@dir, "SendImage.scpt"),
    send_attachment_direct: Path.expand(@dir, "SendImageSingleBuddy.scpt")
  }
  @script_keys Map.keys(@script_paths)

  @doc """
  Converts a `chat_id` to a usable imessage representation.

  ## Examples

      iex> imessage_chat("12345")
      "iMessage;+;12345"
  """
  @spec imessage_chat(String.t()) :: String.t()
  def imessage_chat(chat_id) when is_binary(chat_id) do
    "iMessage;+;" <> chat_id
  end

  @doc """
  Dispatches cli commands to compiled applescripts.
  """
  @spec call(args(), cmd()) :: result()
  def call(list, cmd) when is_list(list) do
    list
    |> Enum.into(%{})
    |> call(cmd)
  end

  def call(map, cmd) when is_map(map) do
    with {:ok, args} <- args_for(map, cmd) do
      osascript(args)
    end
  end

  @doc """
  Dispatches cli commands to compiled applescripts.

  ## Examples

      iex> args_for(%{to: "+1-555-555-5555", text: "Hi"}, :send_text_direct)
      {:ok, [:send_text_direct, "Hi", "+1-555-555-5555"]}

      iex> args_for(%{to: "chat12345", text: "Hi"}, :send_text_group)
      {:ok, [:send_text_group, "Hi", "iMessage;+;chat12345"]}

      iex> args_for(%{to: "email@email.com", attachment: "mix.exs"}, :send_attachment_direct)
      {:ok, [:send_attachment_direct, "mix.exs", "email@email.com"]}

      iex> args_for(%{to: "chat12345", attachment: "mix.exs"}, :send_attachment_group)
      {:ok, [:send_attachment_group, "mix.exs", "iMessage;+;chat12345"]}

      iex> args_for(%{to: "", text: "invalid :to"}, :send_text_direct)
      {:error, {:invalid, "", [:tel, :email]}}

      iex> args_for(%{to: "", text: "invalid :to"}, :send_text_group)
      {:error, {:invalid, "", [:chat_id]}}

      iex> args_for(%{to: "email@email.com", attachment: ""}, :send_attachment_direct)
      {:error, {:invalid, "", [:file]}}

      iex> args_for(%{to: "chat12345", attachment: ""}, :send_attachment_group)
      {:error, {:invalid, "", [:file]}}
  """

  @spec args_for(args(), cmd()) :: {:ok, nonempty_list()} | {:error, error()}
  def args_for(%{to: to, text: text}, :send_text_direct) when is_binary(text) and is_binary(to) do
    with :ok <- Validations.validate(to, at_least_one: [:tel, :email]) do
      {:ok, [:send_text_direct, text, to]}
    end
  end

  def args_for(%{to: to, text: text}, :send_text_group) when is_binary(text) and is_binary(to) do
    with :ok <- Validations.validate(to, at_least_one: [:chat_id]) do
      {:ok, [:send_text_group, text, imessage_chat(to)]}
    end
  end

  def args_for(%{to: to, attachment: attachment}, :send_attachment_direct)
      when is_binary(attachment) and is_binary(to) do
    with :ok <- Validations.validate(to, at_least_one: [:tel, :email]),
         :ok <- Validations.validate(attachment, at_least_one: [:file]) do
      {:ok, [:send_attachment_direct, attachment, to]}
    end
  end

  def args_for(%{to: to, attachment: attachment}, :send_attachment_group)
      when is_binary(attachment) and is_binary(to) do
    with :ok <- Validations.validate(to, at_least_one: [:chat_id]),
         :ok <- Validations.validate(attachment, at_least_one: [:file]) do
      {:ok, [:send_attachment_group, attachment, imessage_chat(to)]}
    end
  end

  defp osascript([script_key | args]) when script_key in @script_keys do
    unless ApplescriptsEx.osx?() do
      raise RuntimeError, "OSx required to call `osascript`"
    end

    script_path = Map.get(@script_paths, script_key)

    case System.cmd("osascript", [script_path | args]) do
      {stdout, 0} -> {:ok, stdout}
      {out, descriptor} -> {:error, {script_key, out, descriptor}}
    end
  end
end
