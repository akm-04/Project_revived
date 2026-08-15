local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wufan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = 0.1
local var_0_11 = 10001865
local var_0_12 = 10001867
local var_0_13 = 40012023
local var_0_14 = 40012024

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.pkTarget = nil
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_11 and arg_2_1.target == arg_2_0 then
		for iter_2_0, iter_2_1 in pairs(arg_2_0:getBuffs()) do
			if iter_2_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_2_1:canRemove() then
				arg_2_0:removeBuffs(iter_2_1)
			end
		end
	elseif arg_2_1.skillID == var_0_12 then
		arg_2_0.pkTarget = arg_2_1.target
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_14 then
		arg_3_1:setForceTarget(arg_3_0)
	elseif arg_3_1:getTableID() == var_0_13 and arg_3_0.pkTarget then
		arg_3_1:setForceTarget(arg_3_0.pkTarget)
	end
end

function var_0_3.afterDamageHarm(arg_4_0, arg_4_1, arg_4_2)
	var_0_3.super.afterDamageHarm(arg_4_0, arg_4_1, arg_4_2)

	if arg_4_2.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_4_2.target:isBoss() then
		arg_4_2.target:resetHpLimit(arg_4_2.target:getHpLimit() - arg_4_1 * var_0_10)
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_11 then
		local var_5_6 = 0

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			if iter_5_1.hero_:getHeroType() == var_0_2.HeroType.AGILE then
				var_5_6 = var_5_6 + 1
			end
		end

		var_5_3 = var_5_6 * (5 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) + 0.2 * arg_5_0:getAP())
	elseif var_5_2 > 0 and arg_5_0:isHasBuffByID(var_0_13) then
		var_5_2 = var_5_2 + 12 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + 0.3 * arg_5_0:getAD()
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.getAD(arg_6_0)
	local var_6_0 = var_0_3.super.getAD(arg_6_0)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_6_1 = 0

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if not iter_6_1:isDeath() then
				var_6_1 = var_6_1 + 1
			end
		end

		var_6_0 = var_6_0 + math.min(var_6_1, 10) * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * 3
	end

	return var_6_0
end

function var_0_3.getHuJia(arg_7_0)
	local var_7_0 = var_0_3.super.getHuJia(arg_7_0)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_7_1 = 0

		for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
			if not iter_7_1:isDeath() then
				var_7_1 = var_7_1 + 1
			end
		end

		var_7_0 = var_7_0 + math.min(var_7_1, 10) * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * 0.9
	end

	return var_7_0
end

function var_0_3.getMoKang(arg_8_0)
	local var_8_0 = var_0_3.super.getMoKang(arg_8_0)

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		local var_8_1 = 0

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() then
				var_8_1 = var_8_1 + 1
			end
		end

		var_8_0 = var_8_0 + math.min(var_8_1, 10) * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * 0.6
	end

	return var_8_0
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1.hero_:getDistanceType() ~= var_0_2.DistanceType.QIANPAI then
			table.insert(var_9_0, iter_9_1)
		end
	end

	if #var_9_0 == 0 then
		for iter_9_2, iter_9_3 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_3:isDeath() and not iter_9_3:isAffected() then
				table.insert(var_9_0, iter_9_3)
			end
		end
	end

	if next(var_9_0) then
		return {
			var_9_0[math.random(#var_9_0)]
		}
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1.hero_:getDistanceType() == var_0_2.DistanceType.HOUPAI then
			table.insert(var_10_0, iter_10_1)
		end
	end

	if #var_10_0 == 0 then
		for iter_10_2, iter_10_3 in ipairs(arg_10_0.sideTeam_) do
			if not iter_10_3:isDeath() and not iter_10_3:isAffected() and iter_10_3.hero_:getDistanceType() ~= var_0_2.DistanceType.QIANPAI then
				table.insert(var_10_0, iter_10_3)
			end
		end
	end

	if next(var_10_0) then
		return {
			var_10_0[math.random(#var_10_0)]
		}
	end

	return var_10_0
end

return var_0_3
