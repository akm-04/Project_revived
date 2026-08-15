local var_0_0 = class("NianBoss", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.NIAN_BOSS, handler(arg_2_0, arg_2_0.onNianBoss_))
end

function var_0_0.onNianBoss_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.total_damage = math.floor(var_3_0.total_hurt)
	arg_3_0.total_rank = var_3_0.total_rank
	arg_3_0.challenge_times = var_3_0.challenge_times
	arg_3_0.boss_brave = var_3_0.boss_info.boss_brave

	if arg_3_0.boss_brave > 1000000 then
		arg_3_0.boss_brave = 1000000
	end

	arg_3_0.boss_id = tonumber(var_3_0.boss_info.boss_id)
	arg_3_0.can_sweep = var_3_0.can_sweep
	arg_3_0.model_id = xyd.tables.nianBoss:modelID(arg_3_0.boss_id)
	arg_3_0.monster_id = xyd.tables.nianBoss:monsterID(arg_3_0.boss_id)
	arg_3_0.buyBossTimes = var_3_0.buy_times
	arg_3_0.fireNum = var_3_0.boss_info.fire_num
	arg_3_0.period = var_3_0.boss_info.period
	arg_3_0.top_info = var_3_0.top_info
end

function var_0_0.getNianModel(arg_4_0)
	local var_4_0 = xyd.HeroAnimation.new(arg_4_0.monster_id, arg_4_0.model_id, xyd.tables.model:uiScale(arg_4_0.model_id), {})

	if var_4_0 then
		var_4_0:idle()
	end

	return var_4_0
end

function var_0_0.loadNianBoss(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.NIAN_BOSS, {}, function(arg_6_0, arg_6_1)
		arg_5_1(arg_6_0)
	end)
end

function var_0_0.buyTimes(arg_7_0, arg_7_1)
	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_BUY_TIMES, {}, function(arg_8_0, arg_8_1)
		arg_7_0.challenge_times = arg_8_1.challenge_times
		arg_7_0.buyBossTimes = arg_8_1.buy_times

		arg_7_1(arg_8_0)
	end)
end

function var_0_0.doSweep(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_SWEEP, arg_9_1, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.challenge_times = arg_9_0.challenge_times - 1
			arg_9_0.total_rank = arg_10_1.total_rank
			arg_9_0.total_damage = math.floor(tonumber(arg_10_1.boss_info.total_hurt))
			arg_9_0.the_damage = math.floor(tonumber(arg_10_1.boss_info.damage))
			arg_9_0.perpose = arg_10_1.boss_info.pre_info

			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getThiefRank(arg_11_0, arg_11_1)
	xyd.Backend.get():request(xyd.mid.THIEF_BOSS_RANK, {}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_1(arg_12_0, arg_12_1)
		end
	end)
end

return var_0_0
