local var_0_0 = class("InviteFriends", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.inviteMissions = {}
	arg_1_0.inviteFriends = {}
	arg_1_0.inviteCode = ""
	arg_1_0.invitorId = 0
	arg_1_0.invitorName = ""
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_INVITE_INFOS, handler(arg_2_0, arg_2_0.onLoadInviteInfos_))
	arg_2_0:registerEvent(xyd.event.GET_MISSION_REWARD, handler(arg_2_0, arg_2_0.onGetMissionReward_))
end

function var_0_0.loadInviteInfos(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.LOAD_INVITE_INFOS, {}, function(arg_4_0, arg_4_1)
		if arg_3_1 then
			arg_3_1(arg_4_0)
		end
	end)
end

function var_0_0.getMissionReward(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_INVITE_AWARD, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.onLoadInviteInfos_(arg_7_0, arg_7_1)
	arg_7_0.inviteMissions = arg_7_1.params.missions
	arg_7_0.inviteFriends = arg_7_1.params.invite_players
	arg_7_0.inviteCode = arg_7_1.params.invite_code
	arg_7_0.invitorId = arg_7_1.params.invitor_id
	arg_7_0.invitorName = arg_7_1.params.invitor_name

	arg_7_0:refreshRedMark(arg_7_0.inviteMissions)
end

function var_0_0.refreshRedMark(arg_8_0, arg_8_1)
	local var_8_0 = false

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		if iter_8_1.can_award then
			var_8_0 = true

			break
		end
	end

	arg_8_0.player:setInvite(var_8_0)
end

function var_0_0.isInviteRedMarkShow(arg_9_0)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.inviteMissions) do
		if iter_9_1.can_award then
			return true
		end
	end

	return false
end

function var_0_0.onGetMissionReward_(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1.params.new_infos

	arg_10_0.inviteMissions = var_10_0.missions
	arg_10_0.inviteFriends = var_10_0.invite_players

	arg_10_0:refreshRedMark(arg_10_0.inviteMissions)
end

function var_0_0.getInviteMissions(arg_11_0)
	return arg_11_0.inviteMissions
end

function var_0_0.getInviteFriends(arg_12_0)
	return arg_12_0.inviteFriends
end

function var_0_0.getInviteCode(arg_13_0)
	return arg_13_0.inviteCode
end

function var_0_0.getInvitorID(arg_14_0)
	return arg_14_0.invitorId
end

function var_0_0.getInvitorName(arg_15_0)
	return arg_15_0.invitorName
end

function var_0_0.setInvitorName(arg_16_0, arg_16_1)
	arg_16_0.invitorName = arg_16_1
end

function var_0_0.setInvitorId(arg_17_0, arg_17_1)
	arg_17_0.invitorId = arg_17_1
end

return var_0_0
