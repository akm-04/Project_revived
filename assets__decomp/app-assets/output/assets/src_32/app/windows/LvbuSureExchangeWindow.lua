local var_0_0 = class("LvbuSureExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityLvbuShopFengxian
local var_0_4 = xyd.tables.activityLvbuShopLvbusp

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.buyNum = 1
	arg_1_0.id = arg_1_2.id
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.fengxianStage = arg_1_2.fengxianStage
	arg_1_0.lvbuspStage = arg_1_2.lvbuspStage
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	xyd.setItemBorder(arg_4_0:nodeByName("icon_container"), arg_4_0.itemID)
	arg_4_0:nodeByName("name_txt"):setString(xyd.tables.item:name(arg_4_0.itemID))
	arg_4_0:nodeByName("has_text"):setString(var_0_2:translation("ITEM_OWN"))
	arg_4_0:nodeByName("jian_text"):setString(var_0_2:translation("ITEM_OWN_SUFFIX"))
	arg_4_0:nodeByName("total_cost_text"):setString(var_0_2:translation("TOTAL_COST_TEXT"))
	arg_4_0:nodeByName("select_buy_num_text"):setString(var_0_2:translation("SELECT_BUY_NUM_TEXT"))
	arg_4_0:nodeByName("max"):setString(var_0_2:translation("HERO_MAIN_TEXT_55"))
	arg_4_0:nodeByName("exchange_txt"):setString(var_0_2:translation("LVBU_NEW_TXT6"))

	local var_4_0 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.itemID)

	arg_4_0:nodeByName("own_num_txt"):setString(tostring(var_4_0))

	local var_4_1, var_4_2 = arg_4_0:nodeByName("own_num_txt"):getPosition()

	arg_4_0:nodeByName("jian_text"):x(var_4_1 + arg_4_0:nodeByName("own_num_txt"):getContentSize().width + 5)
	arg_4_0:updateNum()
end

function var_0_0.updateNum(arg_5_0)
	local var_5_0 = xyd.tables.lvbuShopItem:price(arg_5_0.id)

	if arg_5_0.id == 2 then
		var_5_0 = var_0_4:price(math.max(arg_5_0.lvbuspStage, 1))
	end

	arg_5_0.canBuyNum = math.floor(arg_5_0.selfPlayer.lvbuCoin / var_5_0)

	if arg_5_0.canBuyNum > xyd.tables.item:stack(arg_5_0.itemID) - arg_5_0.backpack:getItemNumByID(arg_5_0.itemID) then
		arg_5_0.canBuyNum = xyd.tables.item:stack(arg_5_0.itemID) - arg_5_0.backpack:getItemNumByID(arg_5_0.itemID)
	end

	if arg_5_0.id == 2 then
		local var_5_1 = var_0_4:buyLimit(arg_5_0.lvbuspStage)
		local var_5_2 = arg_5_0.lvbuFestival.details.lvbusp_times or 0

		if var_5_1 > 0 then
			arg_5_0.canBuyNum = math.min(arg_5_0.canBuyNum, var_5_1 - var_5_2)
		end
	elseif arg_5_0.canBuyNum > xyd.tables.misc.friendBuyLimit then
		arg_5_0.canBuyNum = xyd.tables.misc.friendBuyLimit
	end

	arg_5_0.canBuyNum = math.max(arg_5_0.canBuyNum, 0)

	if arg_5_0.buyNum > arg_5_0.canBuyNum then
		arg_5_0.buyNum = arg_5_0.canBuyNum
	end

	arg_5_0:nodeByName("sell_num_txt"):setString(arg_5_0.buyNum .. "/" .. arg_5_0.canBuyNum)
	arg_5_0:nodeByName("cost_num_txt"):setString(arg_5_0.buyNum * var_5_0)
end

function var_0_0.addCurrentNum(arg_6_0)
	if arg_6_0.buyNum + 1 >= arg_6_0.canBuyNum then
		arg_6_0.buyNum = arg_6_0.canBuyNum
	else
		arg_6_0.buyNum = arg_6_0.buyNum + 1
	end

	arg_6_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_7_0)
	if arg_7_0.buyNum - 1 <= 0 then
		arg_7_0.buyNum = 1
	else
		arg_7_0.buyNum = arg_7_0.buyNum - 1
	end

	arg_7_0:updateNum()
end

