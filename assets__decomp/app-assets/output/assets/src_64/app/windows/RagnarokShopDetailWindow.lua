local var_0_0 = class("RagnarokShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.misc:getValue("activity_ragnarok_shop_item")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.idx = arg_1_2.id
	arg_1_0.itemID = arg_1_2.item_id
	arg_1_0.itemNum = arg_1_2.item_num
	arg_1_0.maxNum = arg_1_2.max_num
	arg_1_0.leftNum = arg_1_2.left_num
	arg_1_0.price = arg_1_2.price
	arg_1_0.currentNum = math.min(1, arg_1_0.maxNum)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_have1"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_4"))
	arg_4_0:nodeByName("txt_have2"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_5"))
	arg_4_0:nodeByName("txt_select"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_6"))
	arg_4_0:nodeByName("txt_max"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_7"))
	arg_4_0:nodeByName("txt_total"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_8"))
	arg_4_0:nodeByName("txt_buy"):setString(var_0_3:translation("RAGNAROK_BOSS_SHOP_9"))
	var_0_1.new({
		size = 402
	}):addTo(arg_4_0:nodeByName("pos_line"))
	xyd.setItemAndAddTips(arg_4_0:nodeByName("item"), arg_4_0.itemID, arg_4_0.itemNum)
	arg_4_0:updateNum()

	local var_4_0 = arg_4_0.backpack:getItemNumByID(arg_4_0.itemID)

	arg_4_0:nodeByName("txt_have_num"):setString(var_4_0)
	arg_4_0:nodeByName("txt_name"):setString(var_0_4:name(arg_4_0.itemID))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_max"), nil, function()
		arg_4_0.currentNum = arg_4_0.maxNum

		arg_4_0:updateNum()
	end)

	local var_4_1 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_4_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_1:setScale(1, 1)
	var_4_1:addTo(arg_4_0:nodeByName("btn_sub"))
	var_4_1:setName("jiandian")

	local var_4_2 = false

	var_4_1:onButtonPressed(function(arg_6_0)
		local var_6_0 = 0

		local function var_6_1()
			var_6_0 = var_6_0 + 0.03

			if arg_4_0.decreaseCurrentNum then
				arg_4_0:decreaseCurrentNum()
			end
		end

		local function var_6_2()
			var_6_0 = var_6_0 + 0.1

			if var_6_0 > 0.5 and var_6_0 <= 4 then
				var_4_2 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_6_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_6_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_2 = false
			end
		end

		var_4_2 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_6_2, 0.1)
	end)
	var_4_1:onButtonRelease(function(arg_9_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_2 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:setScale(1, 1)
	var_4_3:addTo(arg_4_0:nodeByName("btn_add"))
	var_4_3:setName("jiadian")

	local var_4_4 = false

	var_4_3:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_4_0.addCurrentNum then
				arg_4_0:addCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_4_4 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_4 = false
			end
		end

		var_4_4 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
	end)
	var_4_3:onButtonRelease(function(arg_13_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_4 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_buy"), nil, function()
		if arg_4_0.leftNum == 0 then
			local var_14_0 = var_0_3:translation("RAGNAROK_BOSS_SHOP_11")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_14_0
			})

			return
		elseif arg_4_0.currentNum == 0 then
			local var_14_1 = var_0_3:translation("RAGNAROK_BOSS_SHOP_10")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_14_1
			})

			return
		end

		local var_14_2 = {
			idx = arg_4_0.idx,
			num = arg_4_0.currentNum
		}

		arg_4_0.ragnarok:getReward(var_14_2, function(arg_15_0, arg_15_1)
			if arg_15_0 == xyd.error.OK then
				local var_15_0 = {
					itemID = var_0_5,
					itemNum = arg_4_0.currentNum * arg_4_0.price
				}

				arg_4_0.selfPlayer:handleRewards(arg_15_1.awards)
				arg_4_0.backpack:removeItem(var_15_0)

				if arg_4_0.callback then
					arg_4_0.callback(arg_15_1)
				end

				arg_4_0:close()
			end
		end)
	end)
end

function var_0_0.decreaseCurrentNum(arg_16_0)
	if arg_16_0.currentNum - 1 <= 0 then
		return
	else
		arg_16_0.currentNum = arg_16_0.currentNum - 1
	end

	arg_16_0:updateNum()
end

function var_0_0.addCurrentNum(arg_17_0)
	if arg_17_0.currentNum >= arg_17_0.maxNum then
		return
	else
		arg_17_0.currentNum = arg_17_0.currentNum + 1
	end

	arg_17_0:updateNum()
end

function var_0_0.updateNum(arg_18_0)
	arg_18_0:nodeByName("txt_buy_num"):setString(arg_18_0.currentNum .. "/" .. arg_18_0.maxNum)
	arg_18_0:nodeByName("txt_cost"):setString(arg_18_0.currentNum * arg_18_0.price)
end

return var_0_0
