local var_0_0 = class("SenvenGoalAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftCode = arg_1_2.giftCode or 0
	arg_1_0.lev = arg_1_2.lev or 0
	arg_1_0.count = arg_1_2.count or 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("goal_title"):setString(xyd.tables.translation:translation("TARGET"))
	arg_3_0:nodeByName("award_title"):setString(xyd.tables.translation:translation("MISSION_TEXT"))
	arg_3_0:nodeByName("condition_desc"):setString(xyd.tables.translation:translation("CORPS_LEV_ACHIEVE"))
	arg_3_0:nodeByName("condition_content"):setString(arg_3_0.lev)
	arg_3_0:nodeByName("condition_desc"):setString(var_0_1:translation("SENVEN_GOAL_TEAM_LEVEL"))
	arg_3_0:nodeByName("goal_title"):setString(var_0_1:translation("PURPOSE"))
	arg_3_0:nodeByName("award_title"):setString(var_0_1:translation("REWARD"))
	arg_3_0:rewardFormat(arg_3_0:nodeByName("reward_container"), arg_3_0.giftCode)

	local var_3_0 = arg_3_0:nodeByName("extra_txt_pos")
	local var_3_1 = {
		size = 24,
		color = cc.c3b(250, 230, 92)
	}
	local var_3_2 = xyd.AssetLoader.get():loadLabel(var_3_1)

	var_3_2:setMaxLineWidth(575)
	var_3_2:setString(xyd.tables.activityLevelUp:desc(arg_3_0.count))
	var_3_2:addTo(arg_3_0:nodeByName("background"))
	var_3_2:setPosition(var_3_0:getPositionX(), var_3_0:getPositionY() - 10)
	var_3_2:setAnchorPoint(cc.p(0, 0.5))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.rewardFormat(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1:getContentSize().height
	local var_5_1 = var_5_0 / 4
	local var_5_2 = xyd.tables.gift:items(arg_5_2)

	if #var_5_2 == 1 and var_5_2[1] == 0 then
		var_5_2 = {}
	end

	local var_5_3 = xyd.tables.gift:itemNum(arg_5_2)
	local var_5_4 = #var_5_2

	for iter_5_0 = 1, #var_5_2 do
		local var_5_5 = display.newNode()

		var_5_5:setContentSize(var_5_0, var_5_0)

		if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
			xyd.setAvatarBorder(var_5_2[iter_5_0], var_5_5, 1, xyd.tables.hero:initialStar(var_5_2[iter_5_0]))
		else
			xyd.setItemBorder(var_5_5, var_5_2[iter_5_0], false, false, var_5_3[iter_5_0])
		end

		var_5_5:addTo(arg_5_1)
		var_5_5:setAnchorPoint(cc.p(0, 0))
		var_5_5:setPosition((iter_5_0 - 1) * (var_5_0 + var_5_1), 0)

		local var_5_6 = {
			id = var_5_2[iter_5_0],
			lev = xyd.tables.item:level(var_5_2[iter_5_0])
		}

		if xyd.tables.item:type(var_5_2[iter_5_0]) == -1 then
			var_5_6.tipsType = 0
			var_5_6.desc1 = xyd.tables.hero:getDes(var_5_2[iter_5_0])
		else
			var_5_6.tipsType = 1
			var_5_6.desc1 = xyd.tables.item:desc1(var_5_2[iter_5_0])
			var_5_6.desc2 = xyd.tables.item:desc2(var_5_2[iter_5_0])
		end

		var_5_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_5_2[iter_5_0])
		var_5_6.name = xyd.tables.item:name(var_5_2[iter_5_0])

		arg_5_0:addTips(var_5_5, var_5_6)
	end

	local var_5_7 = xyd.tables.gift:crystal(arg_5_2)

	if var_5_7 and var_5_7 > 0 then
		local var_5_8 = display.newNode()

		var_5_8:setContentSize(var_5_0, var_5_0)
		xyd.setItemBorder(var_5_8, -1, false, false, var_5_7)
		var_5_8:addTo(arg_5_1)
		var_5_8:setAnchorPoint(cc.p(0, 0))
		var_5_8:setPosition(var_5_4 * (var_5_0 + var_5_1), 0)

		local var_5_9 = {}

		var_5_9.id = -1
		var_5_9.tipsType = 1

		arg_5_0:addTips(var_5_8, var_5_9)

		var_5_4 = var_5_4 + 1
	end

	local var_5_10 = xyd.tables.gift:mana(arg_5_2)

	if var_5_10 and var_5_10 > 0 then
		local var_5_11 = display.newNode()

		var_5_11:setContentSize(var_5_0, var_5_0)
		xyd.setItemBorder(var_5_11, -2, false, false, var_5_10)
		var_5_11:addTo(arg_5_1)
		var_5_11:setAnchorPoint(cc.p(0, 0))
		var_5_11:setPosition(var_5_4 * (var_5_0 + var_5_1), 0)

		local var_5_12 = {}

		var_5_12.id = -2
		var_5_12.tipsType = 1

		arg_5_0:addTips(var_5_11, var_5_12)

		local var_5_13 = var_5_4 + 1
	end

	return arg_5_1
end

return var_0_0
