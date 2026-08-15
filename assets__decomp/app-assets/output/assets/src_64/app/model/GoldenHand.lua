local var_0_0 = class("GoldenHand", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.vipTable = xyd.tables.vip
	arg_1_0.coinNum = {}
	arg_1_0.crit = {}
	arg_1_0.diamond = {}
	arg_1_0.buyManaTimes = {}
end

function var_0_0.onRegister(arg_2_0)
	print("on registering GoldenHand")
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.USE_GOLDEN_HAND, handler(arg_2_0, arg_2_0.onUseGoldenHand_))
	arg_2_0:registerEvent(xyd.event.TENFOLD_GOLDEN_HAND, handler(arg_2_0, arg_2_0.onUseTenfoldGoldenHand_))
end

function var_0_0.onUseGoldenHand_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.coinNum = var_3_0.mana
	arg_3_0.crit = var_3_0.crit
	arg_3_0.diamond = var_3_0.cost
	arg_3_0.buyManaTimes = var_3_0.buy_mana_times
end

function var_0_0.useGoldenHand(arg_4_0, arg_4_1)
	xyd.Backend.get():request(xyd.mid.USE_GOLDEN_HAND, {}, function(arg_5_0)
		arg_4_1(arg_5_0)
	end, {}, false, true)
end

function var_0_0.useTenfoldGoldenHand(arg_6_0, arg_6_1)
	local var_6_0 = {
		consume_id = xyd.DailyConsumeType.Gold
	}

	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, var_6_0, function(arg_7_0)
		arg_6_1(arg_7_0)
	end, {}, false, true)
end

function var_0_0.onUseTenfoldGoldenHand_(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.params

	if var_8_0.consume_id == xyd.DailyConsumeType.Gold then
		arg_8_0.coinNum = var_8_0.mana
		arg_8_0.crit = var_8_0.crit
		arg_8_0.diamond = var_8_0.cost
	end
end

function var_0_0.checkTenfoldUseTimes(arg_9_0, arg_9_1)
	xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME_LOAD, {}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_1(arg_10_1)
		end
	end, {}, false, true)
end

return var_0_0
