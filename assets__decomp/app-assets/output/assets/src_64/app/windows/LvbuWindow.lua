local var_0_0 = class("LvbuWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.model.Hero")
local var_0_5 = 6
local var_0_6 = 5
local var_0_7 = {
	Big = 2,
	End = 3,
	Start = 0,
	Small = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.missions = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:handleTaskResult()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initialTaskItem()
	arg_4_0:addEffectForCurrentTaskItem()
	arg_4_0:updateAvatar()
	arg_4_0:setButtonClick()
	arg_4_0:handleStateChangeEvent()
	arg_4_0:updateAssetShow()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_5_0)
		if arg_4_0 and not tolua.isnull(arg_4_0) then
			arg_4_0:nodeByName("money_txt"):setString(arg_4_0.selfPlayer.lvbuCoin)
			arg_4_0:nodeByName("diamond_txt"):setString(arg_4_0.selfPlayer.crystal)
		end
	end)
	arg_4_0:nodeByName("money_txt"):setString(arg_4_0.selfPlayer.lvbuCoin)
	arg_4_0:nodeByName("diamond_txt"):setString(arg_4_0.selfPlayer.crystal)
end

function var_0_0.initialTaskItem(arg_6_0)
	for iter_6_0 = 0, xyd.tables.activityLvbuCampaign:getCounts() do
		local var_6_0

		if xyd.tables.activityLvbuCampaign:type(iter_6_0) == var_0_7.Start then
			var_6_0 = "windows/lvbu/red.png"
		elseif xyd.tables.activityLvbuCampaign:type(iter_6_0) == var_0_7.Small then
			var_6_0 = "windows/lvbu/gray.png"
		elseif xyd.tables.activityLvbuCampaign:type(iter_6_0) == var_0_7.Big then
			var_6_0 = "windows/lvbu/blue.png"
		elseif xyd.tables.activityLvbuCampaign:type(iter_6_0) == var_0_7.End then
			var_6_0 = "windows/lvbu/yellow.png"
		end

		local var_6_1 = xyd.AssetLoader.get():loadSprite(var_6_0)
		local var_6_2 = var_6_1:getContentSize().width
		local var_6_3 = var_6_1:getContentSize().height

		var_6_1:addTo(arg_6_0:nodeByName("start_pos"))
		var_6_1:setPosition(cc.p(var_6_2 * xyd.tables.activityLvbuCampaign:x(iter_6_0), var_6_3 * xyd.tables.activityLvbuCampaign:y(iter_6_0)))

		arg_6_0.missions[iter_6_0] = var_6_1
	end
end

function var_0_0.addEffectForCurrentTaskItem(arg_7_0)
	if not arg_7_0.lvbuFestival.result then
		arg_7_0:addSelectEffectForItem(arg_7_0.missions[arg_7_0.lvbuFestival.details.campaign_id - 1])
	else
		arg_7_0:addSelectEffectForItem(arg_7_0.missions[arg_7_0.lvbuFestival.details.campaign_id])
	end
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("change_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0.lvbuFestival:playChangeTeam()
		end
	end)
	arg_8_0:nodeByName("buy_walk_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_8_0.selfPlayer.crystal < xyd.tables.misc.lvbuWalkBuy then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_11_0 = {}

					var_11_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
				end, nil, nil, arg_8_0.colorMode)

				return
			else
				local var_10_0 = string.format(var_0_1:translation("SURE_COST_BUY_WALK"), xyd.tables.misc.lvbuWalkBuy)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
					arg_8_0.lvbuFestival:buyWalk({}, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							arg_8_0:updateAssetShow()
						end
					end)
				end, nil, nil, arg_8_0.colorMode)
			end
		end
	end)
	arg_8_0:nodeByName("next_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_8_0.isAnimating then
				return
			end

			if arg_8_0.lvbuFestival.details.walk <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("LVBU_NO_WALK")
				})

				return
			end

			arg_8_0:nextStep()
		end
	end)
	arg_8_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {}

			var_15_0.title_name = "LVBU_CAMPAIGN_RULER_TITLE"
			var_15_0.rule = "LVBU_CAMPAIGN_RULER"

			xyd.WindowManager.get():openWindow("new_text_rule", var_15_0)
		end
	end)
	arg_8_0:nodeByName("walk_time_tips_txt"):setString(var_0_1:translation("LVBU_WALK_RESET_TIME"))
	arg_8_0:nodeByName("walk_time_tips"):setVisible(false)
	arg_8_0:nodeByName("heart"):setTouchEnabled(true)
	arg_8_0:nodeByName("heart"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			arg_8_0:nodeByName("walk_time_tips"):setVisible(true)

			return true
		elseif arg_16_0.name == "ended" then
			arg_8_0:nodeByName("walk_time_tips"):setVisible(false)
		end
	end)
