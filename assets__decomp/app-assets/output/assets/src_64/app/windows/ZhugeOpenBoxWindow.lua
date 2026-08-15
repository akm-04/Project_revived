local var_0_0 = class("ZhugeOpenBoxWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = class("SpineEffect", import("app.common.ui.SpineEffect"))

function var_0_2.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	var_0_2.super.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
end

function var_0_2.play(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local function var_2_0()
		local var_3_0 = arg_2_2

		arg_2_2 = nil

		if var_3_0 ~= nil then
			var_3_0()
		end
	end

	if not arg_2_0:hasAnimation(arg_2_1) then
		print("not self:hasAnimation(name)" .. arg_2_1)
		var_2_0()

		return
	end

	arg_2_0:registerSpineEventHandler(function(arg_4_0)
		arg_2_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		arg_2_0:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		var_2_0()
	end, sp.EventType.ANIMATION_COMPLETE)
	arg_2_0:registerSpineEventHandler(function(arg_5_0)
		if arg_5_0.eventData ~= nil and arg_5_0.eventData.name == "hit" then
			var_2_0()
		end
	end, sp.EventType.ANIMATION_EVENT)
	arg_2_0:setAnimation(0, arg_2_1, arg_2_3)

	if arg_2_4 then
		arg_2_0:setTimeScale(arg_2_4)
	end
end

function var_0_0.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_0.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_6_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_6_0.backpack = arg_6_0.selfPlayer:getBackpack()
	arg_6_0.awards = arg_6_2.awards
	arg_6_0.boxType = arg_6_2.boxType
	arg_6_0.summonType = arg_6_2.summonType
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super:willOpen(arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
	arg_7_0:layout()
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("item"):removeAllChildren()

	local var_9_0 = arg_9_0.awards[1]
	local var_9_1 = xyd.tables.item:name(var_9_0.table_id)

	arg_9_0:nodeByName("text_desc"):setString(var_0_1:translation("ZHUGE_HOUSE_TIPS_9") .. var_9_1 .. " x" .. var_9_0.item_num)
	xyd.setItemAndAddTips(arg_9_0:nodeByName("item"), var_9_0.table_id, var_9_0.item_num)
	arg_9_0:nodeByName("btn_open"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			if arg_9_0.backpack:getItemNumByID(xyd.tables.misc.zhugeBoxPartItem) < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ZHUGE_HOUSE_TIPS_20")
				})

				return
			end

			arg_9_0.zhugeModel:summon(arg_9_0.summonType, 1, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					local var_11_0 = {
						itemNum = 1,
						itemID = xyd.tables.misc.zhugeBoxPartItem
					}

					arg_9_0.backpack:removeItem(var_11_0)

					arg_9_0.awards = arg_11_1.awards

					if arg_11_1.awards then
						for iter_11_0 = 1, #arg_11_1.awards do
							local var_11_1 = arg_11_1.awards[iter_11_0]

							arg_9_0.backpack:addItemsByID(var_11_1.table_id, var_11_1.item_num)
						end
					end

					local var_11_2 = xyd.WindowManager.get():getWindow("zhuge_small_house")

					if var_11_2 then
						var_11_2:updateCoin()
					end

					arg_9_0:layout()
				end
			end)
		end
	end)

	if not arg_9_0.lightEffcet then
		arg_9_0:playLightEffect()
	end

	arg_9_0:playOpenEffect()
	arg_9_0:updateBg(false)

	local var_9_2 = arg_9_0.backpack:getItemNumByID(xyd.tables.misc.zhugeBoxPartItem)

	arg_9_0:nodeByName("text_box_num"):setString(string.format(var_0_1:translation("ZHUGE_ADVENTURE_TIPS_17"), var_9_2))
end

function var_0_0.updateBg(arg_12_0, arg_12_1)
	if arg_12_1 then
		arg_12_0.canClick = true

		for iter_12_0, iter_12_1 in ipairs(arg_12_0:nodeByName("container"):getChildren()) do
			if iter_12_1 ~= nil and iter_12_1:getName() ~= "box_effect" then
				iter_12_1:setVisible(true)
			end
		end
	else
		arg_12_0.canClick = false

		for iter_12_2, iter_12_3 in ipairs(arg_12_0:nodeByName("container"):getChildren()) do
			if iter_12_3 ~= nil and iter_12_3:getName() ~= "box_effect" then
				iter_12_3:setVisible(false)
			end
		end
	end
end

function var_0_0.playLightEffect(arg_13_0)
	local var_13_0 = "skeletons/ui_effect/zhugeliang/zhuge_effect01"
	local var_13_1 = cc.p(arg_13_0:nodeByName("item"):getPosition())

	arg_13_0.lightEffcet = arg_13_0:createEffect("texiao", var_13_0, arg_13_0:nodeByName("container"), var_13_1, 1)

	arg_13_0.lightEffcet:setLocalZOrder(-1)
	arg_13_0.lightEffcet:play("texiao", nil, true)
end

function var_0_0.createEffect(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5)
	local var_14_0 = arg_14_5 or 1
	local var_14_1 = var_0_2.new(arg_14_2 .. ".json", arg_14_2 .. ".atlas", var_14_0)

	var_14_1:addTo(arg_14_3)
	var_14_1:setPosition(arg_14_4)

	return var_14_1
end

function var_0_0.playOpenEffect(arg_15_0)
	local var_15_0 = "skeletons/ui_effect/zhugeliang/zhuge_box"
	local var_15_1 = cc.p(arg_15_0:nodeByName("item"):getPosition())

	arg_15_0.boxEffcet = arg_15_0:createEffect(arg_15_0.boxType, var_15_0, arg_15_0:nodeByName("container"), var_15_1, 1)

	arg_15_0.boxEffcet:setName("box_effect")
	arg_15_0.boxEffcet:play(arg_15_0.boxType, function()
		arg_15_0:updateBg(true)
	end, false)
end

return var_0_0
