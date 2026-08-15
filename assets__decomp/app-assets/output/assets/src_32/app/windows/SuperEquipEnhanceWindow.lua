local var_0_0 = class("SuperEquipEnhanceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Item")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.translation
local var_0_5 = require("framework.scheduler")
local var_0_6 = xyd.tables.attr
local var_0_7 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.item = arg_1_2.item
	arg_1_0.id = arg_1_2.index
	arg_1_0.currentNum = 1
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0)
	return
end

function var_0_0.willClose(arg_5_0)
	local var_5_0 = xyd.WindowManager.get():getWindow("super_equip_confirm")

	if var_5_0 and not tolua.isnull(var_5_0) then
		var_5_0:update()
	end
end

function var_0_0.layout(arg_6_0)
	xyd.setItemBorder(arg_6_0:nodeByName("enhance_item"), arg_6_0.item:getTableID())
	arg_6_0:nodeByName("text_enhance_level"):setString(var_0_3:translation("TAITAN_EQUIPMENT_EVOLUTION_LV"))
	arg_6_0:nodeByName("text_tips"):setString(var_0_3:translation("TAITAN_TEXT_5"))
	arg_6_0:nodeByName("text_enhance_need"):setString(var_0_3:translation("TAITAN_EQUIPMENT_EVOLUTION_NEED"))
	arg_6_0:nodeByName("text_confirm"):setString(var_0_3:translation("TAITAN_EQUIPMENT_EVOLUTION_GO"))
	arg_6_0:nodeByName("txt_max"):setString(var_0_3:translation("HERO_MAIN_TEXT_55"))
	arg_6_0:nodeByName("txt_sure"):setString(var_0_3:translation("HERO_MAIN_TEXT_31"))
	arg_6_0:update()
	arg_6_0:updateNum()

	local var_6_0

	arg_6_0:nodeByName("button"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("button"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = arg_6_0:getEnhanceNum()

			if arg_6_0.maxNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_4:translation("TAITAN_TEXT_5"))
				})
			elseif arg_6_0.currentNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_4:translation("TAITAN_TEXT_7"))
				})
			elseif arg_6_0:getEnhanceNum() > arg_6_0.item:getSelfNum() then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_4:translation("TAITAN_EQUIPMENT_EVOLUTION_TIPS1"))
				})
			else
				local var_7_1 = string.format(var_0_4:translation("TAITAN_TEXT_6"), var_7_0, arg_6_0.item:getName(), arg_6_0.hero:getEquipLevel(arg_6_0.id) + arg_6_0.currentNum)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_7_1
				}, function()
					local var_8_0 = {
						partner_id = arg_6_0.hero:getHeroID(),
						equip_index = arg_6_0.id,
						enhance_times = arg_6_0.currentNum
					}
					local var_8_1 = xyd.WindowManager.get():getWindow("super_equip_confirm")

					if var_8_1 and not tolua.isnull(var_8_1) then
						var_8_1.isPlayingEffect = true

						var_8_1.effect:play(function()
							arg_6_0.hero:enhanceSuperEquip(var_8_0, function(arg_10_0, arg_10_1)
								if arg_10_0 == xyd.error.OK then
									local var_10_0 = xyd.WindowManager.get():getWindow("super_equip_confirm")

									if var_10_0 and not tolua.isnull(var_10_0) then
										var_10_0.totalEnhanced = var_10_0.totalEnhanced + arg_6_0.currentNum
									end

									local var_10_1 = {
										itemID = arg_6_0.item:getTableID(),
										itemNum = var_7_0
									}

									arg_6_0.selfPlayer:getBackpack():removeItem(var_10_1)
									arg_6_0.item:addEquipLevel(arg_6_0.currentNum)
									arg_6_0:dispatchEvent({
										name = xyd.event.EQUIP_ENHANCED
									})
									arg_6_0:update()
									arg_6_0:updateNum()

									if var_10_0 and not tolua.isnull(var_10_0) then
										var_10_0.isPlayingEffect = false
									end
								end
							end)
						end)
					end
				end)
			end
		end
	end)

	local var_6_1 = cc.ui.UIPushButton.new({
		pressed = "windows/hero/btn_jian_white.png",
		disabled = "windows/hero/btn_jian_white.png",
		normal = "windows/hero/btn_jian_white.png"
	})

	var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_1:setScale(1, 1)
	var_6_1:addTo(arg_6_0:nodeByName("btn_jian"))
	var_6_1:setName("jiandian")

	local var_6_2 = false

	var_6_1:onButtonPressed(function(arg_11_0)
		local var_11_0 = 0

		var_6_1:scale(0.9)

		local function var_11_1()
			var_11_0 = var_11_0 + 0.03

			if arg_6_0.decreaseCurrentNum then
				arg_6_0:decreaseCurrentNum()
			end
		end

		local function var_11_2()
			var_11_0 = var_11_0 + 0.1

			if var_11_0 > 0.5 and var_11_0 <= 4 then
				var_6_2 = true

				if arg_6_0.decreaseCurrentNum then
					arg_6_0:decreaseCurrentNum()
				end
			elseif var_11_0 > 4 then
				arg_6_0.handler[2] = var_0_5.scheduleGlobal(var_11_1, 0.03)

				var_0_5.unscheduleGlobal(arg_6_0.handler[1])
			else
				var_6_2 = false
			end
		end

		var_6_2 = false
		arg_6_0.handler[1] = var_0_5.scheduleGlobal(var_11_2, 0.1)
	end)
	var_6_1:onButtonRelease(function(arg_14_0)
		var_6_1:scale(1)

		if arg_6_0.handler[1] ~= nil then
			var_0_5.unscheduleGlobal(arg_6_0.handler[1])
		end

		if arg_6_0.handler[2] ~= nil then
			var_0_5.unscheduleGlobal(arg_6_0.handler[2])
		end

		if var_6_2 == false and arg_6_0.decreaseCurrentNum then
			arg_6_0:decreaseCurrentNum()
		end
	end)

	local var_6_3 = cc.ui.UIPushButton.new({
		pressed = "windows/hero/btn_plus_white.png",
		disabled = "windows/hero/btn_plus_white.png",
		normal = "windows/hero/btn_plus_white.png"
	})

	var_6_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_3:setScale(1, 1)
	var_6_3:addTo(arg_6_0:nodeByName("btn_add"))
	var_6_3:setName("jiadian")

	local var_6_4 = false

	var_6_3:onButtonPressed(function(arg_15_0)
		var_6_3:scale(0.9)

		local var_15_0 = 0

		local function var_15_1()
			var_15_0 = var_15_0 + 0.03

			if arg_6_0.addCurrentNum then
				arg_6_0:addCurrentNum()
			end
		end

		local function var_15_2()
			var_15_0 = var_15_0 + 0.1

			if var_15_0 > 0.5 and var_15_0 <= 4 then
				var_6_4 = true

				if arg_6_0.addCurrentNum then
					arg_6_0:addCurrentNum()
				end
			elseif var_15_0 > 4 then
				arg_6_0.handler[2] = var_0_5.scheduleGlobal(var_15_1, 0.03)

				var_0_5.unscheduleGlobal(arg_6_0.handler[1])
			else
				var_6_4 = false
			end
		end

		var_6_4 = false
		arg_6_0.handler[1] = var_0_5.scheduleGlobal(var_15_2, 0.1)
	end)
	var_6_3:onButtonRelease(function(arg_18_0)
		var_6_3:scale(1)

		if arg_6_0.handler[1] ~= nil then
			var_0_5.unscheduleGlobal(arg_6_0.handler[1])
		end

		if arg_6_0.handler[2] ~= nil then
			var_0_5.unscheduleGlobal(arg_6_0.handler[2])
		end

		if var_6_4 == false and arg_6_0.addCurrentNum then
			arg_6_0:addCurrentNum()
		end
	end)
	arg_6_0:nodeByName("btn_max"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_6_0:nodeByName("btn_max"), arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = arg_6_0.item:getSelfNum()

			if var_19_0 < arg_6_0.maxNum then
				arg_6_0.currentNum = var_19_0
			else
				arg_6_0.currentNum = arg_6_0.maxNum
			end

			arg_6_0:updateNum()
		end
	end)
