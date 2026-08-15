local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuchu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.hero
local var_0_7 = var_0_2.tables.model
local var_0_8 = 10350004
local var_0_9 = 40010269
local var_0_10 = 0.06
local var_0_11 = var_0_2.tables.cabinetSkillTable
local var_0_12 = 80010011
local var_0_13 = 10001067
local var_0_14 = 0.004
local var_0_15 = 0.05
local var_0_16 = 6

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.xuanYunCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_8)] or 0
	end

	if arg_2_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_2_0.isSkinSkillOn_ then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and arg_2_0.xuanYunCount[iter_2_1] and arg_2_0.xuanYunCount[iter_2_1] >= var_0_16 then
				local var_2_0 = arg_2_0:createAttackUnits({
					iter_2_1
				}, var_0_13)

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end

				arg_2_0.xuanYunCount[iter_2_1] = 0
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.isSkinSkillOn_ and (var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_3_0 == arg_3_0:getPugongID()) then
		local var_3_1 = arg_3_0:getLevel() * var_0_14

		if var_0_2.weightedChoise({
			var_3_1,
			1 - var_3_1
		}) == 1 then
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_12)

			for iter_3_0, iter_3_1 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end

			if not arg_3_0.xuanYunCount[arg_3_1.target] then
				arg_3_0.xuanYunCount[arg_3_1.target] = 0
			end

			arg_3_0.xuanYunCount[arg_3_1.target] = arg_3_0.xuanYunCount[arg_3_1.target] + 1
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == var_0_13 and arg_4_0.isSkinSkillOn_ then
		var_4_2 = (arg_4_0:getHpLimit() - arg_4_0:getHp()) * var_0_15
		var_4_4 = (arg_4_0:getHpLimit() - arg_4_0:getHp()) * var_0_15
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
	if arg_5_0.extraSkillLevel > 0 then
		local var_5_0 = arg_5_1.fighter

		if arg_5_1.skillID == var_5_0:getPugongID() and var_0_6:distanceType(var_5_0:getTableID()) == var_0_2.DistanceType.QIANPAI then
			local var_5_1 = var_0_11:attrValues(var_0_8) * arg_5_0.extraSkillLevel

			if var_0_2.weightedChoise({
				var_5_1,
				1 - var_5_1
			}) == 1 then
				local var_5_2 = var_0_4.new({
					tableID = var_0_9,
					start = var_0_1.ctx.battle.count,
					level = arg_5_0.extraSkillLevel,
					skillID = arg_5_0:getEnergySkillID(),
					fighter = arg_5_0,
					target = var_5_0
				})

				var_5_0:addBuffs({
					var_5_2
				})
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5)
end

function var_0_3.selectFarTarget(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_6_1 = arg_6_1.target
	local var_6_2 = math.abs(arg_6_1.target:getX() - arg_6_0:getX())

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_2 < math.abs(iter_6_1:getX() - arg_6_0:getX()) then
			var_6_2 = math.abs(iter_6_1:getX() - arg_6_0:getX())
			var_6_1 = iter_6_1
		end
	end

	return var_6_1
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}
	local var_7_1 = arg_7_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	for iter_7_0, iter_7_1 in ipairs(var_7_1) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(iter_7_1:getX() - arg_7_2.target:getX()) < var_0_5:scope(arg_7_1) / 2 then
			table.insert(var_7_0, iter_7_1)
		end
	end

	return var_7_0
end

function var_0_3.checkUnitBuffs(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1.target:isDeath() then
		return
	end

	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4 = var_0_3.super.checkUnitBuffs(arg_8_0, arg_8_1, arg_8_2)

	for iter_8_0, iter_8_1 in ipairs(var_8_0) do
		if iter_8_1:getYx() > 0 then
			if arg_8_1.manualPosition_ then
				iter_8_1:resetYXChange(arg_8_1.manualPosition_[1], arg_8_1.manualPosition_[2])
			else
				local var_8_5 = arg_8_0:selectFarTarget(iter_8_1)

				iter_8_1:resetYXChange(var_8_5:getX() + 1, var_8_5:getY())
			end
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_1:getYx() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_9_0 = arg_9_1:getRemoveSkill()
	local var_9_1 = arg_9_0:selectTargetByTypeD1(var_9_0, arg_9_1)
	local var_9_2 = arg_9_0:createAttackUnits(var_9_1, var_9_0)

	for iter_9_0, iter_9_1 in ipairs(var_9_2) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
		table.insert(arg_9_0.records_.special_units, iter_9_1)
	end
end

return var_0_3
