local var_0_0 = class("ActivityGirlsTreasureAwardShowWindow", import("app.windows.SummonResultWindow"))
local var_0_1 = xyd.WindowName.summonWnd
local var_0_2 = xyd.WindowName.summonResultWnd
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.translation
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = import("app.model.Hero")
local var_0_7 = import("app.model.Pet")
local var_0_8 = import("framework.scheduler")
local var_0_9 = 150

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.bagType = arg_1_2.bagType
	arg_1_0.useNum = arg_1_2.useNum
	arg_1_0.times = arg_1_2.times
	arg_1_0.thirdAnni = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.keyID = xyd.tables.AnniLuckybagTable:key(arg_1_0.bagType)
end

function var_0_0.refresh(arg_2_0, arg_2_1, arg_2_2)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0.tmpNode) do
		iter_2_1:removeSelf()
	end

	arg_2_0.tmpNode = {}

	if #arg_2_1 > 10 then
		local var_2_0 = transition.sequence({
			cc.ScaleTo:create(0.2, 1.1),
			cc.ScaleTo:create(0.2, 0)
		})

		arg_2_0.isAnimated = true

		arg_2_0:nodeByName("main"):runActionOnce(var_2_0, false, function()
			arg_2_0:nodeByName("main"):setScale(1)
			arg_2_0:nodeByName("list"):setVisible(true)

			arg_2_0.items_ = {}

			local var_3_0 = {}

			for iter_3_0, iter_3_1 in pairs(arg_2_1) do
				if var_3_0[iter_3_1.table_id] then
					var_3_0[iter_3_1.table_id].item_num = iter_3_1.item_num + var_3_0[iter_3_1.table_id].item_num
				else
					var_3_0[iter_3_1.table_id] = {}
					var_3_0[iter_3_1.table_id] = iter_3_1
				end
			end

			local var_3_1 = 1

			for iter_3_2, iter_3_3 in pairs(var_3_0) do
				arg_2_0.items_[var_3_1] = {}
				arg_2_0.items_[var_3_1] = iter_3_3
				var_3_1 = var_3_1 + 1
			end

			arg_2_0.listItems_ = arg_2_0.items_

			arg_2_0:setItems(true)

			arg_2_0.isAnimated = false
		end)
	else
		arg_2_0.scrollViewMoved_ = false

		arg_2_0:nodeByName("list"):setVisible(false)

		arg_2_0.listItems_ = {}
		arg_2_0.items_ = arg_2_1

		arg_2_0:setItems()
	end

	arg_2_0:setInitPosition()

	if #arg_2_1 <= 10 then
		local var_2_1 = transition.sequence({
			cc.ScaleTo:create(0.2, 1.1),
			cc.ScaleTo:create(0.2, 0)
		})

		arg_2_0:nodeByName("main"):runActionOnce(var_2_1, false, function()
			arg_2_0:nodeByName("main"):setScale(1)
			arg_2_0:getBottomContainer():setVisible(false)

			if arg_2_2.items and next(arg_2_2.items) then
				local var_4_0 = {}

				for iter_4_0, iter_4_1 in ipairs(arg_2_2.items) do
					for iter_4_2 = 1, iter_4_1.item_num do
						local var_4_1 = Item.new()

						var_4_1:populate({
							table_id = iter_4_1.item_id
						})
						table.insert(var_4_0, var_4_1)
					end

					arg_2_0.selfPlayer:getBackpack():addItemsByID(iter_4_1.item_id, iter_4_1.item_num)
				end

				local var_4_2 = var_0_4:translation("CHRISTMAS_SUMMON_AWARD_TEXT1")
				local var_4_3 = var_0_4:translation("CHRISTMAS_SUMMON_AWARD_TEXT2")
				local var_4_4 = var_0_4:translation("CHRISTMAS_SUMMON_AWARD_TEXT3")
				local var_4_5 = {
					var_4_2,
					var_4_3,
					var_4_4
				}
				local var_4_6 = xyd.WindowManager.get():openWindow("battle_award_items", {
					items = var_4_0,
					labels = var_4_5
				})

				cc.EventProxy.new(var_4_6, var_4_6):addEventListener(xyd.event.ALERT_AWARD_CLOSE, function()
					arg_2_0:showAnimation()
				end)
			else
				arg_2_0:showAnimation()
			end
		end)
	else
		arg_2_0:checkShowExtraReward()
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0.tmpNode = {}

	arg_6_0:getBackAnimation()
	arg_6_0:getAgainBtn()
	arg_6_0:getSkipBtn()
	arg_6_0:getCloseBtn()
	arg_6_0:setItems()
	arg_6_0:recordPosition()
	arg_6_0:setInitPosition()

	local var_6_0 = var_0_4:translation("ACTIVITY_CHOCOLATE_NUM" .. arg_6_0.times)
	local var_6_1 = string.format(var_0_4:translation("ACTIVITY_GIRLS_TREASURE_TEXT_15"), var_6_0)

	arg_6_0:getDesText():setString(var_6_1)

	local var_6_2, var_6_3, var_6_4, var_6_5 = arg_6_0:getPriceIcon()

	var_6_2:setVisible(false)
	var_6_3:setVisible(false)
	var_6_4:setVisible(false)
	var_6_5:setVisible(false)
	arg_6_0:nodeByName("price"):setVisible(false)
	arg_6_0:getBottomContainer():setVisible(false)
	arg_6_0:nodeByName("button_hundred"):setVisible(false)
	arg_6_0:nodeByName("price_hundred"):setVisible(false)
	arg_6_0:nodeByName("discount"):setVisible(false)
	arg_6_0:nodeByName("5"):setVisible(false)
	arg_6_0:nodeByName("3"):setVisible(false)

	local var_6_6 = arg_6_0.selfPlayer:getBackpack():getItemNumByID(arg_6_0.keyID) or 0

	arg_6_0:getPriceText():setString(var_6_6)
	arg_6_0:nodeByName("return"):setPosition(arg_6_0:nodeByName("button_again"):getPosition())
