local var_0_0 = class("WorldBoss", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.WORLD_BOSS, handler(arg_2_0, arg_2_0.onWorldBoss_))
end

function var_0_0.onWorldBoss_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.total_damage = math.floor(var_3_0.total_hurt)
	arg_3_0.total_rank = var_3_0.total_rank
	arg_3_0.challenge_times = var_3_0.challenge_times
	arg_3_0.boss_brave = var_3_0.boss_info.boss_brave
	arg_3_0.boss_id = var_3_0.boss_info.current_boss or var_3_0.boss_info.boss_id
	arg_3_0.can_sweep = var_3_0.can_sweep
	arg_3_0.model_id = xyd.tables.worldBoss.model_id[arg_3_0.boss_id]
	arg_3_0.monster_id = xyd.tables.worldBoss.monster_id[arg_3_0.boss_id]
	arg_3_0.buyBossTimes = var_3_0.buy_times
end

function var_0_0.loadWorldBoss(arg_4_0, arg_4_1, arg_4_2)
	xyd.Backend.get():request(xyd.mid.WORLD_BOSS, {}, function(arg_5_0)
		arg_4_1(arg_5_0)
	end, nil, false, arg_4_2)
end

function var_0_0.buyTimes(arg_6_0, arg_6_1)
	xyd.Backend.get():request(xyd.mid.WORLD_BOSS_BUY_TIMES, {}, function(arg_7_0)
		arg_6_1(arg_7_0)
	end)
end

function var_0_0.doSweep(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.WORLD_BOSS_SWEEP, arg_8_1, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.challenge_times = arg_8_0.challenge_times - 1
			arg_8_0.total_rank = arg_9_1.total_rank
			arg_8_0.total_damage = math.floor(tonumber(arg_9_1.total_hurt))
			arg_8_0.the_damage = math.floor(tonumber(arg_9_1.damage))
			arg_8_0.perpose = arg_9_1.pre_info

			arg_8_2(arg_9_0)
		end
	end)
end

return var_0_0
