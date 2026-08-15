local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hetaihou", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 90
local var_0_7 = 90
local var_0_8 = 240
local var_0_9 = 0.8
local var_0_10 = {
	40010446,
	40010447
}
local var_0_11 = {
	40010437
}
local var_0_12 = {
	40010438
}
local var_0_13 = {
	40010439
}
local var_0_14 = {
	40010440
}
local var_0_15 = {
	100,
	200,
	300,
	500
}
local var_0_16 = {
	0.5,
	0.34,
	0.16
}
local var_0_17 = {
	0.35,
	0.7
}
local var_0_18 = {
	40010442,
	40010443,
	40010444
}
local var_0_19 = {
	40010766,
	40010767,
	40010768
}
local var_0_20 = {
	40010445,
	40010769
}
local var_0_21 = 10000582
local var_0_22 = 0.1
local var_0_23 = 0.004
local var_0_24 = 12

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("createAttack_info")
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energyCount_ = 0
	arg_2_0.energyEffectHeros_ = {}
	arg_2_0.energyStoneHeros_ = {}
	arg_2_0.energyKeyHp_ = {}
	arg_2_0.greenEffectEnemyHeros_ = {}
	arg_2_0.greenEffectSelfHeros_ = {}
	arg_2_0.greenEffectCount_ = 0
	arg_2_0.blueEffectEnemyHeros_ = {}
	arg_2_0.blueEffectSelfHeros_ = {}
	arg_2_0.blueEffectCount_ = 0
	arg_2_0.purpleHeroAttackNum_ = {}
	arg_2_0.purpleHero_ = {}
	arg_2_0.currentPurpleTarget_ = nil
	arg_2_0.isEnergying_ = false
	arg_2_0.energyEndCount_ = 0
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0.blueEffectCount_ = var_0_6
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0.greenEffectCount_ = var_0_7
	elseif arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energyCount_ = var_0_8
		arg_3_0.isEnergying_ = true

		arg_3_0:getFighterModel():playAnimation_("gongji05", true)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if arg_4_0.blueEffectCount_ > 0 then
		arg_4_0.blueEffectCount_ = arg_4_0.blueEffectCount_ - 1

		if arg_4_0.blueEffectCount_ <= 0 then
			arg_4_0:removeBlueEffectHerosBuff()
		elseif var_0_1.ctx.battle.count % 10 < 1 then
			arg_4_0:blueEffectJudge()
		end
	end

	if arg_4_0.greenEffectCount_ > 0 then
		arg_4_0.greenEffectCount_ = arg_4_0.greenEffectCount_ - 1

		if arg_4_0.greenEffectCount_ <= 0 then
			arg_4_0:removeGreenEffectHerosBuff()
		elseif var_0_1.ctx.battle.count % 10 < 1 then
			arg_4_0:greenEffectJudge()
		end
	end

	if not arg_4_0:isDeath() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("createAttack_info")) do
			if not iter_4_1:isDeath() and iter_4_1:getTeamType() ~= arg_4_0:getTeamType() and iter_4_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
				local var_4_0 = iter_4_1:getTableID()

				if arg_4_0.purpleHeroAttackNum_[var_4_0] then
					arg_4_0.purpleHeroAttackNum_[var_4_0] = arg_4_0.purpleHeroAttackNum_[var_4_0] + 1
				else
					arg_4_0.purpleHeroAttackNum_[var_4_0] = 1
					arg_4_0.purpleHero_[var_4_0] = iter_4_1
				end
			end
		end

		if var_0_1.ctx.battle.count % 10 < 1 then
			arg_4_0:purpleHeroJudge()
		end
	end

	if arg_4_0.energyCount_ > 0 then
		if arg_4_0.energyCount_ % 30 < 1 then
			local var_4_1 = {}

			for iter_4_2, iter_4_3 in ipairs(arg_4_0.sideTeam_) do
				if not iter_4_3:isDeath() and not iter_4_3:isAffected() and not arg_4_0.energyStoneHeros_[iter_4_3] then
					local var_4_2 = arg_4_0:getEnergyUpLevel(iter_4_3)

					if var_4_2 == 0 then
						if arg_4_0.energyEffectHeros_[iter_4_3] then
							var_0_0.table.removebyvalue(arg_4_0.energyEffectHeros_, iter_4_3)
						end
					elseif var_4_2 == 1 then
						arg_4_0:removeEnergyBuff(iter_4_3)

						arg_4_0.energyStoneHeros_[iter_4_3] = true
						arg_4_0.energyKeyHp_[iter_4_3] = arg_4_0:getKeyHp(iter_4_3)

						arg_4_0:addStoneBuff(iter_4_3)

						if arg_4_0.energyEffectHeros_[iter_4_3] then
							var_0_0.table.removebyvalue(arg_4_0.energyEffectHeros_, iter_4_3)
						end
					else
						if arg_4_0.energyEffectHeros_[iter_4_3] then
							arg_4_0.energyEffectHeros_[iter_4_3] = arg_4_0.energyEffectHeros_[iter_4_3] + var_0_16[var_4_2 - 1]
						else
							arg_4_0.energyEffectHeros_[iter_4_3] = var_0_16[var_4_2 - 1]
						end

						if arg_4_0.energyEffectHeros_[iter_4_3] > 1 then
							arg_4_0:removeEnergyBuff(iter_4_3)

							arg_4_0.energyStoneHeros_[iter_4_3] = true
							arg_4_0.energyKeyHp_[iter_4_3] = arg_4_0:getKeyHp(iter_4_3)

							arg_4_0:addStoneBuff(iter_4_3)
							var_0_0.table.removebyvalue(arg_4_0.energyEffectHeros_, iter_4_3)
						else
							arg_4_0:removeEnergyBuff(iter_4_3)

							local var_4_3 = 3

							for iter_4_4, iter_4_5 in ipairs(var_0_17) do
								if iter_4_5 >= arg_4_0.energyEffectHeros_[iter_4_3] then
									var_4_3 = iter_4_4

									break
								end
							end

							local var_4_4 = arg_4_0:newBuff({
								var_0_18[var_4_3],
								var_0_19[var_4_3]
							}, iter_4_3, arg_4_0:getEnergySkillID())

							if var_4_4[1] then
								var_4_4[1].manualRevise = -arg_4_0.energyEffectHeros_[iter_4_3] * 8
								var_4_4[2].manualRevise = -arg_4_0.energyEffectHeros_[iter_4_3]
							end

							iter_4_3:addBuffs(var_4_4)
						end
					end
				end
			end

			for iter_4_6, iter_4_7 in ipairs(var_4_1) do
				var_0_0.table.removebyvalue(arg_4_0.moveAttackUnits_, iter_4_7)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			for iter_4_8, iter_4_9 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
				local var_4_5 = iter_4_9.target
				local var_4_6 = iter_4_9.harm

				if not var_4_5:isDeath() then
					for iter_4_10, iter_4_11 in pairs(arg_4_0.energyKeyHp_) do
						if var_4_5 == iter_4_10 then
							if iter_4_11 then
								arg_4_0.energyKeyHp_[iter_4_10] = arg_4_0.energyKeyHp_[iter_4_10] - var_4_6

								if arg_4_0.energyKeyHp_[iter_4_10] < 0 then
									local var_4_7 = arg_4_0:createAttackUnits({
										iter_4_10
									}, var_0_21)

									for iter_4_12, iter_4_13 in ipairs(var_4_7) do
										table.insert(arg_4_0.moveAttackUnits_, iter_4_13)
										table.insert(arg_4_0.records_.special_units, iter_4_13)
									end

									arg_4_0.energyKeyHp_[iter_4_10] = false
								end
							end

							break
						end
					end
				end
			end
		end

		arg_4_0.energyCount_ = arg_4_0.energyCount_ - 1

		if arg_4_0.energyCount_ <= 0 then
			arg_4_0:removeEnergyEffect()
			arg_4_0:playAttack(6)

			arg_4_0.energyEndCount_ = var_0_24
		end
	end

	if arg_4_0.energyEndCount_ > 0 then
		arg_4_0.energyEndCount_ = arg_4_0.energyEndCount_ - 1

		if arg_4_0.energyEndCount_ == 0 then
			arg_4_0.isEnergying_ = false
		end
	end
