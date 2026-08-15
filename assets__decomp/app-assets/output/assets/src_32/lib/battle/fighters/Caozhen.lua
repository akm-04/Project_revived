local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caozhen", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 40012136
local var_0_7 = 0.2
local var_0_8 = 0.005
local var_0_9 = 30
local var_0_10 = {
	40012137,
	40012138
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueTarget = nil
	arg_1_0.blueFighter = nil
	arg_1_0.blueBuff = nil
	arg_1_0.purpleCount = 0

	arg_1_0:listenInfo("unit_info")

	arg_1_0.records_.target_count = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("unit_info")) do
			if iter_2_1.fighter == arg_2_0.blueFighter and iter_2_1.target:getTeamType() ~= arg_2_0:getTeamType() then
				iter_2_1.fighter:removeBuffByID(var_0_6)

				arg_2_0.blueFighter = nil
				arg_2_0.blueBuff = nil
			end
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_2_0.purpleCount <= 0 then
			arg_2_0.purpleCount = var_0_9

			local var_2_0 = arg_2_0:createNewBuffs(var_0_10, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			arg_2_0:addBuffs(var_2_0)
		else
			arg_2_0.purpleCount = arg_2_0.purpleCount - 1
		end
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_6 then
		arg_3_0.blueFighter = arg_3_1.target
		arg_3_0.blueBuff = arg_3_1

		arg_3_0:setRandomTarget()
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.fighter == arg_4_0.blueFighter and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and arg_4_4 > 0 then
		local var_4_0 = var_0_7 + var_0_8 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		arg_4_4 = arg_4_4 + arg_4_0:getAP() * var_4_0
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	if arg_5_1 == arg_5_0.blueTarget then
		arg_5_0:setRandomTarget()
	end
end

function var_0_3.setRandomTarget(arg_6_0)
	if arg_6_0.blueBuff then
		local var_6_0 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
			if iter_6_1 ~= arg_6_0.blueFighter and not iter_6_1:isDeath() and not iter_6_1:isAffected() then
				table.insert(var_6_0, iter_6_1)
			end
		end

		if next(var_6_0) then
			local var_6_1 = 1

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_6_1 = arg_6_0.targetCount_[tostring(var_0_1.ctx.battle.count)] or 1
			else
				var_6_1 = math.random(#var_6_0)
				arg_6_0.records_.target_count[tostring(var_0_1.ctx.battle.count)] = var_6_1
			end

			local var_6_2 = var_6_0[var_6_1]

			arg_6_0.blueBuff:setForceTarget(var_6_2)
		end
	end
end

function var_0_3.setupReport(arg_7_0, arg_7_1)
	var_0_3.super.setupReport(arg_7_0, arg_7_1)

	arg_7_0.targetCount_ = arg_7_1.target_count or {}
end

function var_0_3.writeReport(arg_8_0)
	local var_8_0 = var_0_3.super.writeReport(arg_8_0)

	var_8_0.target_count = arg_8_0.records_.target_count

	return var_8_0
end

return var_0_3
