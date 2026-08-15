local var_0_0 = class("Shop", import(".BaseModel"))
local var_0_1 = xyd.tables.shop

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.items_ = {}
	arg_1_0.refreshTimes_ = {}
	arg_1_0.openTimes_ = {}
	arg_1_0.statuses_ = {}
	arg_1_0.openList_ = {}
	arg_1_0.guildOpenList_ = {}
	arg_1_0.hotHero_ = {}
	arg_1_0.ownSkin_ = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_SHOP_LIST, handler(arg_2_0, arg_2_0.onShopList_))
	arg_2_0:registerEvent(xyd.event.OPEN_SHOP_TYPE, handler(arg_2_0, arg_2_0.onOpenShop_))
	arg_2_0:registerEvent(xyd.event.CLOSE_SHOP_TYPE, handler(arg_2_0, arg_2_0.onCloseShop_))
	arg_2_0:registerEvent(xyd.event.LOAD_SHOP, handler(arg_2_0, arg_2_0.onShopInfo_))
	arg_2_0:registerEvent(xyd.event.REFRESH_SHOP, handler(arg_2_0, arg_2_0.onShopRefresh_))
	arg_2_0:registerEvent(xyd.event.BUY_SHOP, handler(arg_2_0, arg_2_0.onShopBuy_))
	arg_2_0:registerEvent(xyd.event.BUY_SHOP_MULTI, handler(arg_2_0, arg_2_0.onShopMultiBuy_))
	arg_2_0:registerEvent(xyd.event.UPDATE_SHOP_ONTIME, handler(arg_2_0, arg_2_0.updateShopOntime_))
end

function var_0_0.loadSkinShopInfo(arg_3_0, arg_3_1, arg_3_2)
	xyd.Backend.get():request(xyd.mid.SKIN_SHOP_INFO, {}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_2(arg_4_0)
		end
	end)
end

function var_0_0.getSkinInfo(arg_5_0)
	return arg_5_0.ownSkin_
end

function var_0_0.loadShopList(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.LOAD_SHOP_LIST, arg_6_1, function(arg_7_0, arg_7_1)
		arg_6_2(arg_7_0)
	end)
end

function var_0_0.loadShopInfo(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_0:isLoaded(arg_8_1.shop_type) == true and arg_8_0:canAutoRefresh(arg_8_1.shop_type) == false then
		arg_8_2(xyd.error.OK)

		return
	end

	xyd.Backend.get():request(xyd.mid.LOAD_SHOP, arg_8_1, function(arg_9_0)
		arg_8_2(arg_9_0)
	end, {}, false, true)
end

function var_0_0.refreshShop(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.REFRESH_SHOP, arg_10_1, function(arg_11_0)
		arg_10_2(arg_11_0)
	end, {}, true, true)
end

function var_0_0.buy(arg_12_0, arg_12_1, arg_12_2)
	xyd.Backend.get():request(xyd.mid.BUY_SHOP, arg_12_1, function(arg_13_0)
		arg_12_2(arg_13_0)
	end)
end

function var_0_0.buyMulti(arg_14_0, arg_14_1, arg_14_2)
	xyd.Backend.get():request(xyd.mid.BUY_SHOP_MULTI, arg_14_1, function(arg_15_0)
		arg_14_2(arg_15_0)
	end)
end

function var_0_0.onShopInfo_(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_1.params
	local var_16_1 = var_16_0.shop_type

	arg_16_0.refreshTimes_[var_16_1] = var_16_0.refresh_times
	arg_16_0.items_[var_16_1] = {}
	arg_16_0.openTimes_[var_16_1] = var_16_0.open_time
	arg_16_0.statuses_[var_16_1] = {
		loaded = false,
		open = var_16_0.is_open == 1,
		countDown = var_16_0.count_down == 1,
		refresh_time = tonumber(xyd.ServerTime.get():getSecondsOfDay())
	}

	for iter_16_0, iter_16_1 in pairs(var_16_0.items) do
		table.insert(arg_16_0.items_[var_16_1], iter_16_1)
	end

	arg_16_0.hotHero_[var_16_1] = {}
	arg_16_0.hotHero_[var_16_1].hot_hero = var_16_0.hot_hero
	arg_16_0.hotHero_[var_16_1].cost_stone = var_16_0.cost_stone
	arg_16_0.hotHero_[var_16_1].is_awarded = var_16_0.is_awarded

	if #arg_16_0.items_[var_16_1] > 0 then
		arg_16_0.statuses_[var_16_1].loaded = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.SHOP_COST_REFRESH
	})
end

function var_0_0.isCountDown(arg_17_0, arg_17_1)
	if arg_17_0.statuses_[arg_17_1].countDown and arg_17_0.statuses_[arg_17_1].open and arg_17_0.openTimes_[arg_17_1] then
		return true
	else
		return false
	end
