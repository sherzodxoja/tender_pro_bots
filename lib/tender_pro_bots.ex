defmodule TenderProBots do
	use Application

	def start(_type, _args) do
		Supervisor.start_link(Sup, [], [])
	end
end
