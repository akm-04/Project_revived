local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiling", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 450
local var_0_5 = {
	40010141,
	40010142
}
local var_0_6 = 600
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.dbuff
local var_0_9 = 100
local var_0_10 = 10
local var_0_11 = 1
local var_0_12 = 80010105
local var_0_13 = 0.3
local var_0_14 = 40011516
local var_0_15 = 40011517
local var_0_16 = 0.1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.harmEnemies_ = {}
	arg_2_0.energyCount_ = nil
	arg_2_0.energyHalo_ = nil
	arg_2_0.purpleHp_ = 0
	arg_2_0.purpleSkillCount = nil
	arg_2_0.skinSkillUsed = false
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		arg_3_0.energyCount_ = var_0_4

		local var_3_0 = {
			fighter = arg_3_0,
			effect_area = function(arg_4_0)
				if arg_3_0:getFlipX() then
					if arg_4_0:getX() - arg_3_0:getX() < 0 then
						return false
					else
						return true
					end
				elseif arg_4_0:getX() - arg_3_0:getX() <= 0 then
					return true
				else
					return false
				end
			end,
			target_type = var_0_2.HaloEffect.selfTeam,
			buffs = var_0_5,
			level = arg_3_0:getSkillLevelByID(arg_3_1.skillID),
			skillID = arg_3_1.skillID
		}

		arg_3_0.energyHalo_ = var_3_0

		arg_3_0:addBuffHalo(var_3_0)
		arg_3_0:setImmuneControl(true)

		if arg_3_0:isWalkAnimation() then
			arg_3_0:modelWalk()
		else
			arg_3_0:resumeIdle()
		end
	end
end

function var_0_3.canAttack(arg_5_0)
	if arg_5_0.energyCount_ then
		return false
	else
		return var_0_3.super.canAttack(arg_5_0)
	end
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	local var_6_0, var_6_1, var_6_2, var_6_3 = var_0_3.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)

	if var_6_0 > 0 then
		local var_6_4 = arg_6_1.fighter
		local var_6_5 = false

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.harmEnemies_) do
			if iter_6_1.fighter == var_6_4 then
				iter_6_1.harm_num = iter_6_1.harm_num + var_6_0
				var_6_5 = true
			end
		end

		if not var_6_5 then
			local var_6_6 = {
				harm_num = var_6_0,
				fighter = var_6_4
			}

			table.insert(arg_6_0.harmEnemies_, var_6_6)
		end

		if arg_6_0.skinSkillID_ == var_0_12 and arg_6_0:getHp() <= arg_6_0:getHpLimit() * var_0_13 and not arg_6_0.skinSkillUsed then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_7 = arg_6_0:createAttackUnits(arg_6_0.selfTeam_, var_0_12)

				for iter_6_2, iter_6_3 in ipairs(var_6_7) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
					table.insert(arg_6_0.records_.special_units, iter_6_3)
				end
			end

			arg_6_0.skinSkillUsed = true
		end
	end

	return var_6_0, var_6_1, var_6_2, var_6_3
end

function var_0_3.toDoPerFrames(arg_7_0)
	if arg_7_0.skinSkillUsed then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			local function var_7_0(arg_8_0)
				if arg_8_0 then
					local var_8_0, var_8_1 = arg_8_0:initAttr()

					arg_8_0.manualRevise = var_8_0 * (arg_8_0.leftCount_ / arg_8_0:getTime() - 1)
					iter_7_1.___attrCache[arg_8_0:getAttrType()] = nil
				end
			end

			local var_7_1 = iter_7_1:getBuffByID(var_0_14)
			local var_7_2 = iter_7_1:getBuffByID(var_0_15)

			var_7_0(var_7_1)
			var_7_0(var_7_2)
		end
	end

	if arg_7_0.energyCount_ then
		arg_7_0.energyCount_ = arg_7_0.energyCount_ - 1

		if arg_7_0.energyCount_ <= 0 or var_0_1.ctx.battle.teamBEnd or var_0_1.ctx.battle.teamAEnd then
			if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
				arg_7_0:updateHp(arg_7_0:getHp() + arg_7_0:getHpLimit() * var_0_16)
			end

			arg_7_0:removeBuffHalo(arg_7_0.energyHalo_)
			arg_7_0:setImmuneControl(false)

			arg_7_0.energyHalo_ = nil
			arg_7_0.energyCount_ = nil
		end
	end

	if arg_7_0:isDeath() then
		return
	end

	if arg_7_0.purpleSkillCount then
		arg_7_0.purpleSkillCount = arg_7_0.purpleSkillCount - 1

		if arg_7_0.purpleSkillCount <= 0 then
			arg_7_0.purpleSkillCount = nil
		end
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_7_2, iter_7_3 in ipairs(arg_7_0:getInfoByKey("unit_info")) do
			local var_7_3 = iter_7_3.target
			local var_7_4 = iter_7_3.skillID

			if arg_7_0.purpleHp_ < arg_7_0:getHpLimit() * var_0_11 and var_0_2.AttackType.CURE ~= var_0_7:type(var_7_4) and var_7_3:getTeamType() == arg_7_0:getTeamType() and arg_7_0:hasDecreaseBuff(var_7_3) then
				arg_7_0.purpleHp_ = math.min(arg_7_0.purpleHp_ + var_0_9 + var_0_10 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple), arg_7_0:getHpLimit() * var_0_11)
			end
		end
	end
