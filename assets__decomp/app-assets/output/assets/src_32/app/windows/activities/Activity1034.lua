local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.model
local var_0_4 = xyd.tables.activitySpringLogin
local var_0_5 = {
	NOTAWARDED = 3,
	AWARDED = 4,
	FINISHED = 2,
	NOT_OPEN = 1
}
local var_0_6 = {
	NOW_NOT_AWARDED = 2,
	BEFORE = 1,
	NOW_AWARDED = 3,
	AFTER = 4
}
local var_0_7 = 10001053

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	arg_2_0.btns = {}

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:initModel()

	if arg_2_0:checkActivityStatus() == var_0_5.NOTAWARDED then
		arg_2_0:updateByDayNum(arg_2_0:getDayCount() + 1)
	else
		arg_2_0:updateByDayNum(arg_2_0:getDayCount())
	end
end

function var_0_0.initModel(arg_3_0)
	local var_3_0 = xyd.HeroAnimation.new(var_0_7, var_0_7, var_0_3:uiScale(var_0_7), {})
	local var_3_1 = arg_3_0.container:getChildByName("list")

	var_3_0:addTo(var_3_1)

	if var_3_0 then
		var_3_0:idle()
	end

	var_3_0:setPosition(cc.p(320, 140))
	var_3_1:setLocalZOrder(100)
end

function var_0_0.initButtons(arg_4_0)
	local var_4_0 = #var_0_4:all()

	for iter_4_0 = 1, var_4_0 do
		local var_4_1 = arg_4_0.container:getChildByName("list"):getChildByName("bottom_btn")
		local var_4_2 = var_4_1:getChildByName("day_btn_" .. iter_4_0)
		local var_4_3 = var_4_1:getChildByName("lingqu" .. iter_4_0)
		local var_4_4 = var_4_1:getChildByName("yilingqu" .. iter_4_0)

		var_4_2:addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_4_0:updateLeftLayoutAndButtons(iter_4_0)
			end
		end)

		if iter_4_0 <= arg_4_0:getDayCount() then
			var_4_3:setVisible(false)
			var_4_4:setVisible(true)
		else
			var_4_3:setVisible(true)
			var_4_4:setVisible(false)
		end

		table.insert(arg_4_0.btns, var_4_2)
	end

	arg_4_0.container:getChildByName("list"):getChildByName("rule_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("loginrules")
		end
	end)
end

