local var_0_0 = class("WarCampShopBuyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.camp_ = arg_1_0.warCamp_:getCampType()
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.buyNum = 1
	arg_1_0.id = arg_1_2.id
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.singleCost = arg_1_2.singleCost
	arg_1_0.remainTimes = arg_1_2.remainTimes
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:nodeByName("friendship_coin1"):setTexture("windows/war_camp/img_score_" .. arg_2_0.camp_ .. ".png")
	arg_2_0:nodeByName("friendship_coin1"):setScale(0.5)
end

function var_0_0.layout(arg_3_0)
	xyd.setItemBorder(arg_3_0:nodeByName("icon_container"), arg_3_0.itemID)
	arg_3_0:nodeByName("name_txt"):setString(xyd.tables.item:name(arg_3_0.itemID))
	arg_3_0:nodeByName("has_text"):setString(var_0_2:translation("ITEM_OWN"))
	arg_3_0:nodeByName("jian_text"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))
	arg_3_0:nodeByName("total_cost_text"):setString(var_0_2:translation("TOTAL_COST_TEXT"))
	arg_3_0:nodeByName("select_buy_num_text"):setString(var_0_2:translation("SELECT_BUY_NUM_TEXT"))

	local var_3_0 = arg_3_0.selfPlayer:getBackpack():getItemNumByID(arg_3_0.itemID)

	arg_3_0:nodeByName("own_num_txt"):setString(tostring(var_3_0))
	arg_3_0:nodeByName("name_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName("own_num_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName("cost_num_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_3_1, var_3_2 = arg_3_0:nodeByName("own_num_txt"):getPosition()

	arg_3_0:nodeByName("jian_text"):x(var_3_1 + arg_3_0:nodeByName("own_num_txt"):getContentSize().width + 5)
	arg_3_0:updateNum()
end

function var_0_0.updateNum(arg_4_0)
	local var_4_0 = arg_4_0.warCamp_:getScore()

	arg_4_0.canBuyNum = math.floor(var_4_0 / arg_4_0.singleCost)

	if arg_4_0.remainTimes and arg_4_0.canBuyNum > arg_4_0.remainTimes then
		arg_4_0.canBuyNum = arg_4_0.remainTimes
	end

	if arg_4_0.canBuyNum > xyd.tables.item:stack(arg_4_0.itemID) - arg_4_0.backpack:getItemNumByID(arg_4_0.itemID) then
		arg_4_0.canBuyNum = xyd.tables.item:stack(arg_4_0.itemID) - arg_4_0.backpack:getItemNumByID(arg_4_0.itemID)
	end

	if arg_4_0.canBuyNum < 0 then
		arg_4_0.canBuyNum = 0
	end

	if arg_4_0.buyNum > arg_4_0.canBuyNum then
		arg_4_0.buyNum = arg_4_0.canBuyNum
	end

	arg_4_0:nodeByName("sell_num_txt"):setString(arg_4_0.buyNum .. "/" .. arg_4_0.canBuyNum)
	arg_4_0:nodeByName("cost_num_txt"):setString(arg_4_0.buyNum * arg_4_0.singleCost)
end

function var_0_0.addCurrentNum(arg_5_0)
	if arg_5_0.buyNum + 1 >= arg_5_0.canBuyNum then
		arg_5_0.buyNum = arg_5_0.canBuyNum
	else
		arg_5_0.buyNum = arg_5_0.buyNum + 1
	end

	arg_5_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_6_0)
	if arg_6_0.buyNum - 1 <= 0 then
		arg_6_0.buyNum = 1
	else
		arg_6_0.buyNum = arg_6_0.buyNum - 1
	end

	arg_6_0:updateNum()
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0:addBlockLayer()

	local var_7_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/-_button2.png",
		disabled = "windows/button/-_button2.png",
		normal = "windows/button/-_button1.png"
	})

	var_7_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_0:setScale(1, 1)
	var_7_0:addTo(arg_7_0:nodeByName("decrease_pos"))
	var_7_0:setName("jiandian")

	local var_7_1 = false

	var_7_0:onButtonPressed(function(arg_8_0)
		local var_8_0 = 0

		local function var_8_1()
			var_8_0 = var_8_0 + 0.03

			if arg_7_0.decreaseCurrentNum then
				arg_7_0:decreaseCurrentNum()
			end
		end

		local function var_8_2()
			var_8_0 = var_8_0 + 0.1

			if var_8_0 > 0.5 and var_8_0 <= 4 then
				var_7_1 = true

				if arg_7_0.decreaseCurrentNum then
					arg_7_0:decreaseCurrentNum()
				end
			elseif var_8_0 > 4 then
				arg_7_0.handler[2] = var_0_1.scheduleGlobal(var_8_1, 0.03)

				var_0_1.unscheduleGlobal(arg_7_0.handler[1])
			else
				var_7_1 = false
			end
		end

		var_7_1 = false
		arg_7_0.handler[1] = var_0_1.scheduleGlobal(var_8_2, 0.1)
	end)
	var_7_0:onButtonRelease(function(arg_11_0)
		if arg_7_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_7_0.handler[1])
		end

		if arg_7_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_7_0.handler[2])
		end

		if var_7_1 == false and arg_7_0.decreaseCurrentNum then
			arg_7_0:decreaseCurrentNum()
		end
	end)

	local var_7_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/add_button2.png",
		disabled = "windows/button/add_button2.png",
		normal = "windows/button/add_button1.png"
	})

	var_7_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_7_2:setScale(1, 1)
	var_7_2:addTo(arg_7_0:nodeByName("increase_pos"))
	var_7_2:setName("jiadian")

	local var_7_3 = false

	var_7_2:onButtonPressed(function(arg_12_0)
		local var_12_0 = 0

		local function var_12_1()
			var_12_0 = var_12_0 + 0.03

			if arg_7_0.addCurrentNum then
				arg_7_0:addCurrentNum()
			end
		end

		local function var_12_2()
			var_12_0 = var_12_0 + 0.1

			if var_12_0 > 0.5 and var_12_0 <= 4 then
				var_7_3 = true

				if arg_7_0.addCurrentNum then
					arg_7_0:addCurrentNum()
				end
			elseif var_12_0 > 4 then
				arg_7_0.handler[2] = var_0_1.scheduleGlobal(var_12_1, 0.03)

				var_0_1.unscheduleGlobal(arg_7_0.handler[1])
			else
				var_7_3 = false
			end
		end

		var_7_3 = false
		arg_7_0.handler[1] = var_0_1.scheduleGlobal(var_12_2, 0.1)
	end)
	var_7_2:onButtonRelease(function(arg_15_0)
		if arg_7_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_7_0.handler[1])
		end

		if arg_7_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_7_0.handler[2])
		end

		if var_7_3 == false and arg_7_0.addCurrentNum then
			arg_7_0:addCurrentNum()
		end
	end)
	arg_7_0:nodeByName("max_button"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.buyNum = arg_7_0.canBuyNum

			arg_7_0:updateNum()
		end
	end)
	arg_7_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_7_0.backpack:getItemNumByID(arg_7_0.itemID) >= xyd.tables.item:stack(arg_7_0.itemID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("SHOP_BACKPACK_IS_FULL")
				})

				return
			elseif arg_7_0.buyNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("BUY_NUM_LESS_THAN_ONE")
				})

				return
			end

			local var_17_0 = {
				id = arg_7_0.id,
				num = arg_7_0.buyNum
			}

			arg_7_0.warCamp_:buyItem(var_17_0, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					arg_7_0.warCamp_.baseInfo.buy_times = arg_18_1.buy_times

					if arg_7_0.callback then
						arg_7_0.callback()
					end

					local var_18_0 = {
						{
							table_id = arg_7_0.itemID,
							item_num = arg_7_0.buyNum
						}
					}

					arg_7_0.selfPlayer:handleRewards(var_18_0)

					local var_18_1 = xyd.WindowManager.get():getWindow("war_camp_shop")

					if var_18_1 then
						var_18_1:updateMyScore()
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("WAR_CAMP_SHOP_TIPS1")
					})
				end
			end)
		end
	end)
