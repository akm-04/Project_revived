local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Masu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = 10000109
local var_0_8 = 80010038
local var_0_9 = 0.5
local var_0_10 = 10
local var_0_11 = 80120038
local var_0_12 = 0.05
local var_0_13 = 2
local var_0_14 = 20010053

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinJudgeCount_ = 0
	arg_1_0.records_.skin_collision_num = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_11 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % 30 == 0 then
		local var_2_0 = arg_2_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsB or var_0_1.ctx.battle.globalBuffsA
		local var_2_1 = arg_2_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

		for iter_2_0, iter_2_1 in pairs(var_2_0) do
			if iter_2_1:getTableID() == var_0_14 then
				var_0_1.ctx.battle.clearAttrCache(var_2_1, iter_2_1:getAttrType())

				iter_2_1.manualRevise = iter_2_1.level_ * iter_2_1:step() * math.min(var_0_12 * (var_0_1.ctx.battle.count - iter_2_1.startCount_) / 30, var_0_13)
			end
		end

		for iter_2_2, iter_2_3 in pairs(arg_2_0.sideTeam_) do
			-- block empty
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID ~= var_0_7 and var_0_4:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_1.target
		local var_3_1 = var_0_4:scope(arg_3_1.skillID)

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= var_3_0 and math.abs(iter_3_1:getX() - var_3_0:getX()) <= var_3_1 / 2 then
				local var_3_2 = arg_3_0:createAttackUnits({
					iter_3_1
				}, var_0_7)

				for iter_3_2, iter_3_3 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	end

	if arg_3_1.skillID ~= var_0_7 and var_0_4:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_8 and arg_3_0.skinJudgeCount_ < var_0_10 then
		arg_3_0.skinJudgeCount_ = arg_3_0.skinJudgeCount_ + 1

		local var_3_3 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_3_0.skinCollisionNum and arg_3_0.skinCollisionNum[tostring(var_0_1.ctx.battle.count)] then
				var_3_3 = true
			end
		else
			var_3_3 = var_0_2.weightedChoise({
				var_0_9,
				1 - var_0_9
			}) == 1

			if var_3_3 then
				arg_3_0.records_.skin_collision_num[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_3_3 then
			arg_3_1:addCollisionNum()
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if var_0_4:father(arg_4_1.rootID_) == arg_4_0:getEnergySkillID() then
		arg_4_0.skinJudgeCount_ = 0
	end
end

function var_0_3.setupReport(arg_5_0, arg_5_1)
	var_0_3.super.setupReport(arg_5_0, arg_5_1)

	arg_5_0.skinCollisionNum = arg_5_1.skin_collision_num
end

function var_0_3.writeReport(arg_6_0)
	local var_6_0 = var_0_3.super.writeReport(arg_6_0)

	var_6_0.skin_collision_num = arg_6_0.records_.skin_collision_num

	return var_6_0
end

return var_0_3
