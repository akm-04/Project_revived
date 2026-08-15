local var_0_0 = class("AddEnergy", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.buyEnergyTimes = {}
	arg_1_0.buySpiritEnergyTimes = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	print("on registering AddEnergy")
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.ADD_ENERGY, handler(arg_2_0, arg_2_0.onAddEnergy_))
	arg_2_0:registerEvent(xyd.event.ADD_SPIRIT_ENERGY, handler(arg_2_0, arg_2_0.onAddSpiritEnergy_))
end

function var_0_0.onAddEnergy_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.buyEnergyTimes = var_3_0.buy_energy_times
	arg_3_0.selfPlayer.buyEnergyTimes = var_3_0.buy_energy_times

	xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):checkGiftByConditionIndex(4)
end

function var_0_0.onAddSpiritEnergy_(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.params

	arg_4_0.buySpiritEnergyTimes = var_4_0.buy_spirit_energy_times
	arg_4_0.selfPlayer.buySpiritEnergyTimes = var_4_0.buy_spirit_energy_times
end

function var_0_0.addEnergy(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.ADD_ENERGY, {}, function(arg_6_0)
		if arg_5_1 then
			arg_5_1(arg_6_0)
		end
	end, {}, true, true)
end

return var_0_0
