defmodule Pidex.MixProject do
  use Mix.Project

  def project do
    [
      app: :pidex,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
    ]
  end

  defp description() do
    "Pure Elixir library for PID controllers (proportional–integral–derivative controller)"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package() do
    [
      files: [
        "lib", "mix.exs", "README*", "LICENSE*"
      ],
      maintainers: ["Jaremy Creechley"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/elcritch/pidex"}
    ]
  end

end
