local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caiwenji", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40010658
local var_0_8 = 250
local var_0_9 = 45
local var_0_10 = 40010660
local var_0_11 = 10000665
local var_0_12 = 0.4
local var_0_13 = 0.006
local var_0_14 = 40010664
local var_0_15 = 40010661
local var_0_16 = {
	600,
	300
}
local var_0_17 = 80010148
local var_0_18 = 0.3
local var_0_19 = {
	40010658,
	40010662,
	40010663
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyBuffs = {}
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_2_0 > 0 then
		local var_2_1 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

		arg_2_0.harmSum = 0
		arg_2_0.harmLine = var_0_6:init(var_2_1) + var_0_6:step(var_2_1) * var_2_0
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.energyTarget then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_3_1:isDeath() and iter_3_1:getHp() < arg_3_0.energyTarget:getHp() then
				arg_3_0:endEnergy()

				break
			end
		end

		if arg_3_0.energyCount then
			arg_3_0.energyCount = arg_3_0.energyCount - 1

			if arg_3_0.energyCount <= 0 then
				arg_3_0:endEnergy()
			end
		end
	end

	if arg_3_0.beginEnergy and not arg_3_0:isCreatingUnits() then
		arg_3_0.beginEnergy = nil
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.beginEnergy = true
	end

	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)
end

function var_0_3.isBreakImmortal(arg_5_0)
	if arg_5_0.beginEnergy then
		return true
	end

	return var_0_3.super.isBreakImmortal(arg_5_0)
end

function var_0_3.deathFeedback(arg_6_0, arg_6_1)
	if arg_6_1 == arg_6_0 or arg_6_1:getTeamType() ~= arg_6_0:getTeamType() and arg_6_1:getSummonType() == var_0_2.summonMonsterType.None and arg_6_0.energyTarget then
		arg_6_0:endEnergy()
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		arg_7_0.energyBuffs = {}
		arg_7_0.energyTarget = arg_7_1.target

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if iter_7_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_7_1:isDeath() and iter_7_1 ~= arg_7_1.target then
				arg_7_0:addEnergyBuff(iter_7_1, var_0_16[1] - var_0_16[2])
			end
		end

		if next(arg_7_0.energyBuffs) then
			arg_7_0.energyCount = var_0_16[1]
		else
			arg_7_0.energyCount = var_0_16[2]

			arg_7_0:addEnergyBuff(arg_7_1.target)
		end
	end
end

function var_0_3.addEnergyBuff(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = var_0_4.new({
		tableID = var_0_15,
		start = var_0_1.ctx.battle.count,
		level = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
		skillID = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
		fighter = arg_8_0,
		target = arg_8_1
	})

	if arg_8_2 then
		var_8_0:setExtraTime(arg_8_2)
	end

	arg_8_1:addBuffs({
		var_8_0
	})
	table.insert(arg_8_0.energyBuffs, var_8_0)
end

function var_0_3.endEnergy(arg_9_0)
	if arg_9_0.energyTarget then
		arg_9_0.energyTarget:removeBuffByID(var_0_14)

		arg_9_0.energyTarget = nil
	end

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.energyBuffs) do
		iter_9_1.target:removeBuffs(iter_9_1)
	end

	arg_9_0.energyBuffs = {}
end

function var_0_3.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	local var_10_0, var_10_1, var_10_2, var_10_3 = var_0_3.super.applyHurtFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)

	if var_10_0 > 0 and arg_10_0.harmSum then
		arg_10_0.harmSum = arg_10_0.harmSum + var_10_0

		if arg_10_0.harmSum >= arg_10_0.harmLine then
			arg_10_0.harmSum = 0

			local var_10_4 = var_0_4.new({
				tableID = var_0_10,
				start = var_0_1.ctx.battle.count,
				level = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_10_0,
				target = arg_10_0
			})

			arg_10_0:addBuffs({
				var_10_4
			})
		end
	end

	return var_10_0, var_10_1, var_10_2, var_10_3
end

