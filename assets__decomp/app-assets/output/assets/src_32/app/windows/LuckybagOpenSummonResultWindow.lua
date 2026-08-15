local var_0_0 = class("LuckybagOpenSummonResultWindow", import("app.windows.SummonResultWindow"))
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
	arg_6_0:getDesText():setVisible(false)

	local var_6_0, var_6_1, var_6_2, var_6_3 = arg_6_0:getPriceIcon()
	local var_6_4 = xyd.AssetLoader.get():loadSprite("windows/anniversary3rd/lucky_bag/sign_" .. tostring(arg_6_0.bagType) .. ".png")

	var_6_0:setVisible(false)
	var_6_1:setVisible(false)
	var_6_2:setVisible(false)
	var_6_3:setVisible(false)

	local var_6_5, var_6_6 = var_6_3:getPosition()

	var_6_4:addTo(var_6_3:getParent())
	var_6_4:pos(var_6_5, var_6_6)
	var_6_4:setScale(0.6)
	var_6_4:setAnchorPoint(0.5, 0.5)
	arg_6_0:getBottomContainer():setVisible(false)
	arg_6_0:nodeByName("button_hundred"):setVisible(false)
	arg_6_0:nodeByName("price_hundred"):setVisible(false)
	arg_6_0:nodeByName("discount"):setVisible(false)
	arg_6_0:nodeByName("5"):setVisible(false)
	arg_6_0:nodeByName("3"):setVisible(false)

	local var_6_7 = arg_6_0.selfPlayer:getBackpack():getItemNumByID(arg_6_0.keyID) or 0

	arg_6_0:getPriceText():setString(var_6_7)
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

function var_0_0.summonAgain(arg_12_0, arg_12_1)
	local var_12_0 = {
		num = 10,
		idx = arg_12_0.bagType
	}

	arg_12_0.thirdAnni:getLuckybagAward(var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			if arg_13_1 and arg_13_1.awards then
				local var_13_0 = {}

				arg_12_0.selfPlayer:handleRewardsWithoutShow(arg_13_1.awards)

				for iter_13_0, iter_13_1 in pairs(arg_13_1.awards) do
					if tonumber(iter_13_0) then
						table.insert(var_13_0, iter_13_1)
					end
				end

				local var_13_1 = {
					bagType = arg_12_0.bagType,
					items = var_13_0
				}

				var_13_1.lastType = 100
				var_13_1.extraAward = arg_13_1.items

				for iter_13_2, iter_13_3 in pairs(var_13_0) do
					arg_12_0.selfPlayer:heroUpdateEvent_({
						name = xyd.event.HERO_UPDATE,
						params = iter_13_3
					}, true)
				end

				arg_12_0:refresh(var_13_0, arg_13_1)
			end

			local var_13_2 = arg_12_0.selfPlayer:getBackpack()
			local var_13_3 = {
				itemID = arg_12_0.keyID
			}

			var_13_3.itemNum = 10

			var_13_2:removeItem(var_13_3)
		end

		local var_13_4 = arg_12_0.selfPlayer:getBackpack():getItemNumByID(arg_12_0.keyID) or 0

		arg_12_0:getPriceText():setString(var_13_4)

		if var_13_4 <= 10 then
			arg_12_0.againBtn_:setVisible(false)
		end

		local var_13_5 = xyd.WindowManager.get():getWindow("luckybag_wnd")

		if var_13_5 and var_13_5.updateItemTxt then
			var_13_5:updateItemTxt(arg_12_0.bagType)
		end
	end)

	arg_12_0.isAnimated = true

	if arg_12_1 then
		arg_12_0.isAnimated = false
	end
end

function var_0_0.showAnimation(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0.super.showAnimation(arg_14_0, arg_14_1, arg_14_2)
end

function var_0_0.summonHeroEvent(arg_15_0, arg_15_1)
	arg_15_0.super.summonHeroEvent(arg_15_0, arg_15_1)
end

return var_0_0
