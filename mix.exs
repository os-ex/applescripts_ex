defmodule ApplescriptsEx.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :applescripts_ex,
      version: "1.0.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true
      ],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dark_dev, ">= 1.0.3", only: [:dev, :test], runtime: false}
    ]
  end
end
