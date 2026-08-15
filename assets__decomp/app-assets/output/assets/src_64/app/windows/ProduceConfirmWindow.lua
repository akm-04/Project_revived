local var_0_0 = class("ProduceConfirmWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.dormFurnitureItem
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.item = arg_1_2.item
	arg_1_0.num = 1

	arg_1_0:genLimit()
end

function var_0_0.genLimit(arg_2_0)
	local var_2_0 = var_0_2:compose(arg_2_0.item)
	local var_2_1 = var_0_2:composeNum(arg_2_0.item)
	local var_2_2 = math.floor(arg_2_0.selfPlayer.glue / var_0_2:glue(arg_2_0.item))

	for iter_2_0, iter_2_1 in pairs(var_2_0) do
		if var_2_2 > math.floor(arg_2_0.selfPlayer:getBackpack():getItemNumByID(var_2_0[iter_2_0]) / var_2_1[iter_2_0]) then
			var_2_2 = math.floor(arg_2_0.selfPlayer:getBackpack():getItemNumByID(var_2_0[iter_2_0]) / var_2_1[iter_2_0])
		end
	end

	arg_2_0.limit = var_2_2
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:setButtonClick()
	arg_3_0:layout()
end

function var_0_0.setButtonClick(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("btn_add"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.num = arg_4_0.num + 1

			if arg_4_0.num >= arg_4_0.limit then
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(true)
			end

			if arg_4_0.num <= 1 then
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(true)
			end

			arg_4_0:setBtnChange()
		end
	end)
	arg_4_0:nodeByName("btn_minus"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.num = arg_4_0.num - 1

			if arg_4_0.num >= arg_4_0.limit then
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(true)
			end

			if arg_4_0.num <= 1 then
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(true)
			end

			arg_4_0:setBtnChange()
		end
	end)
	arg_4_0:nodeByName("btn_max"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.num = arg_4_0.limit

			if arg_4_0.num >= arg_4_0.limit then
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_add"):setTouchEnabled(true)
			end

			if arg_4_0.num <= 1 then
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(false)
			else
				arg_4_0:nodeByName("btn_minus"):setTouchEnabled(true)
			end

			arg_4_0:setBtnChange()
		end
	end)
	arg_4_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_4_0.selfPlayer:makeItem({
				item_id = arg_4_0.item,
				item_num = arg_4_0.num
			}, function(arg_10_0)
				if arg_10_0 == xyd.error.OK then
					local var_10_0 = xyd.WindowManager.get():getWindow("furniture_factory")
					local var_10_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

					if var_10_0 then
						var_10_0:nodeByName("glue_num"):setString(var_10_1.glue .. "/" .. xyd.tables.misc.glueBuyLimit)
					end

					local var_10_2 = {
						itemID = arg_4_0.item,
						itemNum = arg_4_0.num
					}

					xyd.WindowManager.get():openWindow("make_furniture_success", var_10_2)
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	return
end

function var_0_0.didClose(arg_12_0, arg_12_1)
	var_0_0.super:didClose(arg_12_1)
end

function var_0_0.layout(arg_13_0)
	if arg_13_0.num >= arg_13_0.limit then
		arg_13_0:nodeByName("btn_add"):setTouchEnabled(false)
	else
		arg_13_0:nodeByName("btn_add"):setTouchEnabled(true)
	end

	if arg_13_0.num <= 1 then
		arg_13_0:nodeByName("btn_minus"):setTouchEnabled(false)
	else
		arg_13_0:nodeByName("btn_minus"):setTouchEnabled(true)
	end

	arg_13_0:nodeByName("text1"):setString(var_0_1:translation("PRODUCE_CONFIRM_TEXT1"))
	arg_13_0:nodeByName("text1_Copy"):setString(var_0_1:translation("PRODUCE_CONFIRM_TEXT2"))
	arg_13_0:nodeByName("item"):removeAllChildren()
	xyd.setItemBorder(arg_13_0:nodeByName("item"), arg_13_0.item)

	local var_13_0 = {}
	local var_13_1 = arg_13_0:nodeByName("item"):getContentSize().height
	local var_13_2 = display.newNode()

	var_13_2:setContentSize(var_13_1, var_13_1)
	var_13_2:addTo(arg_13_0:nodeByName("item"))
	var_13_2:setAnchorPoint(cc.p(0, 0))

	var_13_0.id = arg_13_0.item
	var_13_0.lev = xyd.tables.item:level(arg_13_0.item)

	if xyd.tables.item:type(arg_13_0.item) == -1 then
		var_13_0.tipsType = 0
		var_13_0.desc1 = xyd.tables.hero:getDes(arg_13_0.item)
	elseif specialItem then
		var_13_0.tipsType = 1
		var_13_0.id = -3
	else
		var_13_0.tipsType = 1
		var_13_0.desc1 = xyd.tables.item:desc1(arg_13_0.item)
		var_13_0.desc2 = xyd.tables.item:desc2(arg_13_0.item)
	end

	var_13_0.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_13_0.item)
	var_13_0.name = xyd.tables.item:name(arg_13_0.item)

	arg_13_0:addTips(var_13_2, var_13_0)
	arg_13_0:setBtnChange()
end

function var_0_0.setBtnChange(arg_14_0)
	arg_14_0:nodeByName("num"):setString(tostring(arg_14_0.num))
	arg_14_0:rewardLayer()
end

function var_0_0.rewardLayer(arg_15_0)
	arg_15_0:nodeByName("materials_container"):removeAllChildren()

	local var_15_0
	local var_15_1 = var_0_2:compose(arg_15_0.item)

	if #var_15_1 == 1 and var_15_1[1] == 0 then
		var_15_1 = {}
	end

	local var_15_2
	local var_15_3 = clone(var_0_2:composeNum(arg_15_0.item))

	for iter_15_0, iter_15_1 in pairs(var_15_3) do
		var_15_3[iter_15_0] = var_15_3[iter_15_0] * arg_15_0.num
	end

	local var_15_4 = #var_15_3
	local var_15_5 = arg_15_0:nodeByName("materials_container"):getContentSize().height
	local var_15_6 = var_15_5 / 4 - 1
	local var_15_7 = (arg_15_0:nodeByName("materials_container"):getContentSize().width - var_15_4 * var_15_5 - (var_15_4 - 1) * var_15_6) / 2
	local var_15_8 = #var_15_1

	for iter_15_2 = 1, #var_15_1 do
		local var_15_9 = display.newNode()

		var_15_9:setContentSize(var_15_5, var_15_5)

		local var_15_10 = xyd.tables.item:type(var_15_1[iter_15_2])

		xyd.setItemBorder(var_15_9, var_15_1[iter_15_2], false, false, var_15_3[iter_15_2])
		var_15_9:addTo(arg_15_0:nodeByName("materials_container"))
		var_15_9:setAnchorPoint(cc.p(0, 0))
		var_15_9:setPosition(var_15_7 + (iter_15_2 - 1) * (var_15_5 + var_15_6), 0)

		local var_15_11 = {
			id = var_15_1[iter_15_2],
			lev = xyd.tables.item:level(var_15_1[iter_15_2])
		}

		if xyd.tables.item:type(var_15_1[iter_15_2]) == -1 then
			var_15_11.tipsType = 0
			var_15_11.desc1 = xyd.tables.hero:getDes(var_15_1[iter_15_2])
		elseif specialItem then
			var_15_11.tipsType = 1
			var_15_11.id = -3
		else
			var_15_11.tipsType = 1
			var_15_11.desc1 = xyd.tables.item:desc1(var_15_1[iter_15_2])
			var_15_11.desc2 = xyd.tables.item:desc2(var_15_1[iter_15_2])
		end

		var_15_11.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_15_1[iter_15_2])
		var_15_11.name = xyd.tables.item:name(var_15_1[iter_15_2])

		arg_15_0:addTips(var_15_9, var_15_11)
	end
end

return var_0_0
