defmodule PhoenixTsInterface.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_ts_interface,
      version: "1.0.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix, ">= 1.4.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    TS interface for Phoenix APIs
    """
  end

  defp package do
    [
      name: :phoenix_ts_interface,
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      maintainers: ["ziinc"],
      links: %{"GitHub" => "https://github.com/Ziinc/phoenix-ts-interface"}
    ]
  end
end
