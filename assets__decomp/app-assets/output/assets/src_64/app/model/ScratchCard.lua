local var_0_0 = class("ScratchCard", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.shuffleScratchCard(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.SHUFFLE_SCRATCH_CARD, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.changeCardsGroup(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.CHANGE_CARDS_GROUP, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.buyLuckyCoins(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_LUCKY_COINS, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.changeAutoStatus(arg_9_0, arg_9_1)
	local var_9_0 = {}

	xyd.Backend.get():request(xyd.mid.CHANGE_AUTO_STATUS, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

return var_0_0
