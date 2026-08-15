local var_0_0 = class("Market")
local var_0_1 = import("framework.scheduler")
local var_0_2 = class("Market", import(".BaseModel"))

function var_0_2.ctor(arg_1_0, ...)
	var_0_2.super.ctor(arg_1_0, ...)

	arg_1_0.gloryIDs = {}
	arg_1_0.normalIDs = {}
	arg_1_0.specialIDs = {}
end

function var_0_2.onRegister(arg_2_0)
	var_0_2.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_MARKET, handler(arg_2_0, arg_2_0.onMarketInfo_))
	arg_2_0:registerEvent(xyd.event.MARKET_BUY, handler(arg_2_0, arg_2_0.onMarketBuy_))
end

function var_0_2.loadMarketInfo(arg_3_0, arg_3_1)
	if arg_3_0.isLoaded then
		arg_3_1(xyd.error.OK)
	else
		xyd.Backend.get():request(xyd.mid.LOAD_MARKET, {}, function(arg_4_0)
			arg_3_0.isLoaded = true

			arg_3_1(arg_4_0)
		end)
	end
end

function var_0_2.buy(arg_5_0, arg_5_1, arg_5_2)
	xyd.Backend.get():request(xyd.mid.MARKET_BUY, {
		table_id = arg_5_1
	}, function(arg_6_0)
		arg_5_2(arg_6_0)
	end)
end

function var_0_2.getMarketInfos(arg_7_0, arg_7_1)
	if arg_7_1 == xyd.MarketType.GLORY then
		return arg_7_0.gloryIDs
	elseif arg_7_1 == xyd.MarketType.NORMAL then
		return arg_7_0.normalIDs
	elseif arg_7_1 == xyd.MarketType.SPECIAL then
		return arg_7_0.specialIDs
	end
end

function var_0_2.getMarketInfo(arg_8_0, arg_8_1)
	local var_8_0 = xyd.tables.shop:getType(arg_8_1)

	return arg_8_0:getMarketInfos(var_8_0)[arg_8_1]
end

function var_0_2.onMarketInfo_(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1.params

	for iter_9_0, iter_9_1 in pairs(var_9_0.list) do
		local var_9_1 = tonumber(iter_9_1.table_id)
		local var_9_2 = xyd.tables.shop:getType(var_9_1)

		if var_9_2 == xyd.MarketType.GLORY then
			arg_9_0.gloryIDs[var_9_1] = iter_9_1
		elseif var_9_2 == xyd.MarketType.NORMAL then
			arg_9_0.normalIDs[var_9_1] = iter_9_1
		elseif var_9_2 == xyd.MarketType.SPECIAL then
			arg_9_0.specialIDs[var_9_1] = iter_9_1
		end

		if iter_9_1.expire_time and (arg_9_0.expireTime == nil or arg_9_0.expireTime > iter_9_1.expire_time and arg_9_0.expireTime > xyd.ServerTime.get():getServerTime()) then
			arg_9_0.expireTime = iter_9_1.expire_time
		end
	end

	if arg_9_0.expireHandler and arg_9_0.expireTime then
		var_0_1.unscheduleGlobal(arg_9_0.expireHandler)

		arg_9_0.expireHandler = var_0_1.scheduleGlobal(function(arg_10_0)
			arg_9_0.isLoaded = false
		end, arg_9_0.expireTime - xyd.ServerTime.get():getServerTime())
	end
end

function var_0_2.onMarketBuy_(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.params.table_id
	local var_11_1 = arg_11_0:getMarketInfo(var_11_0).num or 0

	arg_11_0:getMarketInfo(var_11_0).num = var_11_1 + 1
	arg_11_0:getMarketInfo(var_11_0).created_time = xyd.ServerTime.get():getServerTime()

	if arg_11_1.params.expire_time and arg_11_1.params.expire_time < (arg_11_0.expire_time or 0) and arg_11_0.expireHandler and arg_11_0.expireTime then
		var_0_1.unscheduleGlobal(arg_11_0.expireHandler)

		arg_11_0.expireHandler = var_0_1.scheduleGlobal(function(arg_12_0)
			arg_11_0.isLoaded = false
		end, arg_11_0.expireTime - xyd.ServerTime.get():getServerTime())
	end
end

return var_0_2