end

function var_0_0.updateAssetShow(arg_17_0)
	if arg_17_0.lvbuFestival.details.walk ~= 0 then
		arg_17_0:nodeByName("heart_txt"):setString(arg_17_0.lvbuFestival.details.walk .. ":" .. xyd.tables.misc.lvbuWalkTotal)
		arg_17_0:nodeByName("heart_txt"):setFontSize(33)
	else
		arg_17_0:nodeByName("heart_txt"):setString(var_0_1:translation("LVBU_NO_HEART"))
		arg_17_0:nodeByName("heart_txt"):setFontSize(26)
	end

	arg_17_0:nodeByName("heart_txt"):enableShadow()
	arg_17_0:nodeByName("progress_bar"):setPercent(100 * arg_17_0.lvbuFestival.details.walk / xyd.tables.misc.lvbuWalkTotal)
	arg_17_0:nodeByName("money_txt"):setString(arg_17_0.selfPlayer.lvbuCoin)

	if arg_17_0.lvbuFestival.details.walk > 0 then
		arg_17_0:nodeByName("buy_walk_container"):setVisible(false)
	else
		arg_17_0:nodeByName("buy_walk_container"):setVisible(true)
	end
end

function var_0_0.nextStep(arg_18_0)
	arg_18_0:nodeByName("next_btn"):setTouchEnabled(false)
	arg_18_0:addSelectEffectForItem(arg_18_0.missions[arg_18_0.lvbuFestival.details.campaign_id])
	var_0_3.performWithDelayGlobal(function()
		arg_18_0:playEvent(arg_18_0.lvbuFestival.details.event_id)
		arg_18_0:nodeByName("next_btn"):setTouchEnabled(true)
	end, 0.7)
end

function var_0_0.playEvent(arg_20_0, arg_20_1)
	local var_20_0 = xyd.tables.activityLvbuEvent:story(arg_20_1)

	if var_20_0 > 0 then
		local var_20_1 = {
			story_id = var_20_0
		}

		xyd.WindowManager.get():openWindow("lvbu_story_talk", var_20_1)
	else
		local var_20_2 = {
			campaign_id = arg_20_0.lvbuFestival.details.campaign_id,
			event_id = arg_20_0.lvbuFestival.details.event_id
		}

		var_20_2.is_succ = 1

		arg_20_0.lvbuFestival:goForward(var_20_2, function(arg_21_0, arg_21_1)
			if arg_21_0 == xyd.error.OK then
				arg_20_0.lvbuFestival.result = var_20_2

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.LVBU_TASK_RESULT
				})
			end
		end)
	end
end

function var_0_0.handleStateChangeEvent(arg_22_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_22_0):addEventListener(xyd.event.LVBU_TASK_RESULT, function(arg_23_0)
		local var_23_0 = xyd.WindowManager.get():getWindow("lvbu_main")

		if var_23_0 and not tolua.isnull(var_23_0) then
			var_23_0:handleTaskResult()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_22_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_24_0)
		if arg_22_0 and not tolua.isnull(arg_22_0) then
			arg_22_0:updateAssetShow()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_22_0):addEventListener(xyd.event.REFRESH_LVBU_ASSETS, function(arg_25_0)
		if arg_22_0 and not tolua.isnull(arg_22_0) then
			arg_22_0:updateAssetShow()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_22_0):addEventListener(xyd.event.LVBU_GROUP_CHANGE, function(arg_26_0)
		if arg_22_0 and not tolua.isnull(arg_22_0) then
			arg_22_0:updateAvatar()
		end
	end)
end

function var_0_0.handleTaskResult(arg_27_0)
	if not arg_27_0.lvbuFestival.result then
		return
	end

	if arg_27_0.lvbuFestival.result.is_succ > 0 then
		if not arg_27_0.lvbuFestival.result.story_id then
			arg_27_0:playSuccess(clone(arg_27_0.lvbuFestival.result))
		else
			local var_27_0 = {
				story_id = arg_27_0.lvbuFestival.result.story_id,
				playing_index = arg_27_0.lvbuFestival.playingIndex
			}

			xyd.WindowManager.get():openWindow("lvbu_story_talk", var_27_0)
		end
	else
		arg_27_0:playFailed(clone(arg_27_0.lvbuFestival.result))
	end

	arg_27_0.lvbuFestival.result = nil

	if arg_27_0.lvbuFestival:isInSecondStage() then
		xyd.WindowManager.get():openWindow("lvbu_door")
		xyd.WindowManager.get():closeWindow(arg_27_0)
	end
end

