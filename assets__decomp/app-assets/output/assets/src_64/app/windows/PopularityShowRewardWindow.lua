local var_0_0 = class("PopularityShowRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tableID = arg_1_2.table_id
	arg_1_0.awards = arg_1_2.awards
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.tables.hero:name(arg_4_0.tableID)
	local var_4_1 = string.format(var_0_1:translation("VOTE_GIFT_REWARDS"), var_4_0)

	arg_4_0:nodeByName("text_desc"):setString(var_4_1)
	arg_4_0:playLightEffect(function()
		arg_4_0.selfPlayer:handleRewards(arg_4_0.awards, function()
			xyd.WindowManager.get():closeWindow("popularity_show_reward")
		end)
	end)
end

function var_0_0.playLightEffect(arg_7_0, arg_7_1)
	local var_7_0 = "skeletons/ui_effect/activity_vote_box/activity_vote_box"
	local var_7_1 = cc.p(arg_7_0:nodeByName("gift_pos"):getPosition())

	arg_7_0.lightEffcet = arg_7_0:createEffect(var_7_0, arg_7_0:nodeByName("container"), var_7_1, 1)

	arg_7_0.lightEffcet:setLocalZOrder(-1)
	arg_7_0.lightEffcet:play(arg_7_1, false)
end

function var_0_0.createEffect(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = arg_8_4 or 1
	local var_8_1 = var_0_2.new(arg_8_1 .. ".json", arg_8_1 .. ".atlas", var_8_0)

	var_8_1:addTo(arg_8_2)
	var_8_1:setPosition(arg_8_3)

	return var_8_1
end

return var_0_0
