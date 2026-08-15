local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qingrenjie", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.cabinetSkillTable
local var_0_8 = 20010190
local var_0_9 = 0
local var_0_10 = 0.75
local var_0_11 = 10390006
local var_0_12 = 40010652
local var_0_13 = 40010653

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.flowers_ = 0
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.currentSkillID_ = nil
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ then
		arg_3_0.FlowerBuffSkill = 10001987
		arg_3_0.FlowerBuff = 40012139
	else
		arg_3_0.FlowerBuffSkill = 10000274
		arg_3_0.FlowerBuff = 20010188
	end
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) < 1 then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(var_0_1.ctx.battle.infoList.unit_info) do
		local var_4_0 = iter_4_1.target
		local var_4_1 = iter_4_1.fighter
		local var_4_2 = iter_4_1.skillID

		if var_4_1 ~= var_4_0 and var_0_6:type(var_4_2) ~= var_0_2.AttackType.CURE and var_4_0:getTeamType() ~= arg_4_0:getTeamType() and var_4_0:isHasBuffByID(var_0_8) and var_4_2 ~= arg_4_0.FlowerBuffSkill then
			local var_4_3 = {
				var_4_0
			}
			local var_4_4 = arg_4_0:createAttackUnits(var_4_3, arg_4_0.FlowerBuffSkill)

			for iter_4_2, iter_4_3 in ipairs(var_4_4) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
				table.insert(arg_4_0.records_.special_units, iter_4_3)

				if var_4_0:getSummonType() == var_0_2.summonMonsterType.None then
					arg_4_0.flowers_ = arg_4_0.flowers_ + 1
				end
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if not arg_5_0.extraSkillJudge then
		arg_5_0.extraSkillJudge = true
		arg_5_0.extraSkillLevel = arg_5_0.hero_:skillBook()[tostring(var_0_11)] or 0
	end

	if arg_5_0.extraSkillLevel > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
				if iter_5_1:isHasBuffByID(arg_5_0.FlowerBuff) and not iter_5_1:isHasBuffByID(var_0_12) then
					local var_5_0 = arg_5_0:newBuffs({
						var_0_12,
						var_0_13
					}, arg_5_0:getEnergySkillID(), arg_5_0.extraSkillLevel, iter_5_1)

					iter_5_1:addBuffs(var_5_0)
				elseif not iter_5_1:isHasBuffByID(arg_5_0.FlowerBuff) and iter_5_1:isHasBuffByID(var_0_12) then
					iter_5_1:removeBuffByID(var_0_12)
					iter_5_1:removeBuffByID(var_0_13)
				end
			end
		end

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_3:isDeath() and not iter_5_3:isAffected() then
				if iter_5_3:isHasBuffByID(arg_5_0.FlowerBuff) and not iter_5_3:isHasBuffByID(var_0_12) then
					local var_5_1 = arg_5_0:newBuffs({
						var_0_12,
						var_0_13
					}, arg_5_0:getEnergySkillID(), arg_5_0.extraSkillLevel, iter_5_3)

					iter_5_3:addBuffs(var_5_1)
				elseif not iter_5_3:isHasBuffByID(arg_5_0.FlowerBuff) and iter_5_3:isHasBuffByID(var_0_12) then
					iter_5_3:removeBuffByID(var_0_12)
					iter_5_3:removeBuffByID(var_0_13)
				end
			end
		end
	end
end

function var_0_3.newBuffs(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_5.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_3,
			skillID = arg_6_2,
			fighter = arg_6_0,
			target = arg_6_4
		})

		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.getAP(arg_7_0)
	local var_7_0 = var_0_3.super.getAP(arg_7_0)
	local var_7_1 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_7_1 > 0 then
		return var_7_0 + (var_7_1 * var_0_10 + var_0_9) * math.min(arg_7_0.flowers_, 30)
	end

	return var_7_0
end

function var_0_3.deathFeedback(arg_8_0, arg_8_1)
	var_0_3.super.deathFeedback(arg_8_0, arg_8_1)

	if arg_8_0:isDeath() or arg_8_1:getTeamType() == arg_8_0:getTeamType() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_8_0 = #arg_8_1:getBuffsByID(arg_8_0.FlowerBuff)

	arg_8_0.flowers_ = arg_8_0.flowers_ - var_8_0

	if var_8_0 > 1 then
		local var_8_1 = var_0_4.A1(arg_8_1, arg_8_0.FlowerBuffSkill)

		if #var_8_1 > 0 then
			arg_8_0.flowers_ = arg_8_0.flowers_ + math.ceil(var_8_0 / 2)
		end

		for iter_8_0 = 1, math.ceil(var_8_0 / 2) do
			local var_8_2 = arg_8_0:createAttackUnits(var_8_1, arg_8_0.FlowerBuffSkill)

			for iter_8_1, iter_8_2 in ipairs(var_8_2) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_2)
				table.insert(arg_8_0.records_.special_units, iter_8_2)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	local var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if var_9_2 > 0 and arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		local var_9_6 = #arg_9_1.target:getBuffsByID(arg_9_0.FlowerBuff)

		arg_9_0.flowers_ = arg_9_0.flowers_ - var_9_6
		var_9_2 = var_9_2 * math.min(var_9_6 + 1, 10)

		if arg_9_0:isDeath() then
			var_9_2 = var_9_2 / 2
		end

		arg_9_1.target:removeBuffByID(arg_9_0.FlowerBuff)
	end

	return var_9_0, var_9_1, var_9_2, var_9_3, var_9_4, var_9_5
end

function var_0_3.die(arg_10_0)
	var_0_3.super.die(arg_10_0)
	arg_10_0:specialAttack()
end

function var_0_3.specialAttack(arg_11_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_11_0 = false

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
		if not iter_11_1:isDeath() or iter_11_1:canReborn() then
			var_11_0 = true
		end
	end

	if not var_11_0 then
		return
	end

	local var_11_1 = arg_11_0:getEnergySkillID()
	local var_11_2 = var_0_4.B2(arg_11_0, var_11_1)

	if next(var_11_2) then
		local var_11_3 = arg_11_0:createAttackUnits(var_11_2, var_11_1)

		for iter_11_2, iter_11_3 in ipairs(var_11_3) do
			iter_11_3.arrived = false

			table.insert(arg_11_0.moveAttackUnits_, iter_11_3)
			table.insert(arg_11_0.records_.special_units, iter_11_3)
		end
	end
end

return var_0_3
