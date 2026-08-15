local var_0_0 = class("MagicShop", import(".BaseModel"))
local var_0_1 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_MAGIC_SHOP, handler(arg_2_0, arg_2_0.onMagicShopInfo_))
	arg_2_0:registerEvent(xyd.event.SHOP_MAGIC_BUY, handler(arg_2_0, arg_2_0.onMagicShopBuy_))
	arg_2_0:registerEvent(xyd.event.SHOP_MAGIC_REFRESH, handler(arg_2_0, arg_2_0.onMagicShopRefresh_))
	arg_2_0:registerEvent(xyd.event.SHOP_MAGIC_UNLOCK, handler(arg_2_0, arg_2_0.onMagicUnlock_))
end

function var_0_0.loadShopInfo(arg_3_0, arg_3_1)
	if arg_3_0.isLoaded and arg_3_0.nextRefreshTime and arg_3_0.nextRefreshTime > xyd.ServerTime.get():getServerTime() then
		arg_3_1(xyd.error.OK)

		return
	end

	xyd.Backend.get():request(xyd.mid.LOAD_MAGIC_SHOP, {}, function(arg_4_0)
		arg_3_1(arg_4_0)
	end, {}, false, true)
end

function var_0_0.buy(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.SHOP_MAGIC_BUY, {
		pos = arg_5_1
	}, function(arg_6_0)
		arg_5_2(arg_6_0)
	end)
end

function var_0_0.refresh(arg_7_0, arg_7_1)
	xyd.Backend.get():request(xyd.mid.SHOP_MAGIC_REFRESH, {}, function(arg_8_0)
		arg_7_1(arg_8_0)
	end, {}, true, true)
end

function var_0_0.unlock(arg_9_0, arg_9_1)
	xyd.Backend.get():request(xyd.mid.SHOP_MAGIC_UNLOCK, {}, function(arg_10_0)
		arg_9_1(arg_10_0)
	end)
end

function var_0_0.onMagicShopInfo_(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.params

	arg_11_0.nextRefreshTime = xyd.ServerTime.get():getServerTime() + var_11_0.left_time
	arg_11_0.isLoaded = true
	arg_11_0.items = {}

	for iter_11_0, iter_11_1 in pairs(var_11_0.items) do
		arg_11_0.items[iter_11_1.table_id] = iter_11_1
	end

	arg_11_0.noticeHandler = var_0_1.scheduleGlobal(function()
		var_0_1.unscheduleGlobal(arg_11_0.noticeHandler)

		if xyd.WindowManager.get():isWindowOpen("shop") then
			return
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.SHOP_CAN_REFRESH
		})
	end, var_11_0.left_time)
end

function var_0_0.onMagicShopBuy_(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_1.params

	if var_13_0.pos and arg_13_0.items and arg_13_0.items[var_13_0.pos] then
		arg_13_0.items[var_13_0.pos].is_bought = 1

		local var_13_1 = var_13_0.pos
		local var_13_2 = arg_13_0:getItemType(var_13_1)

		if arg_13_0.items[var_13_1] == nil then
			return
		end

		local var_13_3 = arg_13_0.items[var_13_1].item
		local var_13_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if var_13_2 == xyd.ItemType.UNKOWN then
			return
		elseif var_13_2 == xyd.ItemType.RUNE then
			var_13_3.rune_id = var_13_0.rune_id

			if var_13_4.runeBagLoaded_ and var_13_4:getRuneBag() then
				var_13_4:getRuneBag():addRuneWithRuneInfo(var_13_3)
			end
		elseif var_13_2 == xyd.ItemType.HERO then
			if var_13_4.herosLoaded_ then
				var_13_3.partner_id = var_13_0.partner_id
				var_13_3.player_id = var_13_4.playerID

				var_13_4:addHeroWithHeroInfo(var_13_3)
			end
		elseif var_13_2 == xyd.ItemType.SCROLL and var_13_4.scrollsLoaded_ then
			var_13_4.scrolls_[var_13_3.table_id] = (var_13_4.scrolls_[var_13_3.table_id] or 0) + 1
		end
	end
end

function var_0_0.onMagicShopRefresh_(arg_14_0, arg_14_1)
	arg_14_0:onMagicShopInfo_(arg_14_1)
end

function var_0_0.onMagicUnlock_(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_1.params.item

	arg_15_0.items[var_15_0.table_id] = var_15_0
end

function var_0_0.getItemType(arg_16_0, arg_16_1)
	if arg_16_0.items == nil or arg_16_0.items[arg_16_1] == nil then
		return xyd.ItemType.UNKOWN
	end

	return arg_16_0.items[arg_16_1].item_type
end

function var_0_0.getItemIcon(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0:getItemType(arg_17_1)

	if var_17_0 == xyd.ItemType.UNKOWN or arg_17_0.items[arg_17_1].is_bought == 1 then
		return nil
	elseif var_17_0 == xyd.ItemType.RUNE then
		local var_17_1 = arg_17_0.items[arg_17_1].item.table_id

		return xyd.tables.rune:getRuneImage(var_17_1)
	elseif var_17_0 == xyd.ItemType.HERO then
		local var_17_2 = arg_17_0.items[arg_17_1].item
		local var_17_3 = var_17_2.table_id
		local var_17_4 = var_17_2.star

		return xyd.tables.hero:avatar(var_17_3, var_17_4)
	elseif var_17_0 == xyd.ItemType.SCROLL then
		local var_17_5 = arg_17_0.items[arg_17_1].item.table_id

		return xyd.tables.scroll:icon(var_17_5)
	end
end

function var_0_0.getItemID(arg_18_0, arg_18_1)
	if arg_18_0.items[arg_18_1] == nil or arg_18_0.items[arg_18_1].item == nil or arg_18_0.items[arg_18_1].item.table_id == nil then
		return 0
	else
		return arg_18_0.items[arg_18_1].item.table_id
	end
end

function var_0_0.getItemName(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0:getItemType(arg_19_1)

	if var_19_0 == xyd.ItemType.UNKOWN then
		return nil
	elseif var_19_0 == xyd.ItemType.RUNE then
		local var_19_1 = arg_19_0.items[arg_19_1].item.table_id

		return xyd.tables.rune:getMainName(var_19_1)
	elseif var_19_0 == xyd.ItemType.HERO then
		local var_19_2 = arg_19_0.items[arg_19_1].item
		local var_19_3 = var_19_2.table_id
		local var_19_4 = var_19_2.star

		return xyd.tables.hero:name(var_19_3)
	elseif var_19_0 == xyd.ItemType.SCROLL then
		local var_19_5 = arg_19_0.items[arg_19_1].item.table_id

		return xyd.tables.scroll:name(var_19_5)
	end
end

return var_0_0
