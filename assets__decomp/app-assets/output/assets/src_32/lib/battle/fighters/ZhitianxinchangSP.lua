local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ZhitianxinchangSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10002171
local var_0_7 = 10002172
local var_0_8 = 0.05
local var_0_9 = 0.2
local var_0_10 = 40012313
local var_0_11 = 10002248
local var_0_12 = 40012311
local var_0_13 = 10002165
local var_0_14 = 2
local var_0_15 = 0.25
local var_0_16 = 10002166
local var_0_17 = 40012312
local var_0_18 = 80010260

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyTarget = nil
	arg_1_0.purpleBearHarm = 0
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergyFirstHitSkill = 10002555
		arg_2_0.EnergyLastHitSkill = 10002558
	else
		arg_2_0.EnergyFirstHitSkill = 10002167
		arg_2_0.EnergyLastHitSkill = 10002170
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.target:isDeath()

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 and var_0_5:father(arg_3_1.skillID) == arg_3_0:getPugongID() and not arg_3_1.target:isHasBuffByID(var_0_12) then
		local var_3_1 = arg_3_0:createNewBuffs({
			var_0_12
		}, arg_3_1.target, var_0_18)

		arg_3_1.target:addBuffs(var_3_1)
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and not arg_3_1.target:isHasBuffByID(var_0_12) then
		local var_3_2 = arg_3_0:createNewBuffs({
			var_0_12
		}, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_3_1.target:addBuffs(var_3_2)
	elseif arg_3_1.skillID == arg_3_0.EnergyLastHitSkill and not arg_3_1.target:isDeath() then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_3 = arg_3_0:createAttackUnits({
				arg_3_0
			}, var_0_6)

			for iter_3_0, iter_3_1 in ipairs(var_3_3) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		end
	elseif var_0_5:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and not var_3_0 and arg_3_1.target:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_4 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_7)

		for iter_3_2, iter_3_3 in ipairs(var_3_4) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	if arg_3_1.skillID == arg_3_0.EnergyFirstHitSkill then
		local var_3_5 = arg_3_1.target:getX()
		local var_3_6 = arg_3_1.target:getY()
		local var_3_7

		if arg_3_0:getTeamType() == var_0_2.TeamType.A then
			var_3_7 = -1

			arg_3_0:flipX(false)
		else
			var_3_7 = 1

			arg_3_0:flipX(true)
		end

		arg_3_0:x(var_3_5 + 100 * var_3_7)
		arg_3_0:y(var_3_6)
	elseif arg_3_1.skillID == arg_3_0.EnergyLastHitSkill then
		arg_3_0.energyTarget = nil
	end
end

function var_0_3.updateBearHarms(arg_4_0, arg_4_1)
	var_0_3.super.updateBearHarms(arg_4_0, arg_4_1)

	arg_4_0.purpleBearHarm = arg_4_0.purpleBearHarm + arg_4_1

	if arg_4_0.purpleBearHarm >= arg_4_0:getHpLimit() * var_0_15 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_16)

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		arg_4_0.purpleBearHarm = 0
	end
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.energyTarget then
		return {
			arg_5_0.energyTarget
		}
	end

	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.targetTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_5_0, iter_5_1)
		end
	end

	if next(var_5_0) then
		local var_5_1
		local var_5_2

		for iter_5_2, iter_5_3 in ipairs(var_5_0) do
			if arg_5_0:getTeamType() == var_0_2.TeamType.A then
				if not var_5_1 or var_5_2 < iter_5_3:getX() then
					var_5_1 = iter_5_3
					var_5_2 = iter_5_3:getX()
				end
			elseif not var_5_1 or var_5_2 > iter_5_3:getX() then
				var_5_1 = iter_5_3
				var_5_2 = iter_5_3:getX()
			end
		end

		arg_5_0.energyTarget = var_5_1

		return {
			var_5_1
		}
	else
		return {}
	end
end

function var_0_3.buffRemoveAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_12 then
		if arg_6_0.skinSkillIndex_ == 1 then
			local var_6_0 = arg_6_1.target
			local var_6_1 = var_6_0:getBuffs()
			local var_6_2 = false

			for iter_6_0 = #var_6_1, 1, -1 do
				local var_6_3 = var_6_1[iter_6_0]

				if var_6_3:getDHarm() > 0 and var_6_3:canRemove() then
					var_6_2 = true

					var_6_0:removeBuffs(var_6_3)
				end
			end

			if var_6_2 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_4 = arg_6_0:createAttackUnits({
					arg_6_0
				}, var_0_18)

				for iter_6_1, iter_6_2 in ipairs(var_6_4) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_2)
					table.insert(arg_6_0.records_.special_units, iter_6_2)
				end
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_5 = arg_6_0
			local var_6_6 = var_0_13
			local var_6_7 = {}
			local var_6_8 = var_0_5:scope(var_6_6) / 2
			local var_6_9 = arg_6_1.target
			local var_6_10, var_6_11 = var_6_9:getPos()
			local var_6_12, var_6_13 = var_0_4.getTeam(var_6_5)

			table.insert(var_6_7, var_6_9)

			for iter_6_3, iter_6_4 in ipairs(var_6_13) do
				local var_6_14, var_6_15 = iter_6_4:getPos()

				if not iter_6_4:isDeath() and not iter_6_4:isAffected() and var_6_8 >= math.abs(var_6_10 - var_6_14) and iter_6_4 ~= var_6_9 then
					table.insert(var_6_7, iter_6_4)
				end
			end

			local var_6_16 = arg_6_0:createAttackUnits(var_6_7, var_0_13)

			for iter_6_5, iter_6_6 in ipairs(var_6_16) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_6)
				table.insert(arg_6_0.records_.special_units, iter_6_6)
			end
		end
	end

	if arg_6_1:getTableID() == var_0_10 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_17 = arg_6_0:createAttackUnits({
			arg_6_0
		}, var_0_11)

		for iter_6_7, iter_6_8 in ipairs(var_6_17) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_8)
			table.insert(arg_6_0.records_.special_units, iter_6_8)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_7_1.target:isHasBuffByID(var_0_12) then
		arg_7_4 = arg_7_4 * var_0_14
	elseif arg_7_4 > 0 and arg_7_1.skillID == arg_7_0.EnergyLastHitSkill then
		local var_7_0 = (arg_7_1.target:getHpLimit() - arg_7_1.target:getHp()) * var_0_9

		if arg_7_1.target:isBoss() then
			var_7_0 = math.min(var_7_0, arg_7_0:getHpLimit() * 5)
		end

		arg_7_4 = arg_7_4 + var_7_0
	end

	if arg_7_4 > 0 and var_0_5:father(arg_7_1.skillID) == arg_7_0:getEnergySkillID() then
		local var_7_1 = arg_7_1.target:getHpLimit() * var_0_8

		if arg_7_1.target:isBoss() then
			var_7_1 = math.min(var_7_1, arg_7_0:getHpLimit())
		end

		arg_7_4 = arg_7_4 + var_7_1
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.isBreakImmortal(arg_8_0)
	if arg_8_0:isHasBuffByID(var_0_17) then
		return true
	end

	return var_0_3.super.isBreakImmortal(arg_8_0)
end

return var_0_3
