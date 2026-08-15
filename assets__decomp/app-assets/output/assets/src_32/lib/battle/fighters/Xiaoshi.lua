local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 40012412
local var_0_9 = 0.1
local var_0_10 = 0.005
local var_0_11 = 0.2
local var_0_12 = 0
local var_0_13 = 0.1
local var_0_14 = 0.0015
local var_0_15 = 0.15
local var_0_16 = 0
local var_0_17 = 0.004
local var_0_18 = 0.1
local var_0_19 = 40012411
local var_0_20 = 10002253
local var_0_21 = 10002254

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.breakShieldBuff = false
	arg_2_0.EnergyAddDbuffTargets = {}
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.target

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_3_0:removeShieldBuff(var_3_0)
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
				table.insert(arg_3_0.EnergyAddDbuffTargets, iter_3_1)

				local var_3_1 = arg_3_0:createNewBuffs({
					var_0_19
				}, iter_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_3_1:addBuffs(var_3_1)
			end
		end
	end
end

function var_0_3.removeShieldBuff(arg_4_0, arg_4_1)
	for iter_4_0 = #arg_4_1.buffs_, 1, -1 do
		local var_4_0 = arg_4_1.buffs_[iter_4_0]

		if var_4_0 and (var_4_0:getType() == var_0_2.BuffType.SHIELD_BUFF or var_4_0:getType() == var_0_2.BuffType.D_HARM) and var_4_0:canRemove() and var_4_0.leftCount_ < 3000 then
			arg_4_1:removeBuffs(var_4_0)

			arg_4_0.breakShieldBuff = true
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	var_0_3.super.buffAddAction(arg_5_0, arg_5_1)

	if arg_5_1:getTableID() == var_0_19 and arg_5_0.breakShieldBuff == true then
		if next(arg_5_0.EnergyAddDbuffTargets) then
			for iter_5_0, iter_5_1 in ipairs(arg_5_0.EnergyAddDbuffTargets) do
				if iter_5_1 == arg_5_1.target then
					local var_5_0 = math.max(var_0_6:dHarm(arg_5_1:getTableID()) + arg_5_1.level_ * arg_5_1:stepHarm(), 0)
					local var_5_1 = var_0_13 + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

					if arg_5_0.isStarGreen_ then
						var_5_1 = var_5_1 + (var_0_15 + var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
					end

					arg_5_1:setManualDharm(arg_5_1.manualDharm + var_5_0 * var_5_1)
					table.remove(arg_5_0.EnergyAddDbuffTargets, 1)
				end
			end
		end

		if not next(arg_5_0.EnergyAddDbuffTargets) then
			arg_5_0.breakShieldBuff = false
		end
	elseif arg_5_1:getTableID() == var_0_8 and arg_5_0.breakShieldBuff == true then
		local var_5_2 = var_0_13 + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		if arg_5_0.isStarGreen_ then
			var_5_2 = var_5_2 + (var_0_15 + var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
		end

		local var_5_3 = arg_5_1:getTime() * var_5_2

		arg_5_1:setExtraTime(arg_5_1.extraTime_ + var_5_3)

		arg_5_0.breakShieldBuff = false
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_6_1.target:isHasBuffByID(var_0_8) and arg_6_4 > 0 and arg_6_1.target:getTeamType() == arg_6_0:getTeamType() then
		local var_6_0 = var_0_9 + var_0_10 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		local var_6_1 = math.max(0, 1 - var_6_0)

		if arg_6_0.isStarBlue_ then
			local var_6_2 = var_0_12 + var_0_11 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

			var_6_1 = math.max(0, var_6_1 - var_6_2)
		end

		arg_6_4 = arg_6_4 * var_6_1
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.addBuffBySpecialHero(arg_7_0, arg_7_1)
	var_0_3.super.addBuffBySpecialHero(arg_7_0, arg_7_1)

	for iter_7_0 = #arg_7_1, 1, -1 do
		local var_7_0 = arg_7_1[iter_7_0]

		if var_7_0:getType() == var_0_2.BuffType.D_HARM and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_7_0.target:getTeamType() == arg_7_0:getTeamType() then
			local var_7_1 = math.max(var_0_6:dHarm(var_7_0:getTableID()) + var_7_0.level_ * var_7_0:stepHarm(), 0)
			local var_7_2 = var_0_17 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

			if arg_7_0.isStarPurple_ then
				var_7_2 = var_7_2 + var_0_18
			end

			var_7_0.manualDharm = var_7_0.manualDharm + var_7_1 * var_7_2
		end
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_19 then
		local var_8_0 = arg_8_0:getEnergyRoundSkillTarget(arg_8_1.target, var_0_20)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if arg_8_0.isStarEnergy_ then
				local var_8_1 = arg_8_0:createAttackUnits(var_8_0, var_0_21)

				for iter_8_0, iter_8_1 in ipairs(var_8_1) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
					table.insert(arg_8_0.records_.special_units, iter_8_1)
				end
			else
				local var_8_2 = arg_8_0:createAttackUnits(var_8_0, var_0_20)

				for iter_8_2, iter_8_3 in ipairs(var_8_2) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
					table.insert(arg_8_0.records_.special_units, iter_8_3)
				end
			end
		end
	end
end

function var_0_3.getEnergyRoundSkillTarget(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}
	local var_9_1, var_9_2 = arg_9_1:getPos()
	local var_9_3 = var_0_5:scope(arg_9_2)
	local var_9_4, var_9_5 = var_0_7.getTeam(arg_9_1)

	for iter_9_0, iter_9_1 in ipairs(var_9_5) do
		local var_9_6, var_9_7 = iter_9_1:getPos()

		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and var_9_3 >= math.abs(var_9_1 - var_9_6) and iter_9_1 ~= arg_9_1 then
			table.insert(var_9_0, iter_9_1)
		end
	end

	return var_9_0
end

return var_0_3