function var_0_3.getDHarmBuff(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = arg_11_1
	local var_11_1 = 0
	local var_11_2 = false

	for iter_11_0 = #arg_11_0.buffs_, 1, -1 do
		local var_11_3 = arg_11_0.buffs_[iter_11_0]
		local var_11_4 = var_0_0.clone(var_11_0)

		if var_11_3:getDHarm() > 0 and (var_11_3:dHarmType() == arg_11_2 or var_11_3:dHarmType() == var_0_2.HarmType.All) and not var_11_3:isDHarmLast() then
			if var_11_0 == 0 then
				return 0, 0, true
			end

			var_11_0 = var_11_3:setDHarm(var_11_0)

			local var_11_5 = var_11_0 * (var_0_12 + var_0_13 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

			if var_11_0 > 0 and var_11_3:getTableID() == var_0_10 and not arg_11_3:isAffected() and var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
				if arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_17 then
					local var_11_6 = arg_11_0:createAttackUnits(arg_11_0:selectTargetByTypeD1(arg_11_3), var_0_17)

					for iter_11_1, iter_11_2 in ipairs(var_11_6) do
						iter_11_2.harms = var_11_5

						table.insert(arg_11_0.moveAttackUnits_, iter_11_2)
						table.insert(arg_11_0.records_.special_units, iter_11_2)
					end
				else
					local var_11_7 = arg_11_0:createAttackUnits({
						arg_11_3
					}, var_0_11)

					for iter_11_3, iter_11_4 in ipairs(var_11_7) do
						iter_11_4.harms = var_11_5

						table.insert(arg_11_0.moveAttackUnits_, iter_11_4)
						table.insert(arg_11_0.records_.special_units, iter_11_4)
					end
				end
			end

			if var_11_3:getDHarm() == 0 and var_11_3.fighter then
				var_11_3.fighter:dHarmBuffBreakFeedback(arg_11_0, var_11_3, arg_11_3)
			end

			if var_11_3:harmToHP() > 0 then
				var_11_1 = var_11_1 + var_11_3:harmToHP() * (var_11_4 - var_11_0)
			end

			if var_11_0 == 0 then
				return var_11_0, var_11_1, true
			end

			var_11_2 = true
		end
	end

	return var_11_0, var_11_1, var_11_2
end

function var_0_3.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	if (arg_12_1.skillID == var_0_11 or arg_12_1.skillID == var_0_17) and arg_12_1.harms then
		arg_12_4 = arg_12_4 + arg_12_1.harms
	end

	if arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_17 and arg_12_4 > 0 and arg_12_0:isHasBadBuffs(arg_12_1.target) then
		arg_12_4 = arg_12_4 + arg_12_4 * var_0_18
	end

	return var_0_3.super.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
end

function var_0_3.isHasBadBuffs(arg_13_0, arg_13_1)
	for iter_13_0, iter_13_1 in ipairs(var_0_19) do
		if arg_13_1:isHasBuffByID(iter_13_1) then
			return true
		end
	end

	return false
end

function var_0_3.buffAddAction(arg_14_0, arg_14_1)
	if arg_14_1:getTableID() ~= var_0_7 then
		return
	end

	local var_14_0 = arg_14_0:getX()
	local var_14_1 = arg_14_1.target:getX()

	if math.abs(var_14_0 - var_14_1) < var_0_8 then
		arg_14_1:setExtraTime(var_0_9)
	end
end

function var_0_3.selectTargetByTypeB4(arg_15_0, arg_15_1)
	local var_15_0 = var_0_5.B2(arg_15_0, arg_15_1)
	local var_15_1
	local var_15_2

	for iter_15_0, iter_15_1 in pairs(var_15_0) do
		if iter_15_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_15_1 or var_15_2 > iter_15_1:getHp()) then
			var_15_1 = iter_15_1
			var_15_2 = iter_15_1:getHp()
		end
	end

	return var_15_1 and {
		var_15_1
	} or {}
end

function var_0_3.die(arg_16_0)
	if arg_16_0.beginEnergy then
		arg_16_0.beginEnergy = nil
	end

	return var_0_3.super.die(arg_16_0)
end

function var_0_3.checkKilling(arg_17_0, arg_17_1)
	var_0_3.super.checkKilling(arg_17_0, arg_17_1)

	if arg_17_1 and arg_17_1.skillID == var_0_17 then
		arg_17_0:createSkillByID(arg_17_0:getSkillByColor(var_0_2.SKILL_INDEX.Green), arg_17_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_6:attackIndex(arg_17_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)))
	end
end

function var_0_3.selectTargetByTypeD1(arg_18_0, arg_18_1)
	local var_18_0 = {}
	local var_18_1 = var_0_6:scope(var_0_17)
	local var_18_2, var_18_3 = arg_18_1:getPos()

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.sideTeam_) do
		local var_18_4, var_18_5 = iter_18_1:getPos()

		if not iter_18_1:isDeath() and not iter_18_1:isAffected() and var_18_1 >= math.abs(var_18_4 - var_18_2) then
			table.insert(var_18_0, iter_18_1)
		end
	end

	return var_18_0
end

return var_0_3