end

function var_0_0.update(arg_20_0)
	local var_20_0 = arg_20_0:nodeByName("item")

	var_20_0:removeAllChildren()
	xyd.setItemBorder(var_20_0, arg_20_0.item:getTableID(), nil, nil, nil, nil, nil, arg_20_0.hero:getEquipLevel(arg_20_0.id))

	arg_20_0.maxNum = xyd.tables.superPartnerStar:equipLimit(arg_20_0.hero:getStar()) - arg_20_0.hero:getEquipLevel(arg_20_0.id)
	arg_20_0.minNum = math.min(1, arg_20_0.maxNum)
	arg_20_0.currentNum = arg_20_0.minNum
end

function var_0_0.addCurrentNum(arg_21_0)
	if arg_21_0.currentNum + 1 >= arg_21_0.maxNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_4:translation("TAITAN_TEXT_11"))
		})

		arg_21_0.currentNum = arg_21_0.maxNum
	else
		arg_21_0.currentNum = arg_21_0.currentNum + 1
	end

	arg_21_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_22_0)
	if arg_22_0.currentNum - 1 < arg_22_0.minNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_4:translation("TAITAN_TEXT_10"))
		})

		arg_22_0.currentNum = arg_22_0.minNum
	else
		arg_22_0.currentNum = arg_22_0.currentNum - 1
	end

	arg_22_0:updateNum()
