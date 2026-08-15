local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tier", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 18
local var_0_8 = 10002440
local var_0_9 = 0.2
local var_0_10 = {
	40012054,
	40012055
}
local var_0_11 = 60000
local var_0_12 = {
	40012056,
	40012057,
	40012058
}
local var_0_13 = 40012058
local var_0_14 = 80
local var_0_15 = 0.8
local var_0_16 = 40012642
local var_0_17 = 40012643
local var_0_18 = 600
local var_0_19 = 300
local var_0_20 = 450
local var_0_21 = 450

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energySkillTarget_ = {}
	arg_1_0.energyBackCount_ = nil
	arg_1_0.isAddPurpleBuff = false
	arg_1_0.hpCount = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.target:isDeath() and var_0_6:father(arg_2_1.skillID) == arg_2_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_2_1:recordData(false, false, 0, 0, 0, 0)
	end

	if var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_2_1.target ~= arg_2_0 then
		local var_2_0 = arg_2_1.target:getX()
		local var_2_1 = arg_2_1.target:getY()
		local var_2_2

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			var_2_2 = -1

			arg_2_0:flipX(false)
		else
			var_2_2 = 1

			arg_2_0:flipX(true)
		end

		arg_2_0:x(var_2_0 + 100 * var_2_2)
		arg_2_0:y(var_2_1)

		if arg_2_1.skillID == var_0_8 then
			arg_2_0.energySkillTarget_ = {}
			arg_2_0.energyBackCount_ = var_0_7
		end
	elseif var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_2_3 = arg_2_1.target:getX()
		local var_2_4 = arg_2_1.target:getY()
		local var_2_5

		if arg_2_0:getTeamType() == var_0_2.TeamType.A then
			var_2_5 = -1

			arg_2_0:flipX(false)
		else
			var_2_5 = 1

			arg_2_0:flipX(true)
		end

		arg_2_0:x(var_2_3 + 100 * var_2_5)
		arg_2_0:y(var_2_4)
	elseif var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_6 = arg_2_1.target

		if var_2_6:isSuper() then
			local var_2_7 = arg_2_0:createNewBuffs(var_0_10, var_2_6, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			var_2_6:addBuffs(var_2_7)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_3_0, iter_3_1)
		end
	end

	if next(var_3_0) then
		for iter_3_2, iter_3_3 in ipairs(var_3_0) do
			local var_3_1 = false

			for iter_3_4, iter_3_5 in ipairs(arg_3_0.energySkillTarget_) do
				if iter_3_3 == iter_3_5 then
					var_3_1 = true

					break
				end
			end

			if not var_3_1 then
				table.insert(arg_3_0.energySkillTarget_, iter_3_3)

				return {
					iter_3_3
				}
			end
		end

		arg_3_0.energySkillTarget_ = {}

		return arg_3_0:selectTargetByTypeD1(arg_3_1, arg_3_2)
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			table.insert(var_4_0, iter_4_1)
		end
	end

	local var_4_1
	local var_4_2

	if next(var_4_0) then
		for iter_4_2, iter_4_3 in ipairs(var_4_0) do
			local var_4_3 = iter_4_3:getAP()

			if not var_4_1 or var_4_3 < var_4_2 then
				var_4_1 = iter_4_3
				var_4_2 = var_4_3
			end
		end

		return {
			var_4_1
		}
	else
		return {}
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_5_0.energyPreX_ = arg_5_0:getX()
		arg_5_0.energyPreY_ = arg_5_0:getY()
	end

	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.energyBackCount_ then
		arg_6_0.energyBackCount_ = arg_6_0.energyBackCount_ - 1

		if arg_6_0.energyBackCount_ <= 0 then
			arg_6_0:x(arg_6_0.energyPreX_)
			arg_6_0:y(arg_6_0.energyPreY_)

			arg_6_0.energyPreX_ = nil
			arg_6_0.energyPreY_ = nil
			arg_6_0.energyBackCount_ = nil
		end
	end

	if arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_6_0.isAddPurpleBuff then
		arg_6_0.isAddPurpleBuff = true

		local var_6_0 = 0

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
			if not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None and iter_6_1 ~= arg_6_0 and iter_6_1:isSuper() then
				var_6_0 = var_6_0 + 1
			end
		end

		if var_6_0 > 0 then
			for iter_6_2 = 1, var_6_0 do
				local var_6_1 = arg_6_0:createNewBuffs(var_0_12, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				arg_6_0:addBuffs(var_6_1)
			end
		end
	end

	if var_0_1.ctx.battle.count % var_0_18 == var_0_19 then
		local var_6_2 = arg_6_0:createNewBuffs({
			var_0_16
		}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		arg_6_0:addBuffs(var_6_2)
	elseif var_0_1.ctx.battle.count % var_0_18 == var_0_20 then
		local var_6_3 = arg_6_0:createNewBuffs({
			var_0_17
		}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		arg_6_0:addBuffs(var_6_3)
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	local var_7_0 = arg_7_1.target

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if var_7_0:isSuper() then
			arg_7_4 = arg_7_4 + var_7_0:getAP() * var_0_15
		end
	elseif arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_7_4 = arg_7_4 + math.min(var_7_0:getHp() * var_0_9, var_0_11)
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.getExtraHp(arg_8_0)
	return arg_8_0.hpCount * var_0_14
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_13 then
		arg_9_0.addHp_ = true
		arg_9_0.hpCount = arg_9_0.hpCount + 1

		local var_9_0 = arg_9_0:getHp() + arg_9_0:getExtraHp()

		arg_9_0:updateHp(var_9_0)

		return
	end
end

function var_0_3.getHpLimit(arg_10_0)
	if arg_10_0.addHp_ then
		return var_0_3.super.getHpLimit(arg_10_0) + arg_10_0:getExtraHp()
	end

	return var_0_3.super.getHpLimit(arg_10_0)
end

function var_0_3.getHuJia(arg_11_0)
	local var_11_0 = math.floor(var_0_1.ctx.battle.count / var_0_21)
	local var_11_1 = 1

	if var_11_0 > 0 then
		for iter_11_0 = 1, var_11_0 do
			var_11_1 = var_11_1 * 0.7
		end
	end

	return arg_11_0:getAttrByType(var_0_2.AttributeType.HUJIA) * var_11_1
end

function var_0_3.getMoKang(arg_12_0)
	local var_12_0 = math.floor(var_0_1.ctx.battle.count / var_0_21)
	local var_12_1 = 1

	if var_12_0 > 0 then
		for iter_12_0 = 1, var_12_0 do
			var_12_1 = var_12_1 * 0.7
		end
	end

	return arg_12_0:getAttrByType(var_0_2.AttributeType.MOKANG) * var_12_1
end

return var_0_3
