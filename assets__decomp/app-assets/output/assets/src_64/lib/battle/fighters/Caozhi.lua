local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caozhi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10000294
local var_0_5 = 10000291
local var_0_6 = 10000293
local var_0_7 = 10000292
local var_0_8 = var_0_2.tables.skill

function var_0_3.selectTargetByTypeD1(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0
	local var_1_1

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
		if not iter_1_1:isDeath() and not iter_1_1:isAffected() and not iter_1_1:isBreakImmortal() and iter_1_1:getSummonType() == var_0_2.summonMonsterType.None and (not iter_1_1:isCreatingUnits() or not iter_1_1.isEnergySkill_) and (not var_1_0 or var_1_1 > iter_1_1:getHp() / iter_1_1:getHpLimit()) then
			var_1_0 = iter_1_1
			var_1_1 = iter_1_1:getHp() / iter_1_1:getHpLimit()
		end
	end

	if var_1_0 then
		return {
			var_1_0
		}
	end

	return {}
end

function var_0_3.selectTargetByTypeD2(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0
	local var_2_1

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() and (not var_2_0 or var_2_1 > iter_2_1:getHp() / iter_2_1:getHpLimit()) then
			var_2_0 = iter_2_1
			var_2_1 = iter_2_1:getHp() / iter_2_1:getHpLimit()
		end
	end

	if not var_2_0 then
		return {}
	end

	local var_2_2 = {
		var_2_0
	}

	for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_3:isDeath() and not iter_2_3:isAffected() and iter_2_3 ~= var_2_0 and math.abs(iter_2_3:getX() - var_2_0:getX()) < var_0_8:scope(arg_2_1) / 2 then
			table.insert(var_2_2, iter_2_3)
		end
	end

	return var_2_2
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.forcetarget_ = arg_3_1.target

		if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			return
		end

		local var_3_0 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_1.target.selfTeam_) do
			if iter_3_1 ~= arg_3_1.target and not iter_3_1:isDeath() and not iter_3_1:isAffected() then
				table.insert(var_3_0, iter_3_1)

				if iter_3_1:isCreatingUnits() then
					iter_3_1:skillIsBreak(arg_3_1)
				end
			end
		end

		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, var_0_4)

		for iter_3_2, iter_3_3 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_3_1.target:isDeath() or var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
			return
		end

		local var_3_2 = {
			arg_3_1.target
		}
		local var_3_3 = arg_3_1.target.hero_:getHeroType() == var_0_2.HeroType.STRENGTH and var_0_6 or var_0_7
		local var_3_4 = arg_3_0:createAttackUnits(var_3_2, var_3_3)

		for iter_3_4, iter_3_5 in ipairs(var_3_4) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
			table.insert(arg_3_0.records_.special_units, iter_3_5)
		end
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_3_1.target:isDeath() or var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport or arg_3_1.target.hero_:getHeroType() ~= var_0_2.HeroType.AGILE then
			return
		end

		local var_3_5 = {
			arg_3_1.target
		}
		local var_3_6 = arg_3_0:createAttackUnits(var_3_5, var_0_5)

		for iter_3_6, iter_3_7 in ipairs(var_3_6) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
			table.insert(arg_3_0.records_.special_units, iter_3_7)
		end
	end
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	var_0_3.super.buffAddAction(arg_4_0, arg_4_1)

	if arg_4_1.skillID_ == var_0_4 then
		arg_4_1:setForceTarget(arg_4_0.forcetarget_)
	end
end

return var_0_3
