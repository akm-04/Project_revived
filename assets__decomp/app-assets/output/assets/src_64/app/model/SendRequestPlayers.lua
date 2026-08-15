local var_0_0 = class("SendRequestPlayers", import(".OtherPlayers"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.SEND_REQUEST_PLAYERS, handler(arg_2_0, arg_2_0.sendRequestPlayersEvent_))
end

function var_0_0.load(arg_3_0, arg_3_1)
	if arg_3_0.players_ then
		if arg_3_1 then
			arg_3_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_SEND_REQUEST_PLAYERS, {}, function(arg_4_0, arg_4_1, arg_4_2)
			if arg_4_0 == xyd.error.OK and not arg_3_0.players_ then
				arg_3_0:sendRequestPlayersEvent_({
					name = xyd.event.SEND_REQUEST_PLAYERS,
					params = arg_4_1,
					userdata = arg_4_2
				})
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end)
	end
end

function var_0_0.sendRequestPlayersEvent_(arg_5_0, arg_5_1)
	arg_5_0.players_ = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1.params.list) do
		local var_5_0 = import("app.model.NonFriendPlayer").new()

		var_5_0:populate(iter_5_1)
		table.insert(arg_5_0.players_, var_5_0)
	end
end

function var_0_0.requestFriend(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.REQUEST_FRIEND, arg_6_1, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			local var_7_0 = import("app.model.NonFriendPlayer").new()

			var_7_0:populate(arg_7_1)
			table.insert(arg_6_0.players_, var_7_0)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SEND_REQUEST_PLAYERS_UPDATE
			})
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.cancelFriendRequest(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.CANCEL_REQUEST_FRIEND, arg_8_1, function(arg_9_0)
		if arg_9_0 == xyd.error.OK then
			local var_9_0 = arg_8_1.player_id

			arg_8_0:deletePlayer(var_9_0)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SEND_REQUEST_PLAYERS_UPDATE
			})
		end

		if arg_8_2 then
			arg_8_2(arg_9_0, response)
		end
	end)
end

return var_0_0
