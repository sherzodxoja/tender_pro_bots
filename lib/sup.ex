defmodule Sup do
	use Supervisor

	
	def init(_) do
		children = []
		supervise(children, strategy: :one_for_one)
	end


end