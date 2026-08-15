local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xueying", var_0_1.ctx.battle.requireFighter("Xueying"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011534

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakenAimedTarget = nil
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.AwakeAimedTargetBuff = 40012301
	else
		arg_2_0.AwakeAimedTargetBuff = 40011535
	end
end

function var_0_3.selectTargetByTypeD3(arg_3_0, arg_3_1, arg_3_2)
	return {
		arg_3_0.awakenAimedTarget
	}
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	var_0_3.super.toDoPerFrames(arg_4_0)

	local var_4_0 = arg_4_0.awakenAimedTarget
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.targetTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and (not var_4_1 or var_4_1 > iter_4_1:getHuJia()) then
			var_4_1 = iter_4_1:getHuJia()
			arg_4_0.awakenAimedTarget = iter_4_1
		end
	end

	if var_4_0 ~= arg_4_0.awakenAimedTarget then
		arg_4_0.awakenAimedTarget:addBuffs({
			var_0_4.new({
				tableID = arg_4_0.AwakeAimedTargetBuff,
				start = var_0_1.ctx.battle.count,
				level = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_4_0,
				target = arg_4_0.awakenAimedTarget
			})
		})

		if var_4_0 then
			var_4_0:removeBuffByID(arg_4_0.AwakeAimedTargetBuff)
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.skillID
	local var_5_1 = arg_5_1.target

	if var_5_1 == arg_5_0.awakenAimedTarget and var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_5_1.mustBaoji = true
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_5_2 = var_5_1:getBuffByID(var_0_6)

		if var_5_2 then
			var_5_2:setForceTarget(arg_5_0)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0 = arg_6_1.fighter
	local var_6_1 = arg_6_1.target

	if var_6_0 == arg_6_0.awakenAimedTarget and var_6_1 == arg_6_0 and arg_6_4 > 0 then
		arg_6_4 = math.max(0.9 - 0.004 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake), 0) * arg_6_4
	end

	if var_6_0 == arg_6_0 and var_6_1 == arg_6_0.awakenAimedTarget and arg_6_3 then
		local var_6_2 = arg_6_0:createAttackUnits({
			var_6_1
		}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

return var_0_3
