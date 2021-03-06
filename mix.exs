defmodule Translecto.Mixfile do
    use Mix.Project

    def project do
        [
            app: :translecto,
            description: "A minimal translation library for Ecto",
            version: "0.3.3",
            elixir: "~> 1.3",
            build_embedded: Mix.env == :prod,
            start_permanent: Mix.env == :prod,
            deps: deps(),
            package: package(),
            dialyzer: [plt_add_deps: :transitive]
        ]
    end

    # Configuration for the OTP application
    #
    # Type "mix help compile.app" for more information
    def application do
        [applications: [:logger, :ecto]]
    end

    # Dependencies can be Hex packages:
    #
    #   {:mydep, "~> 0.3.0"}
    #
    # Or git/path repositories:
    #
    #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
    #
    # Type "mix help deps" for more examples and options
    defp deps do
        [
            { :ecto, ">= 2.0.0 and < 4.0.0" },
            { :ecto_sql, "~> 3.0", optional: true },
            { :ex_doc, "~> 0.13", only: :dev },
            { :simple_markdown, "~> 0.5.3", only: :dev, runtime: false },
            { :ex_doc_simple_markdown, "~> 0.3", only: :dev, runtime: false }
        ]
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/Translecto" }
        ]
    end
end