end

function var_0_3.hasDecreaseBuff(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getBuffs()

	for iter_9_0, iter_9_1 in ipairs(var_9_0) do
		local var_9_1 = iter_9_1:getTableID()

		if (var_0_8:attr(var_9_1) == var_0_2.AttributeType.AD_JIANSHANG or var_0_8:attr(var_9_1) == var_0_2.AttributeType.AD_JIANSHANG) and (var_0_8:init(var_9_1) < 0 or var_0_8:step(var_9_1) < 0) then
			return true
		end

		if var_0_8:type(var_9_1) == var_0_2.BuffType.SHIELD_BUFF then
			return true
		end
	end

	return false
end

function var_0_3.die(arg_10_0)
	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_10_0.purpleSkillCount and arg_10_0.purpleHp_ > 0 then
		arg_10_0.purpleSkillCount = var_0_6

		arg_10_0:updateHp(arg_10_0.purpleHp_)

		arg_10_0.purpleHp_ = 0

		return
	end

	var_0_3.super.die(arg_10_0)

	if arg_10_0.energyHalo_ then
		arg_10_0:removeBuffHalo(arg_10_0.energyHalo_)
		arg_10_0:setImmuneControl(false)

		arg_10_0.energyCount_ = nil
		arg_10_0.energyHalo_ = nil
	end
end

function var_0_3.checkEnergySkill(arg_11_0)
	if arg_11_0.energyCount_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_11_0)
	end
end

function var_0_3.modelWalk(arg_12_0)
	if not arg_12_0.energyCount_ then
		if arg_12_0.fighterModel:getScale() ~= 1 then
			arg_12_0.fighterModel:scale(1)
		end

		arg_12_0:getFighterModel():walk(true)
	else
		arg_12_0:getFighterModel():playAnimation_("run2", true, nil, nil)
	end
end

function var_0_3.resumeIdle(arg_13_0)
	if not arg_13_0.energyCount_ then
		if not arg_13_0:isDeath() and arg_13_0:getFighterModel() then
			arg_13_0:getFighterModel():idle()
		end
	else
		arg_13_0:getFighterModel():playAnimation_("idle2", true, nil, nil)
	end
end

function var_0_3.selectTargetByTypeD1(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0
	local var_14_1

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.selfTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_14_1 or var_14_1 > iter_14_1:getHp()) then
			var_14_0 = iter_14_1
			var_14_1 = iter_14_1:getHp()
		end
	end

	return {
		var_14_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_15_0, arg_15_1, arg_15_2)
	local function var_15_0(arg_16_0, arg_16_1)
		return arg_16_0.harm_num > arg_16_1.harm_num
	end

	local var_15_1

	table.sort(arg_15_0.harmEnemies_, var_15_0)

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.harmEnemies_) do
		local var_15_2 = iter_15_1.fighter

		if not var_15_2:isDeath() and not var_15_2:isAffected() and var_15_2:getTeamType() ~= arg_15_0:getTeamType() then
			var_15_1 = var_15_2

			break
		end
	end

	arg_15_0.harmEnemies_ = {}
	var_15_1 = var_15_1 or arg_15_0:getNearestTarget()

	return {
		var_15_1
	}
end

return var_0_3