function var_0_0.playSuccess(arg_28_0, arg_28_1)
	if xyd.tables.activityLvbuEvent:story(arg_28_1.event_id) == 0 then
		if xyd.WindowManager.get():getWindow("toast") then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = xyd.tables.activityLvbuEvent:tip(arg_28_1.event_id)
		})
	end
end

function var_0_0.playFailed(arg_29_0, arg_29_1)
	arg_29_0:addSelectEffectForItem(arg_29_0.missions[arg_29_0.lvbuFestival.details.campaign_id - 1], true)
end

function var_0_0.addSelectEffectForItem(arg_30_0, arg_30_1, arg_30_2)
	if not arg_30_1 or tolua.isnull(arg_30_1) then
		return
	end

	local var_30_0 = "skeletons/ui_effect/zhujue/zhujue.json"
	local var_30_1 = "skeletons/ui_effect/zhujue/zhujue.atlas"

	if not arg_30_0.effect or tolua.isnull(arg_30_0.effect) then
		arg_30_0.effect = var_0_2.new(var_30_0, var_30_1, 1)

		arg_30_0.effect:addTo(arg_30_0:nodeByName("start_pos"))
		arg_30_0.effect:setPosition(arg_30_1:getPosition())
		arg_30_0.effect:setContentSize(0, 1)
	end

	if arg_30_2 then
		transition.stopTarget(arg_30_0.effect)

		local var_30_2, var_30_3 = arg_30_1:getPosition()

		arg_30_0.effect:setAnchorPoint(0, 55)
		arg_30_0.effect:setPosition(arg_30_0.effect:getPositionX(), arg_30_0.effect:getPositionY() + 55)

		local var_30_4
		local var_30_5 = arg_30_0.effect:getPositionX() < arg_30_1:getPositionX() and 360 or -360

		arg_30_0.isAnimating = true

		local var_30_6 = cc.RotateBy:create(0.7, var_30_5)
		local var_30_7 = cc.Sequence:create(cc.EaseSineIn:create(var_30_6))

		arg_30_0.effect:runActionOnce(var_30_7)
		transition.moveTo(arg_30_0.effect, {
			time = 0.7,
			x = var_30_2,
			y = var_30_3 + 55,
			onComplete = function()
				arg_30_0.effect:setAnchorPoint(0, 0)
				arg_30_0.effect:setPosition(arg_30_0.effect:getPositionX(), arg_30_0.effect:getPositionY() - 55)

				arg_30_0.isAnimating = false
			end
		})
	else
		arg_30_0.isAnimating = true

		transition.stopTarget(arg_30_0.effect)

		local var_30_8, var_30_9 = arg_30_1:getPosition()

		transition.moveTo(arg_30_0.effect, {
			time = 0.7,
			x = var_30_8,
			y = var_30_9,
			onComplete = function()
				arg_30_0.isAnimating = false
			end
		})
	end

	arg_30_0.effect:setName("effect")
	arg_30_0.effect:play(nil, true)
end

function var_0_0.updateAvatar(arg_33_0)
	local var_33_0 = arg_33_0:nodeByName("avatar" .. 1):getContentSize()

	for iter_33_0 = 1, #arg_33_0.lvbuFestival.teamHeros do
		local var_33_1 = display.newNode()

		var_33_1:setContentSize(var_33_0.width, var_33_0.height)
		var_33_1:setAnchorPoint(cc.p(0, 0))
		arg_33_0:nodeByName("avatar" .. iter_33_0):removeAllChildren(true)
		xyd.setAvatarBorder(arg_33_0.lvbuFestival.teamHeros[iter_33_0], var_33_1)
		var_33_1:addTo(arg_33_0:nodeByName("avatar" .. iter_33_0))
		arg_33_0:addHeroTips(var_33_1, arg_33_0.lvbuFestival.teamHeros[iter_33_0])
	end
end

function var_0_0.addHeroTips(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {
		id = arg_34_2:getTableID(),
		lev = arg_34_2:getLevel(),
		quality = arg_34_2:getColor(),
		name = arg_34_2:getName(),
		desc = xyd.tables.hero:getDes(arg_34_2:getTableID()),
		hero = arg_34_2
	}

	var_34_0.isHero = true

	local var_34_1, var_34_2 = arg_34_1:getPosition()

	arg_34_1:setTouchEnabled(true)
	arg_34_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
		if arg_35_0.name == "began" then
			local var_35_0 = xyd.WindowManager.get():getWindow("new_item_tips")
			local var_35_1 = arg_34_0:convertToWorldSpace(cc.p(0, 0))

			if not var_35_0 then
				local var_35_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_34_0)

				xyd.adaptToWorldPosition(arg_34_1, var_35_2)
			end

			return true
		elseif arg_35_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
			local var_35_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

return var_0_0
