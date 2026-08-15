local var_0_0 = class("ZhugeOpenTenBoxWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Item")
local var_0_3 = xyd.tables.misc
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items_ = arg_1_2.awards or {}
	arg_1_0.boxType = arg_1_2.boxType
	arg_1_0.summonType = arg_1_2.summonType
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 220), true)
	arg_3_0:showAnimation()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.summonHeroEvent(arg_5_0, arg_5_1)
	if not arg_5_1.item_index then
		return
	end

	if not tolua.isnull(arg_5_0) then
		arg_5_0:showAnimation(arg_5_1.item_index, true)
	end
end

function var_0_0.refresh(arg_6_0, arg_6_1, arg_6_2)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0.tmpNode) do
		iter_6_1:removeSelf()
	end

	arg_6_0.tmpNode = {}
	arg_6_0.items_ = arg_6_1

	arg_6_0:setItems()
	arg_6_0:setInitPosition()

	if #arg_6_1 <= 10 then
		local var_6_0 = transition.sequence({
			cc.ScaleTo:create(0.2, 1.1),
			cc.ScaleTo:create(0.2, 0)
		})

		arg_6_0:nodeByName("main"):runActionOnce(var_6_0, false, function()
			arg_6_0:nodeByName("main"):setScale(1)
			arg_6_0:getBottomContainer():setVisible(false)
			arg_6_0:showAnimation()
		end)
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = arg_8_0.backpack:getItemNumByID(xyd.tables.misc.zhugeBoxPartItem)

	arg_8_0:nodeByName("text_box_num"):setString(string.format(var_0_5:translation("ZHUGE_ADVENTURE_TIPS_17"), var_8_0))

	arg_8_0.tmpNode = {}

	arg_8_0:getAgainBtn()
	arg_8_0:setItems()
	arg_8_0:recordPosition()
	arg_8_0:setInitPosition()
	arg_8_0:getBottomContainer():setVisible(false)
end

function var_0_0.getSummonItem(arg_9_0, arg_9_1)
	return arg_9_0:nodeByName("item" .. arg_9_1)
end

function var_0_0.setItems(arg_10_0)
	arg_10_0:getSummonItem(0):setVisible(false)

	for iter_10_0, iter_10_1 in pairs(arg_10_0.items_) do
		if iter_10_1.is_partner then
			arg_10_0:updateHeroIcon(iter_10_0, iter_10_1)
		else
			arg_10_0:updateItemIcon(iter_10_0, iter_10_1)
		end
	end
end

