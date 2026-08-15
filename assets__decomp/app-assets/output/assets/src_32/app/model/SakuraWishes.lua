local var_0_0 = class("SakuraWishes", import(".BaseModel"))
local var_0_1 = xyd.Activities.SAKURA_WISHES

function var_0_0.ctor(arg_1_0, ...)
	return
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity({
		activity_id = var_0_1
	}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.activity = arg_4_1

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.summonOne(arg_5_0, arg_5_1)
	local var_5_0 = {}

	var_5_0.award_id = 1

	xyd.Backend.get():request(xyd.mid.ACTIVITY_1151_AWARD, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_1 then
			arg_5_1(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.summonTen(arg_7_0, arg_7_1)
	local var_7_0 = {}

	var_7_0.award_id = 2

	xyd.Backend.get():request(xyd.mid.ACTIVITY_1151_AWARD, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_1 then
			arg_7_1(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.summonOneTicket(arg_9_0, arg_9_1)
	local var_9_0 = {}

	var_9_0.award_id = 3

	xyd.Backend.get():request(xyd.mid.ACTIVITY_1151_AWARD, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.summonTenTicket(arg_11_0, arg_11_1)
	local var_11_0 = {}

	var_11_0.award_id = 4

	xyd.Backend.get():request(xyd.mid.ACTIVITY_1151_AWARD, var_11_0, function(arg_12_0, arg_12_1)
		if arg_11_1 then
			arg_11_1(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.summonSuperRare(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.SAKURA_WISHES_SUPER_BONUS, {}, function(arg_14_0, arg_14_1)
		if arg_13_1 then
			arg_13_1(arg_14_0, arg_14_1)
		end
	end)
end

return var_0_0