function var_0_0.updateLeftLayoutAndButtons(arg_7_0, arg_7_1)
	local var_7_0 = var_0_4:getGift(arg_7_1)
	local var_7_1 = arg_7_0.container:getChildByName("list"):getChildByName("reward_list")

	var_7_1:getChildByName("reward"):removeAllChildren()

	local var_7_2 = var_0_4:setEffect(arg_7_1)

	arg_7_0:rewardFormat(var_7_1:getChildByName("reward"), var_7_0, activity, nil, var_7_2)

	if arg_7_0:getDayCount() + 1 == arg_7_1 and arg_7_0:checkActivityStatus() == var_0_5.NOTAWARDED then
		arg_7_0:setAwardBtnState(var_0_6.NOW_NOT_AWARDED)
	elseif arg_7_0:getDayCount() == arg_7_1 and arg_7_0:checkActivityStatus() == var_0_5.AWARDED then
		arg_7_0:setAwardBtnState(var_0_6.NOW_AWARDED)
	elseif arg_7_1 <= arg_7_0:getDayCount() then
		arg_7_0:setAwardBtnState(var_0_6.BEFORE)
	elseif arg_7_1 > arg_7_0:getDayCount() then
		arg_7_0:setAwardBtnState(var_0_6.AFTER)
	end

	local var_7_3 = #var_0_4:all()

	for iter_7_0 = 1, var_7_3 do
		if iter_7_0 == arg_7_1 then
			arg_7_0.btns[iter_7_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_7_0.btns[iter_7_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.rewardFormat(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0 = arg_8_1:getContentSize().height
	local var_8_1 = arg_8_4 or var_8_0 / 4
	local var_8_2 = xyd.tables.gift:items(arg_8_2)

	if #var_8_2 == 1 and var_8_2[1] == 0 then
		var_8_2 = {}
	end

	local var_8_3 = xyd.tables.gift:itemNum(arg_8_2)
	local var_8_4 = #var_8_2

	for iter_8_0 = 1, #var_8_2 do
		local var_8_5 = display.newNode()

		var_8_5:setContentSize(var_8_0, var_8_0)

		if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
			xyd.setAvatarBorder(var_8_2[iter_8_0], var_8_5, 1, xyd.tables.hero:initialStar(var_8_2[iter_8_0]))
		else
			xyd.setItemBorder(var_8_5, var_8_2[iter_8_0], false, false, var_8_3[iter_8_0])
		end

		var_8_5:addTo(arg_8_1)
		var_8_5:setAnchorPoint(cc.p(0, 0))
		var_8_5:setPosition((iter_8_0 - 1) * (var_8_0 + var_8_1), 0)

		local var_8_6 = {
			id = var_8_2[iter_8_0],
			lev = xyd.tables.item:level(var_8_2[iter_8_0])
		}

		if xyd.tables.item:type(var_8_2[iter_8_0]) == -1 then
			var_8_6.tipsType = 0
			var_8_6.desc1 = xyd.tables.hero:getDes(var_8_2[iter_8_0])
		else
			var_8_6.tipsType = 1
			var_8_6.desc1 = xyd.tables.item:desc1(var_8_2[iter_8_0])
			var_8_6.desc2 = xyd.tables.item:desc2(var_8_2[iter_8_0])
		end

		if var_8_2[iter_8_0] == arg_8_5 and arg_8_5 ~= 0 then
			arg_8_0:setItemAvatarEffect(var_8_5)
		end

		var_8_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_8_2[iter_8_0])
		var_8_6.name = xyd.tables.item:name(var_8_2[iter_8_0])

		arg_8_0:addTips(var_8_5, var_8_6)
	end

	local var_8_7 = xyd.tables.gift:crystal(arg_8_2)

	if var_8_7 and var_8_7 > 0 then
		local var_8_8 = display.newNode()

		var_8_8:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_8, -1, false, false, var_8_7)
		var_8_8:addTo(arg_8_1)
		var_8_8:setAnchorPoint(cc.p(0, 0))
		var_8_8:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_9 = {}

		var_8_9.id = -1
		var_8_9.tipsType = 1

		arg_8_0:addTips(var_8_8, var_8_9)

		var_8_4 = var_8_4 + 1
	end

	local var_8_10 = xyd.tables.gift:mana(arg_8_2)

	if var_8_10 and var_8_10 > 0 then
		local var_8_11 = display.newNode()

		var_8_11:setContentSize(var_8_0, var_8_0)
		xyd.setItemBorder(var_8_11, -2, false, false, var_8_10)
		var_8_11:addTo(arg_8_1)
		var_8_11:setAnchorPoint(cc.p(0, 0))
		var_8_11:setPosition(var_8_4 * (var_8_0 + var_8_1), 0)

		local var_8_12 = {}

		var_8_12.id = -2
		var_8_12.tipsType = 1

		arg_8_0:addTips(var_8_11, var_8_12)

		local var_8_13 = var_8_4 + 1
	end

	return arg_8_1
end

function var_0_0.setAwardBtnState(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0.container:getChildByName("list")
	local var_9_1 = var_9_0:getChildByName("btn")
	local var_9_2 = var_9_0:getChildByName("lingqu")
	local var_9_3 = var_9_0:getChildByName("yilingqu")
	local var_9_4 = var_9_0:getChildByName("not_begin")
	local var_9_5 = var_9_0:getChildByName("get_gray")

	var_9_1:removeAllChildren()
	var_9_2:setVisible(false)
	var_9_3:setVisible(false)
	var_9_4:setVisible(false)
	var_9_5:setVisible(false)

	if arg_9_1 == var_0_6.BEFORE then
		var_9_1:setBright(false)
		var_9_3:setVisible(true)
	elseif arg_9_1 == var_0_6.NOW_NOT_AWARDED then
		var_9_1:setBright(true)
		var_9_2:setVisible(true)
		var_9_1:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				arg_9_0:getAward(i)
			end
		end)

		local var_9_6 = "skeletons/ui_effect/common_effect_hero12/common_effect_hero12"
		local var_9_7 = var_9_6 .. ".json"
		local var_9_8 = var_9_6 .. ".atlas"

		arg_9_0.Effect = var_0_1.new(var_9_7, var_9_8, 1)

		arg_9_0.Effect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_9_0.Effect:setPosition(var_9_1:getWidth() / 2 + 2, var_9_1:getHeight() / 2)
		arg_9_0.Effect:addTo(var_9_1)
		arg_9_0.Effect:play(nil, true)
	elseif arg_9_1 == var_0_6.NOW_AWARDED then
		var_9_1:setBright(false)
		var_9_3:setVisible(true)
	elseif arg_9_1 == var_0_6.AFTER then
		var_9_1:setBright(false)
		var_9_4:setVisible(true)
	end
end

function var_0_0.getAward(arg_11_0, arg_11_1)
	local var_11_0 = var_0_4:getGift(arg_11_0.activity.details.award_count + 1)

	arg_11_0.activitiesModel:getActivityReward(arg_11_0.activity.table_id, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.selfPlayer:handleRewards(arg_12_1.awards)

			arg_11_0.activity.details.award_count = arg_11_0.activity.details.award_count + 1
			arg_11_0.activity.details.is_awarded = 1
			arg_11_0.activity.details.can_award = 0

			arg_11_0.activitiesModel:clearRedMarkState(arg_11_0.activity.table_id, 2)
			arg_11_0:setAwardBtnState(var_0_6.NOW_AWARDED)
			arg_11_0:updateByDayNum(arg_11_0.activity.details.award_count)
		end
	end)
end

function var_0_0.updateByDayNum(arg_13_0, arg_13_1)
	arg_13_0:initButtons()
	arg_13_0:updateTopLayout()
	arg_13_0:updateLeftLayoutAndButtons(arg_13_1)
end

function var_0_0.updateTopLayout(arg_14_0)
	local var_14_0 = arg_14_0.container:getChildByName("list"):getChildByName("continusTitle")
	local var_14_1 = var_14_0:getChildByName("day_counts")

	var_14_1:removeAllChildren()

	local var_14_2 = xyd.AssetLoader:get():loadSprite("images/text/" .. arg_14_0:getDayCount() .. ".png")

	xyd.displaySpriteOnContainer(var_14_2, var_14_1, false)

	local var_14_3 = transition.sequence({
		cc.ScaleTo:create(0.2, 1.2),
		cc.ScaleTo:create(0.2, 1)
	})
	local var_14_4 = cc.Spawn:create(var_14_3)

	var_14_0:runAction(var_14_4)
end

function var_0_0.setItemAvatarEffect(arg_15_0, arg_15_1)
	local var_15_0 = xyd.tables.activitySpringLogin:setEffect(2)
	local var_15_1 = "skeletons/ui_effect/springLoginEffect/common_effect_summon14"
	local var_15_2 = var_15_1 .. ".json"
	local var_15_3 = var_15_1 .. ".atlas"
	local var_15_4 = var_0_1.new(var_15_2, var_15_3, 1)

	var_15_4:addTo(arg_15_1)
	var_15_4:setLocalZOrder(-100)
	var_15_4:setPosition(arg_15_1:getWidth() / 2, arg_15_1:getHeight() / 2)
	var_15_4:setScale(0.4)
	var_15_4:play(nil, true)
end

function var_0_0.checkActivityStatus(arg_16_0)
	local var_16_0

	open = arg_16_0.activity.is_open

	if is_open == 0 then
		return var_0_5.NOT_OPEN
	elseif xyd.ServerTime.get():getServerTime() >= arg_16_0.activity.end_time then
		return var_0_5.FINISHED
	elseif arg_16_0.activity.details.is_awarded == 0 then
		return var_0_5.NOTAWARDED
	else
		return var_0_5.AWARDED
	end
end

function var_0_0.getDayCount(arg_17_0)
	if arg_17_0:checkActivityStatus() > var_0_5.FINISHED then
		return arg_17_0.activity.details.award_count
	else
		return 0
	end
end

return var_0_0