end

function var_0_0.getLastTime(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0.openTimes_[arg_18_1]

	return xyd.ServerTime.get():getServerTime() - var_18_0
end

function var_0_0.onShopBuy_(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_1.params
	local var_19_1 = var_19_0.shop_type

	if var_19_1 == xyd.ShopType.COURSE then
		local var_19_2 = {}

		for iter_19_0, iter_19_1 in ipairs(arg_19_0.items_[var_19_1]) do
			if iter_19_1.index == var_19_0.index then
				local var_19_3 = {
					table_id = iter_19_1.item_id,
					item_num = iter_19_1.item_num
				}

				if var_19_3.table_id == -1 then
					var_19_3.crystal = iter_19_1.item_num
				end

				table.insert(var_19_2, var_19_3)
			end
		end

		xyd.WindowManager.get():openWindow("alert_award", {
			awards = var_19_2
		})
	end

	for iter_19_2, iter_19_3 in ipairs(arg_19_0.items_[var_19_1]) do
		if iter_19_3.index == var_19_0.index then
			local var_19_4 = (var_19_0.buy_times - iter_19_3.buy_times) * iter_19_3.item_num

			iter_19_3.isbuy = var_19_0.isbuy
			iter_19_3.buy_times = var_19_0.buy_times

			local var_19_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if var_19_5.backpackLoaded_ and var_19_5:getBackpack() then
				local var_19_6 = {
					itemID = iter_19_3.item_id,
					itemNum = var_19_4
				}

				var_19_5:getBackpack():addItem(var_19_6)
			end

			if iter_19_3.stone_id then
				local var_19_7 = {
					itemID = iter_19_3.stone_id,
					itemNum = iter_19_3.sell_price
				}
				local var_19_8 = xyd.tables.misc.spaceShopItem

				if iter_19_3.sell_type == xyd.currencyType.STONE and var_19_5:getBackpack():getItemNumByID(var_19_8) >= iter_19_3.sell_price then
					var_19_7.itemID = var_19_8
				end

				var_19_5:getBackpack():removeItem(var_19_7)
			end
		end
	end
end

function var_0_0.onShopMultiBuy_(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_1.params
	local var_20_1 = var_20_0.shop_type

	for iter_20_0, iter_20_1 in pairs(var_20_0.list) do
		if iter_20_1 then
			local var_20_2 = {
				index = iter_20_1,
				isbuy = arg_20_1.params.isbuy[iter_20_0],
				buy_times = arg_20_1.params.buy_times[iter_20_0],
				shop_type = var_20_1
			}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.BUY_SHOP,
				params = var_20_2,
				userdata = arg_20_1.userdata
			})
		end
	end
end

function var_0_0.updateShopOntime_(arg_21_0, arg_21_1)
	arg_21_0.statuses_ = {}
end

function var_0_0.onShopRefresh_(arg_22_0, arg_22_1)
	arg_22_0:onShopInfo_(arg_22_1)
end

function var_0_0.isLoaded(arg_23_0, arg_23_1)
	return arg_23_0.statuses_[arg_23_1] and arg_23_0.statuses_[arg_23_1].loaded
end

function var_0_0.canAutoRefresh(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0.statuses_[arg_24_1].refresh_time

	if var_24_0 == nil then
		return true
	end

	local var_24_1 = tonumber(xyd.ServerTime.get():getSecondsOfDay())
	local var_24_2 = var_0_1:nextRefreshTime(arg_24_1, var_24_0)

	if var_24_2 > 0 and var_24_2 < var_24_1 then
		return true
	else
		return false
	end
end

function var_0_0.isOpen(arg_25_0, arg_25_1)
	if arg_25_0.statuses_[arg_25_1] and arg_25_0.statuses_[arg_25_1].open == true then
		return true
	else
		return false
	end
end

function var_0_0.onOpenShop_(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_1.params

	if not var_26_0 or not next(var_26_0) then
		return
	end

	arg_26_0.statuses_[var_26_0.shopType] = {
		open = true,
		loaded = false,
		countDown = var_26_0.countDown or false
	}

	arg_26_0:updateOpenList()
	arg_26_0:loadShopInfo({
		shop_type = var_26_0.shopType
	}, function()
		return
	end)
end

function var_0_0.onCloseShop_(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_1.params

	if not var_28_0 or not next(var_28_0) then
		return
	end

	arg_28_0.statuses_[var_28_0.shopType] = {
		countDown = false,
		open = false,
		loaded = false
	}

	arg_28_0:updateOpenList()
end

function var_0_0.onShopList_(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_1.params

	if not var_29_0 or not next(var_29_0) then
		return
	end

	local var_29_1 = var_29_0.list

	if not var_29_1 or not next(var_29_1) then
		return
	end

	local var_29_2 = {}
	local var_29_3 = {}
	local var_29_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	local var_29_5 = var_29_4:getGuildChapterList()
	local var_29_6 = var_29_4:getGuildCampaigns()
	local var_29_7

	for iter_29_0, iter_29_1 in pairs(var_29_1) do
		if xyd.tables.shop:isTeamShop(tonumber(iter_29_1)) ~= 1 then
			if tonumber(iter_29_1) ~= xyd.ShopType.ACADEMY_ARENA then
				table.insert(var_29_2, tonumber(iter_29_1))
			end
		elseif var_29_5 and var_29_6 then
			local var_29_8 = var_29_5[xyd.tables.shop:teamDungeonHomologousIds()[tonumber(iter_29_1)]]

			if var_29_8.is_open == 1 and var_29_8.chapter_version == 2 and var_29_4:getJoinTime() < var_29_8.start_time then
				table.insert(var_29_3, tonumber(iter_29_1))
			end
		end
	end

	table.sort(var_29_2)
	table.sort(var_29_3)

	arg_29_0.openList_ = var_29_2
	arg_29_0.guildOpenList_ = var_29_3

	for iter_29_2, iter_29_3 in pairs(var_29_2) do
		if not arg_29_0.statuses_[iter_29_3] then
			arg_29_0.statuses_[iter_29_3] = {}
		end

		arg_29_0.statuses_[iter_29_3].open = true
	end
end

function var_0_0.getOpenNum(arg_30_0)
	return #arg_30_0.openList_
end

function var_0_0.getGuildOpenNum(arg_31_0)
	return #arg_31_0.guildOpenList_
end

function var_0_0.updateOpenList(arg_32_0)
	local var_32_0 = {}
	local var_32_1 = {}
	local var_32_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	local var_32_3 = var_32_2:getGuildChapterList()
	local var_32_4 = var_32_2:getGuildCampaigns()
	local var_32_5

	for iter_32_0, iter_32_1 in pairs(arg_32_0.statuses_) do
		if iter_32_1.open == true then
			if xyd.tables.shop:isTeamShop(iter_32_0) == 0 then
				table.insert(var_32_0, iter_32_0)
			elseif var_32_3 and var_32_4 then
				local var_32_6 = var_32_3[xyd.tables.shop:teamDungeonHomologousIds()[tonumber(iter_32_0)]]

				if var_32_6 and var_32_6.is_open == 1 and var_32_6.chapter_version == 2 and var_32_2:getJoinTime() < var_32_6.start_time then
					table.insert(var_32_1, tonumber(iter_32_0))
				end
			end
		end
	end

	table.sort(var_32_0)

	arg_32_0.openList_ = var_32_0
	arg_32_0.guildOpenList_ = var_32_1
end

function var_0_0.getOpenList(arg_33_0)
	return arg_33_0.openList_
end

function var_0_0.getGuildOpenList(arg_34_0)
	return arg_34_0.guildOpenList_
end

function var_0_0.getShownOpenList(arg_35_0)
	local var_35_0 = {}

	for iter_35_0, iter_35_1 in pairs(arg_35_0.openList_) do
		if iter_35_1 ~= xyd.ShopType.ARENA and iter_35_1 ~= xyd.ShopType.TOP and iter_35_1 ~= xyd.ShopType.MARCH and iter_35_1 ~= xyd.ShopType.GUILD and iter_35_1 ~= xyd.ShopType.HONOR and iter_35_1 ~= xyd.ShopType.REGION and iter_35_1 ~= xyd.ShopType.ILLUSION and iter_35_1 ~= xyd.ShopType.MAGIC and iter_35_1 ~= xyd.ShopType.TEATALK and iter_35_1 ~= xyd.ShopType.ACADEMY_ARENA and iter_35_1 ~= xyd.ShopType.SUMMON and iter_35_1 ~= xyd.ShopType.ULTRA_SKIN and iter_35_1 ~= xyd.ShopType.TUTOR and xyd.tables.shop:isTeamShop(iter_35_1) ~= 1 then
			table.insert(var_35_0, iter_35_1)
		end
	end

	return var_35_0
end

function var_0_0.closeShop(arg_36_0, arg_36_1)
	arg_36_0.statuses_[arg_36_1] = {
		countDown = false,
		open = false,
		loaded = false
	}

	arg_36_0:updateOpenList()
	xyd.Backend.get():request(xyd.mid.CLOSE_SHOP, {
		shop_type = arg_36_1
	}, function(arg_37_0)
		return
	end)
end

function var_0_0.buyExclusiveShop(arg_38_0, arg_38_1, arg_38_2)
	local var_38_0 = arg_38_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_EXCLUSIVE_SHOP, var_38_0, function(arg_39_0, arg_39_1)
		if arg_38_2 then
			arg_38_2(arg_39_0, arg_39_1)
		end
	end)
end

return var_0_0
