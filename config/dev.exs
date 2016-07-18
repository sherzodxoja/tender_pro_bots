use Mix.Config

# bots_spec is a list of tuples {BotModule, Options} where BotModule is a name of gen_server module, Options is a proplist
config :bots, :bots_spec, [
	{"worker_bot", :active, [{:token, "182601977:AAH3HkVAeHBQfuFH_GrIh_qEKfgPmybhliU"}, {:commander, Bots.Telegram.Commander}]}
	#{"webhook_bot", :passive, [{:token, "182601977:AAH3HkVAeHBQfuFH_GrIh_qEKfgPmybhliU"}, {:commander, Bots.Telegram.Commander}]}
]

config :bots, :webserver, [{:ssl, false}, {:port, 8080}]
