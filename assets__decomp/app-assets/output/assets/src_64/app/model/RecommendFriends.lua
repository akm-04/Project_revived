local var_0_0 = class("RecommendFriends", import(".OtherPlayers"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.RECOMMEND_FRIENDS, handler(arg_2_0, arg_2_0.recommendFriendsEvent_))
	arg_2_0:registerEvent(xyd.event.REQUEST_FRIEND, handler(arg_2_0, arg_2_0.requestFriendEvent_))
end

function var_0_0.load(arg_3_0, arg_3_1)
	if arg_3_0.players_ then
		if arg_3_1 then
			arg_3_1(xyd.error.OK)
		end
	else
		xyd.Backend.get():request(xyd.mid.LOAD_RECOMMEND_FRIENDS, {}, function(arg_4_0, arg_4_1, arg_4_2)
			if arg_4_0 == xyd.error.OK and not arg_3_0.players_ then
				arg_3_0:recommendFriendsEvent_({
					name = xyd.event.RECOMMEND_FRIENDS,
					params = arg_4_1,
					userdata = arg_4_2
				})
			end

			if arg_3_1 then
				arg_3_1(arg_4_0)
			end
		end)
	end
end

function var_0_0.recommendFriendsEvent_(arg_5_0, arg_5_1)
	arg_5_0.players_ = {}

	for iter_5_0, iter_5_1 in pairs(arg_5_1.params.list) do
		local var_5_0 = import("app.model.NonFriendPlayer").new()

		var_5_0:populate(iter_5_1)
		table.insert(arg_5_0.players_, var_5_0)
	end
end

function var_0_0.requestFriendEvent_(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.params.player_id

	if arg_6_0:getPlayerByID(var_6_0) then
		arg_6_0:deletePlayer(var_6_0)
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.RECOMMEND_FRIENDS_UPDATE
		})
	end
end

return var_0_0