end

function var_0_3.checkMove(arg_5_0)
	if arg_5_0.isEnergying_ then
		return false
	else
		return var_0_3.super.checkMove(arg_5_0)
	end
end

function var_0_3.canAttack(arg_6_0)
	if arg_6_0.isEnergying_ then
		return false
	else
		return var_0_3.super.canAttack(arg_6_0)
	end
end

function var_0_3.isBreakImmortal(arg_7_0)
	if arg_7_0.isEnergying_ then
		return true
	else
		return var_0_3.super.isBreakImmortal(arg_7_0)
	end
end

function var_0_3.checkEnergySkill(arg_8_0)
	if arg_8_0.isEnergying_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_8_0)
	end
end

function var_0_3.addStoneBuff(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0:newBuff(var_0_20, arg_9_1, arg_9_0:getEnergySkillID())

	arg_9_1:addBuffs(var_9_0)
end

function var_0_3.removeEnergyEffect(arg_10_0)
	for iter_10_0, iter_10_1 in pairs(arg_10_0.energyEffectHeros_) do
		arg_10_0:removeEnergyBuff(iter_10_0)
	end

	for iter_10_2, iter_10_3 in pairs(arg_10_0.energyStoneHeros_) do
		for iter_10_4 = 1, #var_0_20 do
			iter_10_2:removeBuffByID(var_0_20[iter_10_4])
		end
	end

	arg_10_0.energyStoneHeros_ = {}
	arg_10_0.energyEffectHeros_ = {}
	arg_10_0.energyKeyHp_ = {}
end

function var_0_3.removeEnergyBuff(arg_11_0, arg_11_1)
	if arg_11_1:isDeath() then
		return
	end

	for iter_11_0, iter_11_1 in ipairs(var_0_18) do
		arg_11_1:removeBuffByID(iter_11_1)
	end

	for iter_11_2, iter_11_3 in ipairs(var_0_19) do
		arg_11_1:removeBuffByID(iter_11_3)
	end
end

function var_0_3.getEnergyUpLevel(arg_12_0, arg_12_1)
	if arg_12_1:isDeath() then
		return 0
	end

	local var_12_0 = math.abs(arg_12_0:getX() - arg_12_1:getX())

	for iter_12_0, iter_12_1 in ipairs(var_0_15) do
		if var_12_0 <= iter_12_1 then
			return iter_12_0
		end
	end

	return 0
end

function var_0_3.getKeyHp(arg_13_0, arg_13_1)
	return arg_13_1:getHp() * var_0_9
end

function var_0_3.purpleHeroJudge(arg_14_0)
	local var_14_0 = -1
	local var_14_1

	for iter_14_0, iter_14_1 in pairs(arg_14_0.purpleHero_) do
		if not iter_14_1:isDeath() then
			local var_14_2 = iter_14_1:getTableID()
			local var_14_3 = arg_14_0.purpleHeroAttackNum_[var_14_2]

			if var_14_3 and var_14_0 < var_14_3 then
				var_14_1 = iter_14_1
				var_14_0 = var_14_3
			end
		end
	end

	if var_14_1 then
		if arg_14_0.currentPurpleTarget_ and arg_14_0.currentPurpleTarget_ ~= var_14_1 then
			arg_14_0.currentPurpleTarget_:removeBuffByID(var_0_10[1])
		end

		if arg_14_0.currentPurpleTarget_ ~= var_14_1 then
			local var_14_4 = arg_14_0:newBuff(var_0_10, var_14_1, arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_14_1:addBuffs(var_14_4)

			arg_14_0.currentPurpleTarget_ = var_14_1
		end
	end
end

function var_0_3.removeBlueEffectHerosBuff(arg_15_0)
	for iter_15_0 = #arg_15_0.blueEffectEnemyHeros_, 1, -1 do
		local var_15_0 = arg_15_0.blueEffectEnemyHeros_[iter_15_0]

		arg_15_0:removeBuff(var_15_0, var_0_13)
		table.remove(arg_15_0.blueEffectEnemyHeros_, iter_15_0)
	end

	for iter_15_1 = #arg_15_0.blueEffectSelfHeros_, 1, -1 do
		local var_15_1 = arg_15_0.blueEffectSelfHeros_[iter_15_1]

		arg_15_0:removeBuff(var_15_1, var_0_14)
		table.remove(arg_15_0.blueEffectSelfHeros_, iter_15_1)
	end
end

function var_0_3.removeGreenEffectHerosBuff(arg_16_0)
	for iter_16_0 = #arg_16_0.greenEffectEnemyHeros_, 1, -1 do
		local var_16_0 = arg_16_0.greenEffectEnemyHeros_[iter_16_0]

		arg_16_0:removeBuff(var_16_0, var_0_11)
		table.remove(arg_16_0.greenEffectEnemyHeros_, iter_16_0)
	end

	for iter_16_1 = #arg_16_0.greenEffectSelfHeros_, 1, -1 do
		local var_16_1 = arg_16_0.greenEffectSelfHeros_[iter_16_1]

		arg_16_0:removeBuff(var_16_1, var_0_12)
		table.remove(arg_16_0.greenEffectSelfHeros_, iter_16_1)
	end
end

function var_0_3.removeBuff(arg_17_0, arg_17_1, arg_17_2)
	if type(arg_17_2) ~= "table" or arg_17_1:isDeath() then
		return
	end

	for iter_17_0, iter_17_1 in ipairs(arg_17_2) do
		arg_17_1:removeBuffByID(iter_17_1)
	end
end

function var_0_3.greenEffectJudge(arg_18_0)
	local var_18_0 = arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_18_1 = var_0_5:scope(var_18_0)

	for iter_18_0 = #arg_18_0.greenEffectEnemyHeros_, 1, -1 do
		local var_18_2 = arg_18_0.greenEffectEnemyHeros_[iter_18_0]

		if var_18_2:isDeath() or math.abs(var_18_2:getX() - arg_18_0:getX()) > var_18_1 * 0.5 then
			arg_18_0:removeBuff(var_18_2, var_0_11)
			table.remove(arg_18_0.greenEffectEnemyHeros_, iter_18_0)
		elseif not var_18_2:isHasBuffByID(var_0_11[1]) then
			local var_18_3 = arg_18_0:newBuff(var_0_11, var_18_2, arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			var_18_2:addBuffs(var_18_3)
		end
	end

	for iter_18_1, iter_18_2 in ipairs(arg_18_0.sideTeam_) do
		if not iter_18_2:isDeath() and not iter_18_2:isAffected() and not iter_18_2:isHasBuffByID(var_0_11[1]) and math.abs(iter_18_2:getX() - arg_18_0:getX()) <= var_18_1 * 0.5 then
			local var_18_4 = arg_18_0:newBuff(var_0_11, iter_18_2, arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			iter_18_2:addBuffs(var_18_4)
			table.insert(arg_18_0.greenEffectEnemyHeros_, iter_18_2)
		end
	end

	if #arg_18_0.greenEffectEnemyHeros_ <= 0 then
		for iter_18_3 = #arg_18_0.greenEffectSelfHeros_, 1, -1 do
			local var_18_5 = arg_18_0.greenEffectSelfHeros_[iter_18_3]

			if var_18_5:isDeath() or math.abs(var_18_5:getX() - arg_18_0:getX()) > var_18_1 * 0.5 then
				arg_18_0:removeBuff(var_18_5, var_0_12)
				table.remove(arg_18_0.greenEffectSelfHeros_, iter_18_3)
			elseif not var_18_5:isHasBuffByID(var_0_12[1]) then
				local var_18_6 = arg_18_0:newBuff(var_0_12, var_18_5, arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

				var_18_5:addBuffs(var_18_6)
			end
		end

		for iter_18_4, iter_18_5 in ipairs(arg_18_0.selfTeam_) do
			if not iter_18_5:isDeath() and not iter_18_5:isAffected() and not iter_18_5:isHasBuffByID(var_0_12[1]) and math.abs(iter_18_5:getX() - arg_18_0:getX()) <= 0.5 * var_18_1 then
				local var_18_7 = arg_18_0:newBuff(var_0_12, iter_18_5, arg_18_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

				iter_18_5:addBuffs(var_18_7)
				table.insert(arg_18_0.greenEffectSelfHeros_, iter_18_5)
			end
		end
	else
		for iter_18_6 = #arg_18_0.greenEffectSelfHeros_, 1, -1 do
			local var_18_8 = arg_18_0.greenEffectSelfHeros_[iter_18_6]

			arg_18_0:removeBuff(var_18_8, var_0_12)
			table.remove(arg_18_0.greenEffectSelfHeros_, iter_18_6)
		end
	end
end

function var_0_3.blueEffectJudge(arg_19_0)
	local var_19_0 = arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_19_1 = var_0_5:scope(var_19_0)

	for iter_19_0 = #arg_19_0.blueEffectEnemyHeros_, 1, -1 do
		local var_19_2 = arg_19_0.blueEffectEnemyHeros_[iter_19_0]

		if var_19_2:isDeath() or math.abs(var_19_2:getX() - arg_19_0:getX()) > var_19_1 * 0.5 then
			arg_19_0:removeBuff(var_19_2, var_0_13)
			table.remove(arg_19_0.blueEffectEnemyHeros_, iter_19_0)
		elseif not var_19_2:isHasBuffByID(var_0_13[1]) then
			arg_19_0:addBlueBuff(var_19_2)
		end
	end

	for iter_19_1, iter_19_2 in ipairs(arg_19_0.sideTeam_) do
		if not iter_19_2:isDeath() and not iter_19_2:isAffected() and not iter_19_2:isHasBuffByID(var_0_13[1]) and math.abs(iter_19_2:getX() - arg_19_0:getX()) <= var_19_1 * 0.5 then
			arg_19_0:addBlueBuff(iter_19_2)
			table.insert(arg_19_0.blueEffectEnemyHeros_, iter_19_2)
		end
	end

	if #arg_19_0.blueEffectEnemyHeros_ <= 0 then
		for iter_19_3 = #arg_19_0.blueEffectSelfHeros_, 1, -1 do
			local var_19_3 = arg_19_0.blueEffectSelfHeros_[iter_19_3]

			if var_19_3:isDeath() or math.abs(var_19_3:getX() - arg_19_0:getX()) > var_19_1 * 0.5 then
				arg_19_0:removeBuff(var_19_3, var_0_14)
				table.remove(arg_19_0.blueEffectSelfHeros_, iter_19_3)
			elseif not var_19_3:isHasBuffByID(var_0_14[1]) then
				local var_19_4 = arg_19_0:newBuff(var_0_14, var_19_3, arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				var_19_3:addBuffs(var_19_4)
			end
		end

		for iter_19_4, iter_19_5 in ipairs(arg_19_0.selfTeam_) do
			if not iter_19_5:isDeath() and not iter_19_5:isAffected() and not iter_19_5:isHasBuffByID(var_0_14[1]) and math.abs(iter_19_5:getX() - arg_19_0:getX()) <= 0.5 * var_19_1 then
				local var_19_5 = arg_19_0:newBuff(var_0_14, iter_19_5, arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_19_5:addBuffs(var_19_5)
				table.insert(arg_19_0.blueEffectSelfHeros_, iter_19_5)
			end
		end
	else
		for iter_19_6 = #arg_19_0.blueEffectSelfHeros_, 1, -1 do
			local var_19_6 = arg_19_0.blueEffectSelfHeros_[iter_19_6]

			arg_19_0:removeBuff(var_19_6, var_0_14)
			table.remove(arg_19_0.blueEffectSelfHeros_, iter_19_6)
		end
	end
end

function var_0_3.addBlueBuff(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_0:newBuff(var_0_13, arg_20_1, arg_20_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	arg_20_1:addBuffs(var_20_0)
end

function var_0_3.newBuff(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = {}

	for iter_21_0, iter_21_1 in ipairs(arg_21_1) do
		local var_21_1 = var_0_4.new({
			tableID = iter_21_1,
			start = var_0_1.ctx.battle.count,
			level = arg_21_0:getSkillLevelByID(arg_21_3),
			skillID = arg_21_3,
			fighter = arg_21_0,
			target = arg_21_2
		})

		var_21_1:setIsHit(true)
		var_21_1:setDirection(arg_21_0:getFighterModel():getFlipX())
		table.insert(var_21_0, var_21_1)
	end

	return var_21_0
end

function var_0_3.forceDie(arg_22_0)
	if arg_22_0.greenEffectCount_ > 0 then
		arg_22_0:removeGreenEffectHerosBuff()

		arg_22_0.greenEffectCount_ = 0
	end

	if arg_22_0.blueEffectCount_ > 0 then
		arg_22_0.blueEffectCount_ = 0

		arg_22_0:removeBlueEffectHerosBuff()
	end

	if arg_22_0.currentPurpleTarget_ then
		arg_22_0.currentPurpleTarget_:removeBuffByID(var_0_10[1])
	end

	if arg_22_0.energyCount_ > 0 then
		arg_22_0.energyCount_ = 0

		arg_22_0:removeEnergyEffect()

		arg_22_0.energyEndCount_ = var_0_24
	end

	var_0_3.super.forceDie(arg_22_0)
end

function var_0_3.buffAddAction(arg_23_0, arg_23_1)
	if arg_23_1:getSkillID() == arg_23_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_23_0 = var_0_22 + var_0_23 * arg_23_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if arg_23_1:getTableID() == var_0_10[1] then
			arg_23_1.manualRevise = arg_23_1.target:getAP() * var_23_0 * -1
		elseif arg_23_1:getTableID() == var_0_10[2] then
			arg_23_1.manualRevise = arg_23_1.target:getAD() * var_23_0 * -1
		end
	end

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		if arg_23_1:getTableID() == var_0_18[1] then
			arg_23_1:setManualFilter({
				color = cc.c4f(0.75, 0.75, 0.75, 1)
			})
		elseif arg_23_1:getTableID() == var_0_18[2] then
			arg_23_1:setManualFilter({
				color = cc.c4f(0.5, 0.5, 0.5, 1)
			})
		elseif arg_23_1:getTableID() == var_0_18[3] then
			arg_23_1:setManualFilter({
				color = cc.c4f(0.3, 0.3, 0.3, 1)
			})
		end
	end
end

return var_0_3