end

function var_0_0.getAgainBtn(arg_7_0)
	if not arg_7_0.againBtn_ then
		arg_7_0.againBtn_ = arg_7_0:nodeByName("button_again")

		local var_7_0 = arg_7_0.useNum
		local var_7_1 = arg_7_0.selfPlayer:getBackpack():getItemNumByID(arg_7_0.keyID) or 0

		if var_7_0 == 10 and var_7_1 >= 10 then
			arg_7_0.againBtn_:getChildByName("txt"):setString(var_0_4:translation("SUMMON_BUY_AGAIN10"))
			xyd.nodeEventSample(arg_7_0.againBtn_, nil, function(arg_8_0)
				xyd.playButtonSound()

				if not arg_7_0.isAnimated then
					arg_7_0:summonAgain()
				end
			end)
		else
			arg_7_0.againBtn_:setVisible(false)
		end
	end

	return arg_7_0.againBtn_
end

function var_0_0.setSkipBtnVisible(arg_9_0, arg_9_1)
	if not arg_9_0 or not arg_9_0.skipBtn_ or tolua.isnull(arg_9_0.skipBtn_) then
		return
	end

	if not arg_9_0:isCanSkipType() or arg_9_0.isSkipAnimation then
		arg_9_0.skipBtn_:setVisible(false)

		return
	end

	arg_9_0.skipBtn_:setVisible(false)
end

function var_0_0.checkShowExtraReward(arg_10_0)
	return
end

function var_0_0.updateItemIcon(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	arg_11_0.super.updateItemIcon(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
end

function var_0_0.showAnimation(arg_12_0, arg_12_1, arg_12_2)
	arg_12_0.super.showAnimation(arg_12_0, arg_12_1, arg_12_2)
end

function var_0_0.summonHeroEvent(arg_13_0, arg_13_1)
	arg_13_0.super.summonHeroEvent(arg_13_0, arg_13_1)
end

return var_0_0