end

function var_0_0.updateNum(arg_23_0)
	arg_23_0:nodeByName("enhance_num"):setString(arg_23_0.currentNum .. "/" .. arg_23_0.maxNum)

	if arg_23_0.maxNum == 0 then
		arg_23_0:nodeByName("text_tips"):setVisible(true)
	else
		arg_23_0:nodeByName("text_tips"):setVisible(false)
	end

	local var_23_0 = arg_23_0:nodeByName("item2")

	var_23_0:removeAllChildren()
	xyd.setItemBorder(var_23_0, arg_23_0.item:getTableID(), nil, nil, nil, nil, nil, arg_23_0.hero:getEquipLevel(arg_23_0.id) + arg_23_0.currentNum)

	local var_23_1 = arg_23_0:getEnhanceNum()
	local var_23_2 = arg_23_0.item:getSelfNum()

	arg_23_0:nodeByName("enhance_need_num"):setString(arg_23_0:getEnhanceNum() .. "/" .. arg_23_0.item:getSelfNum())

	if var_23_1 <= var_23_2 then
		arg_23_0:nodeByName("enhance_need_num"):setColor(cc.c4b(253, 146, 11, 255))
	else
		arg_23_0:nodeByName("enhance_need_num"):setColor(cc.c4b(177, 8, 8, 255))
	end

	local var_23_3 = var_0_2.new()
	local var_23_4 = arg_23_0.hero:getEquipLevel(arg_23_0.id) + arg_23_0.currentNum

	var_23_3:populate({
		table_id = arg_23_0.item:getTableID(),
		equip_level = var_23_4
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.EQUIP_ENHANCE_CHANGE,
		params = {
			item = var_23_3
		}
	})
end

function var_0_0.getEnhanceNum(arg_24_0)
	local var_24_0 = 0

	for iter_24_0 = arg_24_0.hero:getEquipLevel(arg_24_0.id) + 1, arg_24_0.hero:getEquipLevel(arg_24_0.id) + arg_24_0.currentNum do
		var_24_0 = var_24_0 + xyd.tables.superEquipEnhance:needNum(math.ceil(iter_24_0 / 10))
	end

	return var_24_0
end

function var_0_0.didClose(arg_25_0)
	if arg_25_0.handler then
		if arg_25_0.handler[1] then
			var_0_5.unscheduleGlobal(arg_25_0.handler[1])
		end

		if arg_25_0.handler[2] then
			var_0_5.unscheduleGlobal(arg_25_0.handler[2])
		end
	end
end

return var_0_0
