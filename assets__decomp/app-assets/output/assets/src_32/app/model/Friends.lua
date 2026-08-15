local var_0_0 = class("Friends", import(".OtherPlayers"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.ACCEPT_FRIEND_REQUEST, handler(arg_2_0, arg_2_0.acceptFriendEvent_))
	arg_2_0:registerEvent(xyd.event.RELOAD, handler(arg_2_0, arg_2_0.reloadEvent_))
end

function var_0_0.load(arg_3_0, arg_3_1)
	if arg_3_0.loaded_ then
		if arg_3_1 then
			arg_3_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_FRIENDS, {}, function(arg_4_0, arg_4_1, arg_4_2)
			if arg_4_0 == xyd.error.OK then
				arg_3_0:friendsEvent_({
					name = xyd.event.FRIENDS,
					params = arg_4_1,
					userdata = arg_4_2
				})

				arg_3_0.loaded_ = true
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1, arg_4_2)
			end
		end)
	end
end

function var_0_0.friendsEvent_(arg_5_0, arg_5_1)
	arg_5_0.maxFriendNumLimit_ = tonumber(arg_5_1.params.count)
	arg_5_0.players_ = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1.params.list) do
		local var_5_0 = import("app.model.FriendPlayer").new()

		var_5_0:populate(iter_5_1)
		table.insert(arg_5_0.players_, var_5_0)
	end
end

function var_0_0.acceptFriendEvent_(arg_6_0, arg_6_1)
	local var_6_0 = import("app.model.FriendPlayer").new()

	var_6_0:populate(arg_6_1.params)
	table.insert(arg_6_0.players_, var_6_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.FRIENDS_UPDATE
	})
end

function var_0_0.reloadEvent_(arg_7_0, arg_7_1)
	if arg_7_1.params.friend_list == 1 then
		arg_7_0.loaded_ = false
	end
end

function var_0_0.sendSocial(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.SEND_SOCIAL, arg_8_1, function(arg_9_0, arg_9_1, arg_9_2)
		if arg_9_0 == xyd.error.OK then
			arg_8_0:getPlayerByID(arg_8_1.player_id).socialTime_ = xyd.ServerTime.get():getServerTime()

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.FRIENDS_UPDATE
			})

			if arg_8_2 then
				arg_8_2(arg_9_0, arg_9_1, arg_9_2)
			end
		end
	end, {}, false, true)
end

function var_0_0.deleteFriend(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.DELETE_FRIEND, arg_10_1, function(arg_11_0, arg_11_1, arg_11_2)
		if arg_11_0 == xyd.error.OK then
			arg_10_0:deletePlayer(arg_10_1.player_id)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.FRIENDS_UPDATE
			})

			if arg_10_2 then
				arg_10_2(arg_11_0, arg_11_1, arg_11_2)
			end
		end
	end)
end

return var_0_0
