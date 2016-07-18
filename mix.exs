defmodule TenderProBots.Mixfile do
	use Mix.Project

	def project do 
		[
			app: :tender_pro_bots,
			version: "0.1.0",
			elixir: "~> 1.3",
			build_embedded: Mix.env == :prod,
			start_permanent: Mix.env == :prod,
			deps: deps()
		]
	end

	def application do
		[
			applications: [:logger, :bots],
			mod: {TenderProBots, []}
		]
	end

  
	defp deps do
		[{:bots, git: "https://github.com/TokiTori/bots.git", branch: "master"}]
	end
end
