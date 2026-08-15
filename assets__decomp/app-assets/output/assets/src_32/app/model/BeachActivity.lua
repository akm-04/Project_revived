local var_0_0 = class("BeachActivity", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.bossHp = 0
	arg_1_0.matrixID = 0
	arg_1_0.bossAttackTimes = {}
	arg_1_0.bossID = 0
	arg_1_0.buyAttackTimes = 0
	arg_1_0.buyCritTimes = 0
	arg_1_0.canAttackTimes = 0
	arg_1_0.isStarting = 0
	arg_1_0.startTimes = 0
	arg_1_0.bossChange = false
	arg_1_0.endTime = 0
	arg_1_0.points = 0
	arg_1_0.awardStepNormal = 0
	arg_1_0.awardStepSpecial = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.startBeach(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.START_BEACH, {}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_4_1 then
			if arg_4_1.boss_hp then
				arg_3_0.bossHp = arg_4_1.boss_hp
			end

			if arg_4_1.boss_card_index then
				arg_3_0.matrixID = arg_4_1.boss_card_index
			end

			if arg_4_1.boss_attack_times then
				arg_3_0.bossAttackTimes = arg_4_1.boss_attack_times
			end

			if arg_4_1.boss_index then
				arg_3_0.bossID = arg_4_1.boss_index
			end

			if arg_4_1.buy_attack_times then
				arg_3_0.buyAttackTimes = arg_4_1.buy_attack_times
			end

			if arg_4_1.buy_critical_times then
				arg_3_0.buyCritTimes = arg_4_1.buy_critical_times
			end

			if arg_4_1.can_attack_times then
				arg_3_0.canAttackTimes = arg_4_1.can_attack_times
			end

			if arg_4_1.is_fighting then
				arg_3_0.isStarting = arg_4_1.is_fighting
			end

			if arg_4_1.play_times then
				arg_3_0.startTimes = arg_4_1.play_times
			end

			if arg_4_1.awards then
				arg_3_0.awards = arg_4_1.awards
			end

			if arg_4_1.points then
				arg_3_0.points = arg_4_1.points
			end

			if arg_4_1.award_step_n then
				arg_3_0.awardStepNormal = arg_4_1.award_step_n
			end

			if arg_4_1.award_step_s then
				arg_3_0.awardStepSpecial = arg_4_1.award_step_s
			end
		end

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.setParams(arg_5_0, arg_5_1)
	if arg_5_1 then
		if arg_5_1.boss_hp then
			if arg_5_0.bossHp ~= arg_5_1.boss_hp and arg_5_1.boss_hp <= 0 then
				arg_5_0.bossChange = true
			else
				arg_5_0.bossChange = false
			end

			arg_5_0.bossHp = arg_5_1.boss_hp
		end

		if arg_5_1.boss_card_index then
			arg_5_0.matrixID = arg_5_1.boss_card_index
		end

		if arg_5_1.boss_attack_times then
			arg_5_0.bossAttackTimes = arg_5_1.boss_attack_times
		end

		if arg_5_1.boss_index then
			if arg_5_0.bossID ~= arg_5_1.boss_index then
				arg_5_0.bossChange = true
			else
				arg_5_0.bossChange = false
			end

			arg_5_0.bossID = arg_5_1.boss_index
		end

		if arg_5_1.buy_attack_times then
			arg_5_0.buyAttackTimes = arg_5_1.buy_attack_times
		end

		if arg_5_1.buy_critical_times then
			arg_5_0.buyCritTimes = arg_5_1.buy_critical_times
		end

		if arg_5_1.can_attack_times then
			arg_5_0.canAttackTimes = arg_5_1.can_attack_times
		end

		if arg_5_1.is_fighting then
			arg_5_0.isStarting = arg_5_1.is_fighting
		end

		if arg_5_1.play_times then
			arg_5_0.startTimes = arg_5_1.play_times
		end

		if arg_5_1.awards then
			arg_5_0.awards = arg_5_1.awards
		end

		if arg_5_1.end_time then
			arg_5_0.endTime = arg_5_1.end_time
		end

		if arg_5_1.points then
			arg_5_0.points = arg_5_1.points
		end

		if arg_5_1.award_step_n then
			arg_5_0.awardStepNormal = arg_5_1.award_step_n
		end

		if arg_5_1.award_step_s then
			arg_5_0.awardStepSpecial = arg_5_1.award_step_s
		end
	end
end

function var_0_0.getBeachActivityInfo(arg_6_0, arg_6_1)
	xyd.Backend.get():request(xyd.mid.GET_REARENA_INFO, {}, function(arg_7_0, arg_7_1)
		if arg_6_1 then
			arg_6_1(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.attack(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1 or {}

	xyd.Backend.get():request(xyd.mid.BEACH_ATTACK, var_8_0, function(arg_9_0, arg_9_1)
		if arg_8_2 then
			arg_8_2(arg_9_0, arg_9_1)
		end
	end)
end

function var_0_0.buyCrit(arg_10_0, arg_10_1)
	xyd.Backend.get():request(xyd.mid.BUY_CRIT, {}, function(arg_11_0, arg_11_1)
		if arg_10_1 then
			arg_10_1(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.getPointAward(arg_12_0, arg_12_1)
	xyd.Backend.get():request(xyd.mid.BEACH_POINT_AWARD, {}, function(arg_13_0, arg_13_1)
		if arg_13_1 and arg_12_1 then
			arg_12_1(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.buyPoint(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.BEACH_POINT_BUY, var_14_0, function(arg_15_0, arg_15_1)
		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.buyAttack(arg_16_0, arg_16_1)
	xyd.Backend.get():request(xyd.mid.BUY_ATTACK_TIMES, {}, function(arg_17_0, arg_17_1)
		if arg_16_1 then
			arg_16_1(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.giveUpGame(arg_18_0, arg_18_1)
	xyd.Backend.get():request(xyd.mid.BEACH_GIVE_UP, {}, function(arg_19_0, arg_19_1)
		if arg_18_1 then
			arg_18_1(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.getBossHp(arg_20_0)
	return arg_20_0.bossHp
end

function var_0_0.isGameOver(arg_21_0)
	if arg_21_0.bossID == xyd.tables.beachBoss:getBossCount() and arg_21_0.bossHp <= 0 then
		return true
	end

	return false
end

function var_0_0.getMatrixID(arg_22_0)
	if not arg_22_0.matrixID or arg_22_0.matrixID <= 0 then
		arg_22_0.matrixID = 1
	end

	return arg_22_0.matrixID
end

function var_0_0.getBossAttackTimes(arg_23_0)
	return arg_23_0.bossAttackTimes
end

function var_0_0.getBossID(arg_24_0)
	return arg_24_0.bossID
end

function var_0_0.getCanAttackTimes(arg_25_0)
	return arg_25_0.canAttackTimes
end

function var_0_0.getPoints(arg_26_0)
	return arg_26_0.points
end

function var_0_0.getAwardStepNormal(arg_27_0)
	return arg_27_0.awardStepNormal
end

function var_0_0.getAwardStepSpecial(arg_28_0)
	return arg_28_0.awardStepSpecial
end

function var_0_0.isStart(arg_29_0)
	if arg_29_0.isStarting == 1 then
		return true
	else
		return false
	end
end

function var_0_0.getStartTimes(arg_30_0)
	return arg_30_0.startTimes
end

function var_0_0.getEndTime(arg_31_0)
	return arg_31_0.endTime
end

function var_0_0.getBuyAttackTimes(arg_32_0)
	return arg_32_0.buyAttackTimes
end

function var_0_0.getBuyCritTimes(arg_33_0)
	return arg_33_0.buyCritTimes
end

function var_0_0.isBossChange(arg_34_0)
	return arg_34_0.bossChange
end

function var_0_0.getAwards(arg_35_0)
	if arg_35_0.awards and next(arg_35_0.awards) then
		return arg_35_0.awards
	end

	return nil
end

function var_0_0.clearAward(arg_36_0)
	arg_36_0.awards = {}
end

return var_0_0
