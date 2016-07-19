defmodule TenderProBots.Commanders.Telegram.Commander do


	def get_response(update) do
		IO.puts "msg: " <> inspect update
		cond do
			update["message"] ->
				message = update["message"]
				splited = String.split(message["text"], " ")
				command = hd(splited)
				args = String.replace_prefix(message["text"], command, "")
				chat_id = message["chat"]["id"]

				response = case command do
					"/hello"->
						{:send_message, %{text: "Hi, " <> message["from"]["first_name"], chat_id: chat_id}}
					"/help"->
						{:send_message, %{text: "Available commands: \n/help\tshow this message\n/hello\tgreetings to you\n/search [-n 10] text", chat_id: chat_id}}
					"/search"->
						search(args)
					"/search3"->
						search_result = search3(args, :new)
						{:send_message, Map.put(search_result, :chat_id, chat_id)}
					"товар"->
						{:send_message, %{text: "not found yet", chat_id: chat_id}}
					c->
						{:send_message, %{text: "Unknown command: #{c}. Use /help and select proper command", chat_id: chat_id}}
				end
			update["inline_query"] ->
				inline_query_id = update["inline_query"]["id"]
				query = update["inline_query"]["query"]
				{results, next_offset} = if query == "" do
					{[], 0}
				else
					offset = try do
						o = update["inline_query"]["offset"]
						case Integer.parse(o) do
							{i, _}->
								i
							_->
								0
						end
					catch
						x->
							0
					end
					search2(query, offset)
				end

				{:ok, results_json} = Poison.encode(results)
				{:inline, %{inline_query_id: inline_query_id, results: results_json, next_offset: next_offset}}
			update["callback_query"] ->
				data = update["callback_query"]["data"]
				message = update["callback_query"]["message"]
				chat_id = message["chat"]["id"]
				message_id = message["message_id"]

				
				splited = String.split(data, " ")
				command = hd(splited)
				args = String.replace_prefix(data, command, "")

				search_result = search3(args)
				response = Map.merge(search_result, %{chat_id: chat_id, message_id: message_id})

				{:edit_text, response}
		end
		
	end

	defp search3(params, type \\ :callback) do
		parsed = parse_search_params(params, String.length(params), 0, "", "", [], :none)

		props = [{:host, '109.120.156.21'}, {:database, 'iac'}, {:user, 'postgres'}, {:password, 'bot867tpro'}]
		con = :pgsql_connection.open(props)

		limit = 3
		limit_from_query = case parsed[:n] do
			:nil when type == :new->
				limit
			:nil->
				30
			value->
				String.to_integer(value)
		end

		
		offset = if parsed[:o], do: String.to_integer(parsed[:o]), else: 0 
		response = :pgsql_connection.extended_query("select * from rest.find_product($1, '{}', '{}', $2, $3) order by 1", 
			[parsed[:text], offset, limit_from_query], con)
		IO.puts "db response: #{inspect response}"

		case response do
			{{:select, 0}, _}->
				%{text: "it's empty"}
			{{:select, count}, list_of_items}->
				d = Enum.map(list_of_items, fn(x)->
					{id, name, _, _} = x
					"/goods_" <> Integer.to_string(id) <> " - " <> name <> "\n"
				end)
				b = cond do
					limit_from_query != limit and type != :new->
						[
							%{text: "collapse", callback_data: "/search3 -o #{0} -n #{limit} #{parsed[:text]}"}
						]
					offset == 0->
						[
							%{text: "expand", callback_data: "/search3 #{parsed[:text]}"},
							%{text: "#{div(offset, limit)+2}>", callback_data: "/search3 -o #{offset+limit} -n #{limit} #{parsed[:text]}"}
						]
					count < limit->
						[
							%{text: "<#{div(offset, limit)}", callback_data: "/search3 -o #{offset-limit} -n #{limit} #{parsed[:text]}"},
							%{text: "expand", callback_data: "/search3 #{parsed[:text]}"}
						]
					true->
						[
							%{text: "<#{div(offset, limit)}", callback_data: "/search3 -o #{offset-limit} -n #{limit} #{parsed[:text]}"},
							%{text: "expand", callback_data: "/search3 #{parsed[:text]}"},
							%{text: "#{div(offset, limit)+2}>", callback_data: "/search3 -o #{offset+limit} -n #{limit} #{parsed[:text]}"}
						]
				end
				{:ok, buttons} = Poison.encode(%{inline_keyboard: [b]})
				%{parse_mode: "HTML", text: Enum.join(d), reply_markup: buttons}
			{:error, error}->
				%{text: "error in backend: #{inspect error}"}
		end
	end


	defp search2(params, offset) do
		limit = 10
		# TODO: throw error when not enought params
		parsed = parse_search_params(params, String.length(params), 0, "", "", [], :none)

		props = [{:host, '109.120.156.21'}, {:database, 'iac'}, {:user, 'postgres'}, {:password, 'bot867tpro'}]
		con = :pgsql_connection.open(props)

		response = :pgsql_connection.extended_query("select * from rest.find_product($1, '{}', '{}', $2, 10)", [parsed[:text], offset], con)
		IO.puts inspect response

		case response do
			#{{:select, 0}, _}->
			#	"it's empty"
			{{:select, _}, list_of_items}->
				d = Enum.map(list_of_items, fn(x)->
					{id, name, _, _} = x
					%{type: "article", id: Integer.to_string(id), title: name, input_message_content: %{message_text: "/search -n 1 л"}}
				end)
				{d, offset+limit}
			{:error, error}->
				"error in backend: " <> inspect error
		end
	end

	defp search(params) do
		# TODO: throw error when not enought params
		parsed = parse_search_params(params, String.length(params), 0, "", "", [], :none)

		props = [{:host, '109.120.156.21'}, {:database, 'iac'}, {:user, 'postgres'}, {:password, 'bot867tpro'}]
		con = :pgsql_connection.open(props)
		limit = if parsed[:n], do: String.to_integer(parsed[:n]), else: 0 
		response = :pgsql_connection.extended_query("select * from rest.find_product($1, '{}', '{}', 0, $2)", [parsed[:text], limit], con)
		IO.puts inspect response

		case response do
			{{:select, 0}, _}->
				"it's empty"
			{{:select, _}, list_of_items}->
				d = Enum.map(list_of_items, fn(x)->
					{id, name, _, _} = x
					"<pre>" <> Integer.to_string(id) <> " - " <> name <> "</pre>\n"
				end)
				{"HTML", Enum.join(d)}
			{:error, error}->
				"error in backend: " <> inspect error
		end
	end

	defp parse_search_params(_, length, position, name, value, values, state) when length == position do
		case state do
			:none->
				values
			_->
				[{String.to_atom(name), value} | values]
		end
	end

	defp parse_search_params(params, length, position, name, value, values, state) do
		case String.at(params, position) do
			"-"->
				parse_search_params(params, length, position+1, "", "", values, :name)
			" "->
				case state do
					:name->
						parse_search_params(params, length, position+1, name, "", values, :value)
					:value->
						parse_search_params(params, length, position+1, "", "", [{String.to_atom(name), value} | values], :none)
					_->
						parse_search_params(params, length, position+1, "", "", values, state)
				end
			char->
				case state do
					:name->
						parse_search_params(params, length, position+1, name <> char, "", values, state)
					:value->
						parse_search_params(params, length, position+1, name , value <> char, values, state)
					_->
						parse_search_params(params, length, position+1, "text" , char, values, :value)
				end
		end
	end
end