use Mix.Config

# bots_spec is a list of tuples {BotModule, Options} where BotModule is a name of gen_server module, Options is a proplist
config :bots, :bots_spec, [
	{"worker_bot", :active, [{:token, "182601977:AAH3HkVAeHBQfuFH_GrIh_qEKfgPmybhliU"}, {:commander, Bots.Telegram.Commander}]}
	#{"webhook_bot", :passive, [{:token, "182601977:AAH3HkVAeHBQfuFH_GrIh_qEKfgPmybhliU"}, {:commander, Bots.Telegram.Commander}]}
]

config :bots, :webserver, [{:ssl, true}, {:port, 8443}, {:keyfile, "/root/bot/dev/bots/ssl/private.key"}, {:certfile, "/root/bot/dev/bots/ssl/public.crt"}, {:cacertfile, "/root/bot/dev/bots/ssl/gd_bundle-g2-g1.crt"}]
