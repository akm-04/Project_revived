local var_0_0 = class("GetRequestPlayers", import(".OtherPlayers"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.RELOAD, handler(arg_2_0, arg_2_0.reloadEvent_))
end

function var_0_0.load(arg_3_0, arg_3_1)
	if arg_3_0.loaded_ then
		if arg_3_1 then
			arg_3_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_GET_REQUEST_PLAYERS, {}, function(arg_4_0, arg_4_1, arg_4_2)
			if arg_4_0 == xyd.error.OK then
				arg_3_0:getRequestPlayersEvent_({
					name = xyd.event.SEND_REQUEST_PLAYERS,
					params = arg_4_1,
					userdata = arg_4_2
				})

				arg_3_0.loaded_ = true
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end)
	end
end

function var_0_0.getRequestPlayersEvent_(arg_5_0, arg_5_1)
	arg_5_0.players_ = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1.params.list) do
		local var_5_0 = import("app.model.NonFriendPlayer").new()

		var_5_0:populate(iter_5_1)
		table.insert(arg_5_0.players_, var_5_0)
	end
end

function var_0_0.reloadEvent_(arg_6_0, arg_6_1)
	if arg_6_1.params.friend_req == 1 then
		arg_6_0.loaded_ = false
	end
end

function var_0_0.acceptFriendRequest(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.ACCEPT_FRIEND_REQUEST, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:deletePlayer(arg_7_1.player_id)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.GET_REQUEST_PLAYERS_UPDATE
			})
		end
	end)
end

function var_0_0.denyFriendRequest(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.DENY_FRIEND_REQUEST, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			for iter_10_0, iter_10_1 in pairs(arg_9_1.player_ids) do
				arg_9_0:deletePlayer(iter_10_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.GET_REQUEST_PLAYERS_UPDATE
			})
		end
	end)
end

return var_0_0
