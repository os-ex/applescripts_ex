defmodule ApplescriptsEx do
  @moduledoc """
  Documentation for `ApplescriptsEx`.
  """

  alias ApplescriptsEx.Commands

  @spec call(Commands.args(), Commands.cmd()) :: Commands.result()
  defdelegate call(script_key, args), to: Commands

  @doc """
  Check if OS is OSx.
  """
  @spec osx?() :: boolean()
  def osx? do
    :os.type() == {:unix, :darwin}
  end
end
