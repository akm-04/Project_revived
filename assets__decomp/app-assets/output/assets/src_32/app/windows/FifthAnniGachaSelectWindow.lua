local var_0_0 = class("FifthAnniGachaSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.fifthAnniGacha
local var_0_3 = xyd.tables.gift
local var_0_4 = import("framework.scheduler")
local var_0_5 = import("app.common.ui.SplitLine")
local var_0_6 = 4
local var_0_7 = 77
local var_0_8 = 34
local var_0_9 = 21

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.maxNum = arg_1_2.num
	arg_1_0.pool = arg_1_2.pool
	arg_1_0.items = var_0_2:getPoolItems(arg_1_0.pool)
	arg_1_0.selectIds = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_2.selectItems) do
		for iter_1_2, iter_1_3 in ipairs(arg_1_0.items) do
			if iter_1_1 == iter_1_3 then
				table.insert(arg_1_0.selectIds, iter_1_2)

				break
			end
		end
	end

	arg_1_0.selectNum = #arg_1_0.selectIds
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:setButtonClick()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_13"))
	arg_4_0:nodeByName("txt_num"):setString(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_15"))
	arg_4_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_4_0:nodeByName("txt_sure"):setString(var_0_1:translation("SURE"))
	arg_4_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_4_0 = arg_4_0:nodeByName("item_container")
	local var_4_1 = var_4_0:getContentSize()
	local var_4_2 = 0
	local var_4_3 = var_4_1.height - var_0_7

	for iter_4_0 = 1, #arg_4_0.items do
		local var_4_4 = display.newNode()
		local var_4_5 = var_0_2:giftId(arg_4_0.items[iter_4_0])

		var_4_4:setContentSize(var_0_7, var_0_7)
		var_4_4:setPosition(var_4_2, var_4_3)
		var_4_4:setName("node_" .. iter_4_0)
		xyd.setItemAndAddTips(var_4_4, var_0_3:items(var_4_5)[1], var_0_3:itemNum(var_4_5)[1])
		var_4_4:setTouchEnabled(true)
		var_4_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				return true
			elseif arg_5_0.name == "ended" then
				if arg_4_0.scrollViewMoved_ then
					return
				end

				local var_5_0 = var_4_4:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))

				if var_5_0.x < 0 or var_5_0.x > var_0_7 or var_5_0.y < 0 or var_5_0.y > var_0_7 then
					return
				end

				arg_4_0:select(iter_4_0)
			end
		end)
		var_4_0:addChild(var_4_4)

		if iter_4_0 % var_0_6 == 0 then
			var_4_3 = var_4_3 - var_0_7 - var_0_9
			var_4_2 = 0
		else
			var_4_2 = var_4_2 + var_0_7 + var_0_8
		end
	end

	for iter_4_1, iter_4_2 in ipairs(arg_4_0.selectIds) do
		arg_4_0:addSelectEffect(iter_4_2)
	end

	arg_4_0:nodeByName("txt_tips"):setString(string.format(var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_14"), arg_4_0.maxNum))

	local var_4_6 = var_0_5.new({
		size = 400
	})

	arg_4_0:nodeByName("pos_line"):addChild(var_4_6)
	arg_4_0:updateSelectNum()
end

function var_0_0.setButtonClick(arg_6_0)
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_sure"), nil, function()
		if arg_6_0.callback then
			local var_7_0 = {}

			table.sort(arg_6_0.selectIds)

			for iter_7_0, iter_7_1 in ipairs(arg_6_0.selectIds) do
				table.insert(var_7_0, arg_6_0.items[iter_7_1])
			end

			arg_6_0.callback(arg_6_0.pool, var_7_0)
		end

		arg_6_0:close()
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_cancel"), nil, function()
		arg_6_0:close()
	end)
end

function var_0_0.select(arg_9_0, arg_9_1)
	local var_9_0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selectIds) do
		if iter_9_1 == arg_9_1 then
			var_9_0 = iter_9_0

			break
		end
	end

	if var_9_0 then
		table.remove(arg_9_0.selectIds, var_9_0)

		arg_9_0.selectNum = arg_9_0.selectNum - 1

		arg_9_0:removeSelectEffect(arg_9_1)
		arg_9_0:updateSelectNum()

		return
	else
		if arg_9_0.selectNum >= arg_9_0.maxNum then
			local var_9_1 = var_0_1:translation("FIFTH_ANNI_GACHA_TEXT_16")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_9_1
			})

			return
		end

		table.insert(arg_9_0.selectIds, arg_9_1)

		arg_9_0.selectNum = arg_9_0.selectNum + 1

		arg_9_0:addSelectEffect(arg_9_1)
		arg_9_0:updateSelectNum()
	end
end

function var_0_0.addSelectEffect(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0:nodeByName("item_container"):getChildByName("node_" .. arg_10_1)

	if var_10_0:getChildByName("select_effect") then
		return
	end

	local var_10_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1232/gacha/select.png")

	var_10_1:setNormalizedPosition(cc.p(0.5, 0.5))
	var_10_1:setScale(0.7)
	var_10_1:setName("select_effect")
	var_10_0:addChild(var_10_1)
	arg_10_0:updateAllSelectAction()
end

function var_0_0.removeSelectEffect(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0:nodeByName("item_container"):getChildByName("node_" .. arg_11_1):getChildByName("select_effect")

	if not var_11_0 then
		return
	end

	var_11_0:removeFromParent()
end

function var_0_0.updateAllSelectAction(arg_12_0)
	for iter_12_0 = 1, 8 do
		repeat
			local var_12_0 = arg_12_0:nodeByName("item_container"):getChildByName("node_" .. iter_12_0)

			if not var_12_0 then
				break
			end

			local var_12_1 = var_12_0:getChildByName("select_effect")

			if not var_12_1 then
				break
			end

			transition.stopTarget(var_12_1)
			var_12_1:setScale(0.7)

			local var_12_2 = cc.ScaleBy:create(0.3, 1.04)
			local var_12_3 = transition.sequence({
				var_12_2,
				var_12_2:reverse()
			})
			local var_12_4 = cc.RepeatForever:create(var_12_3)

			var_12_1:runAction(var_12_4)
		until true
	end
end

function var_0_0.updateSelectNum(arg_13_0)
	arg_13_0:nodeByName("num"):setString(string.format("%d/%d", arg_13_0.maxNum - arg_13_0.selectNum, arg_13_0.maxNum))
end

return var_0_0