end

function var_0_0.summaryAwards(arg_19_0, arg_19_1)
	local var_19_0 = {}
	local var_19_1 = 0

	for iter_19_0 = 1, #arg_19_1 do
		if arg_19_1[iter_19_0].table_id == -1 and arg_19_1[iter_19_0].mana and arg_19_1[iter_19_0].mana > 0 then
			var_19_1 = var_19_1 + arg_19_1[iter_19_0].mana
		elseif arg_19_1[iter_19_0].table_id > 0 then
			var_19_0[arg_19_1[iter_19_0].table_id] = (var_19_0[arg_19_1[iter_19_0].table_id] or 0) + (arg_19_1[iter_19_0].item_num or 0)
		end
	end

	local var_19_2 = {}

	for iter_19_1, iter_19_2 in pairs(var_19_0) do
		table.insert(var_19_2, {
			table_id = iter_19_1,
			item_num = iter_19_2
		})
	end

	if var_19_1 > 0 then
		table.insert(var_19_2, {
			table_id = -1,
			mana = var_19_1,
			item_num = var_19_1
		})
	end

	return var_19_2
end

function var_0_0.didClose(arg_20_0)
	if arg_20_0.handler then
		if arg_20_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_20_0.handler[1])
		end

		if arg_20_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_20_0.handler[2])
		end
	end
end

return var_0_0