function var_0_0.updateItemIcon(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = var_0_2.new()
	local var_11_1 = {
		item_id = arg_11_1,
		table_id = arg_11_2.table_id
	}

	var_11_0:populate(var_11_1)

	local var_11_2

	if arg_11_3 then
		var_11_2 = arg_11_3
	else
		var_11_2 = arg_11_0:getSummonItem(arg_11_1)
	end

	var_11_2:removeAllChildren()
	xyd.setItemBorder(var_11_2, arg_11_2.table_id, true)

	if not arg_11_3 then
		local var_11_3 = display.newNode()

		var_11_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_3:setPosition(var_11_2:getPosition())
		var_11_3:setContentSize(var_11_2:getContentSize())
		var_11_3:setLocalZOrder(100)
		var_11_3:addTo(arg_11_0:nodeByName("main"))
		table.insert(arg_11_0.tmpNode, var_11_3)
		arg_11_0:addTips(var_11_3, var_11_1.table_id)
	end

	local var_11_4 = {
		size = 22,
		y = -30,
		text = var_11_0:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_11_2:getContentSize().width / 2
	}
	local var_11_5 = xyd.AssetLoader.get():loadLabel(var_11_4)

	var_11_5:addTo(var_11_2)
	var_11_5:setAnchorPoint(0.5, 0)

	if not arg_11_3 then
		var_11_2:setVisible(false)
	end

	local var_11_6 = {
		size = 22,
		y = 5,
		text = tonumber(arg_11_2.item_num),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_11_2:getContentSize().width - 10
	}

	if arg_11_2.item_num > 1 then
		local var_11_7 = xyd.AssetLoader.get():loadLabel(var_11_6)

		var_11_7:addTo(var_11_2)
		var_11_7:setAnchorPoint(1, 0)
		var_11_7:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	end
end

function var_0_0.addTips(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {
		id = arg_12_2
	}

	xyd.addTips(arg_12_1, var_12_0)
end

function var_0_0.updateHeroIcon(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = clone(arg_13_0.selfPlayer.heros_)
	local var_13_1

	for iter_13_0, iter_13_1 in pairs(var_13_0) do
		if tonumber(arg_13_2.table_id) == iter_13_1:getTableID() then
			var_13_1 = iter_13_1

			table.insert(arg_13_0.heros, var_13_1)

			break
		end
	end

	local var_13_2

	if arg_13_3 then
		var_13_2 = arg_13_3
	else
		var_13_2 = arg_13_0:getSummonItem(arg_13_1)
	end

	var_13_2:removeAllChildren()
	xyd.setAvatarBorder(var_13_1, var_13_2, true)

	if not arg_13_3 then
		local var_13_3 = display.newNode()

		var_13_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_13_3:setPosition(var_13_2:getPosition())
		var_13_3:setContentSize(var_13_2:getContentSize())
		var_13_3:setLocalZOrder(100)
		var_13_3:addTo(arg_13_0:nodeByName("main"))
		table.insert(arg_13_0.tmpNode, var_13_3)
		arg_13_0:addTips(var_13_3, arg_13_2.table_id)
	end

	local var_13_4 = {
		size = 22,
		y = -30,
		text = var_13_1:getName(),
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign = cc.ui.TEXT_VALIGN_TOP,
		x = var_13_2:getContentSize().width / 2
	}
	local var_13_5 = xyd.AssetLoader.get():loadLabel(var_13_4)

	var_13_5:addTo(var_13_2)
	var_13_5:setAnchorPoint(0.5, 0)

	if not arg_13_3 then
		var_13_2:setVisible(false)
	end
end

function var_0_0.getAgainBtn(arg_14_0)
	if not arg_14_0.againBtn_ then
		arg_14_0.againBtn_ = arg_14_0:nodeByName("button_again")

		arg_14_0.againBtn_:addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if not arg_14_0.isAnimated then
					if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_0_3.zhugeBoxPartItem) < 10 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_5:translation("ZHUGE_HOUSE_TIPS_20")
						})

						return
					end

					arg_14_0:summonAgain()
				end
			end
		end)
	end

	return arg_14_0.againBtn_
end

function var_0_0.recordPosition(arg_16_0)
	arg_16_0.position = {}

	for iter_16_0, iter_16_1 in pairs(arg_16_0.items_) do
		local var_16_0, var_16_1 = arg_16_0:getSummonItem(iter_16_0):getPosition()

		arg_16_0.position[iter_16_0] = {
			x = var_16_0,
			y = var_16_1
		}
	end
end