function var_0_0.didOpen(arg_8_0)
	arg_8_0:addBlockLayer()

	local var_8_0 = cc.ui.UIPushButton.new({
		pressed = "windows/lvbu/sure_exchange/btn_del.png",
		disabled = "windows/lvbu/sure_exchange/btn_del.png",
		normal = "windows/lvbu/sure_exchange/btn_del.png"
	})

	var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_0:setScale(1, 1)
	var_8_0:addTo(arg_8_0:nodeByName("decrease_pos"))
	var_8_0:setName("jiandian")

	local var_8_1 = false

	var_8_0:onButtonPressed(function(arg_9_0)
		var_8_0:setScale(0.9)

		local var_9_0 = 0

		local function var_9_1()
			var_9_0 = var_9_0 + 0.03

			if arg_8_0.decreaseCurrentNum then
				arg_8_0:decreaseCurrentNum()
			end
		end

		local function var_9_2()
			var_9_0 = var_9_0 + 0.1

			if var_9_0 > 0.5 and var_9_0 <= 4 then
				var_8_1 = true

				if arg_8_0.decreaseCurrentNum then
					arg_8_0:decreaseCurrentNum()
				end
			elseif var_9_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_9_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_1 = false
			end
		end

		var_8_1 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_9_2, 0.1)
	end)
	var_8_0:onButtonRelease(function(arg_12_0)
		var_8_0:setScale(1)

		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_1 == false and arg_8_0.decreaseCurrentNum then
			arg_8_0:decreaseCurrentNum()
		end
	end)

	local var_8_2 = cc.ui.UIPushButton.new({
		pressed = "windows/lvbu/sure_exchange/btn_add.png",
		disabled = "windows/lvbu/sure_exchange/btn_add.png",
		normal = "windows/lvbu/sure_exchange/btn_add.png"
	})

	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setScale(1, 1)
	var_8_2:addTo(arg_8_0:nodeByName("increase_pos"))
	var_8_2:setName("jiadian")

	local var_8_3 = false

	var_8_2:onButtonPressed(function(arg_13_0)
		var_8_2:setScale(0.9)

		local var_13_0 = 0

		local function var_13_1()
			var_13_0 = var_13_0 + 0.03

			if arg_8_0.addCurrentNum then
				arg_8_0:addCurrentNum()
			end
		end

		local function var_13_2()
			var_13_0 = var_13_0 + 0.1

			if var_13_0 > 0.5 and var_13_0 <= 4 then
				var_8_3 = true

				if arg_8_0.addCurrentNum then
					arg_8_0:addCurrentNum()
				end
			elseif var_13_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_13_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_3 = false
			end
		end

		var_8_3 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_13_2, 0.1)
	end)
	var_8_2:onButtonRelease(function(arg_16_0)
		var_8_2:setScale(1)

		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_3 == false and arg_8_0.addCurrentNum then
			arg_8_0:addCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("max_button"), nil, function()
		xyd.playButtonSound()

		arg_8_0.buyNum = arg_8_0.canBuyNum

		arg_8_0:updateNum()
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("exchange_btn"), nil, function()
		xyd.playButtonSound()

		if arg_8_0.backpack:getItemNumByID(arg_8_0.itemID) >= xyd.tables.item:stack(arg_8_0.itemID) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("SHOP_BACKPACK_IS_FULL")
			})

			return
		elseif arg_8_0.buyNum == 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("BUY_NUM_LESS_THAN_ONE")
			})

			return
		end

		if arg_8_0.id == 2 then
			local var_18_0 = {
				id = math.max(1, arg_8_0.lvbuspStage),
				num = arg_8_0.buyNum
			}

			arg_8_0.lvbuFestival:exchangeLvbusp(var_18_0, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					if arg_19_1 and arg_19_1.awards then
						dump(arg_19_1)

						local var_19_0 = arg_8_0:summaryAwards(arg_19_1.awards)

						arg_8_0.selfPlayer:handleRewards(var_19_0)
					end

					xyd.WindowManager.get():closeWindow(arg_8_0)
				end
			end)
		else
			local var_18_1 = {
				id = arg_8_0.id,
				num = arg_8_0.buyNum
			}

			arg_8_0.lvbuFestival:exchangeItems(var_18_1, function(arg_20_0, arg_20_1)
				if arg_20_0 == xyd.error.OK then
					if arg_20_1 and arg_20_1.awards then
						local var_20_0 = arg_8_0:summaryAwards(arg_20_1.awards)

						arg_8_0.selfPlayer:handleRewards(var_20_0)
					end

					xyd.WindowManager.get():closeWindow(arg_8_0)
				end
			end)
		end
	end)
end

function var_0_0.summaryAwards(arg_21_0, arg_21_1)
	local var_21_0 = {}
	local var_21_1 = 0

	for iter_21_0 = 1, #arg_21_1 do
		if arg_21_1[iter_21_0].table_id == -1 and arg_21_1[iter_21_0].mana and arg_21_1[iter_21_0].mana > 0 then
			var_21_1 = var_21_1 + arg_21_1[iter_21_0].mana
		elseif arg_21_1[iter_21_0].table_id > 0 then
			var_21_0[arg_21_1[iter_21_0].table_id] = (var_21_0[arg_21_1[iter_21_0].table_id] or 0) + (arg_21_1[iter_21_0].item_num or 0)
		end
	end

	local var_21_2 = {}

	for iter_21_1, iter_21_2 in pairs(var_21_0) do
		table.insert(var_21_2, {
			table_id = iter_21_1,
			item_num = iter_21_2
		})
	end

	if var_21_1 > 0 then
		table.insert(var_21_2, {
			table_id = -1,
			mana = var_21_1,
			item_num = var_21_1
		})
	end

	return var_21_2
end

function var_0_0.didClose(arg_22_0)
	if arg_22_0.handler then
		if arg_22_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_22_0.handler[1])
		end

		if arg_22_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_22_0.handler[2])
		end
	end

	local var_22_0 = xyd.WindowManager.get():getWindow("lvbu_shop")

	if var_22_0 and var_22_0.list then
		local var_22_1 = var_22_0.scrollNodePosY

		var_22_0.list:reload()
		var_22_0.list.scrollNode:setPositionY(var_22_1)

		var_22_0.scrollNodePosY = 0
	end
end

return var_0_0