function var_0_0.showAnimation(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0
	local var_17_1
	local var_17_2 = arg_17_1 or 0

	if arg_17_0.position[var_17_2] then
		if var_17_2 == 0 then
			var_17_1 = arg_17_0.items_[1]
		else
			var_17_1 = arg_17_0.items_[var_17_2]
		end

		if var_17_1.is_partner and not arg_17_2 then
			local var_17_3 = {
				toStone = false,
				item_index = var_17_2,
				partnerID = var_17_1.table_id
			}
			local var_17_4 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_17_3)

			cc.EventProxy.new(var_17_4, var_17_4):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_17_0, arg_17_0.summonHeroEvent))

			return
		elseif var_17_1.to_stone and not arg_17_2 then
			local var_17_5 = {
				item_index = var_17_2,
				partnerID = xyd.tables.item:heroID(var_17_1.table_id),
				toStone = tonumber(var_17_1.item_num)
			}
			local var_17_6 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_17_5)

			cc.EventProxy.new(var_17_6, var_17_6):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_17_0, arg_17_0.summonHeroEvent))

			return
		elseif var_17_1.is_pet and not arg_17_2 then
			local var_17_7 = {
				item_index = var_17_2,
				partnerID = xyd.tables.item:heroID(var_17_1.table_id),
				toStone = tonumber(var_17_1.item_num),
				isPet = var_17_1.is_pet
			}
			local var_17_8 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_17_7)

			cc.EventProxy.new(var_17_8, var_17_8):addEventListener(xyd.event.SUMMON_HERO_CLOSE, handler(arg_17_0, arg_17_0.summonHeroEvent))

			return
		end

		local var_17_9 = arg_17_0:getSummonItem(var_17_2)

		var_17_9:setVisible(true)

		local var_17_10 = var_0_3.summonTenDuration
		local var_17_11 = xyd.tables.sound:getSound("draw_item_ten")

		audio.playSound(var_17_11)

		local var_17_12 = cc.Spawn:create(cc.MoveTo:create(var_17_10, cc.p(arg_17_0.position[var_17_2].x, arg_17_0.position[var_17_2].y)), cc.ScaleTo:create(var_17_10, 1), cc.RotateBy:create(var_17_10, 360))

		transition.execute(var_17_9, var_17_12, {
			delay = var_0_3.summonDelay,
			onComplete = function()
				if var_17_2 == #arg_17_0.items_ then
					arg_17_0.isAnimated = false

					arg_17_0:getBottomContainer():setVisible(true)

					return
				end

				var_17_2 = var_17_2 + 1

				arg_17_0:showAnimation(var_17_2)
			end
		})
	elseif var_17_2 < #arg_17_0.items_ then
		var_17_2 = var_17_2 + 1

		arg_17_0:showAnimation(var_17_2)
	end
end

function var_0_0.summonAgain(arg_19_0)
	arg_19_0.zhugeModel:summon(arg_19_0.summonType, 2, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = {
				itemNum = 10,
				itemID = xyd.tables.misc.zhugeBoxPartItem
			}

			arg_19_0.backpack:removeItem(var_20_0)

			if arg_20_1 and arg_20_1.awards then
				for iter_20_0 = 1, #arg_20_1.awards do
					local var_20_1 = arg_20_1.awards[iter_20_0]

					arg_19_0.backpack:addItemsByID(var_20_1.table_id, var_20_1.item_num)
				end
			end

			local var_20_2 = xyd.WindowManager.get():getWindow("zhuge_small_house")

			if var_20_2 and not tolua.isnull(var_20_2) then
				var_20_2:updateCoin()
			end

			local var_20_3 = arg_19_0.backpack:getItemNumByID(xyd.tables.misc.zhugeBoxPartItem)

			arg_19_0:nodeByName("text_box_num"):setString(string.format(var_0_5:translation("ZHUGE_ADVENTURE_TIPS_17"), var_20_3))
			arg_19_0:summonCallback(arg_20_1)
		end
	end)

	arg_19_0.isAnimated = true
end

function var_0_0.summonCallback(arg_21_0, arg_21_1)
	local var_21_0 = {}

	for iter_21_0, iter_21_1 in pairs(arg_21_1.awards) do
		if tonumber(iter_21_0) then
			table.insert(var_21_0, iter_21_1)
		end
	end

	arg_21_0:refresh(var_21_0, arg_21_1)
end

function var_0_0.getBottomContainer(arg_22_0)
	return arg_22_0:nodeByName("bottom_container")
end

function var_0_0.getDesText(arg_23_0)
	return arg_23_0:nodeByName("des")
end

function var_0_0.setInitPosition(arg_24_0)
	local var_24_0, var_24_1 = arg_24_0:getDesText():getPosition()

	for iter_24_0 = 0, 10 do
		arg_24_0:getSummonItem(iter_24_0):setScale(0)
		arg_24_0:getSummonItem(iter_24_0):setPosition(cc.p(var_24_0, var_24_1))
		arg_24_0:getSummonItem(iter_24_0):setVisible(false)
	end
end

return var_0_0
