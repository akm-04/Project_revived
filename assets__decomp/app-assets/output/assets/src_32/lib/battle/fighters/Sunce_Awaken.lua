local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunce", var_0_1.ctx.battle.requireFighter("Sunce"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 7
local var_0_7 = 5
local var_0_8 = 5
local var_0_9 = 0.04
local var_0_10 = 40011671
local var_0_11 = 40002012

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0:getModelID() == var_0_11 then
		arg_2_0.AwakeMarkBuffID = 40012599
	else
		arg_2_0.AwakeMarkBuffID = 40010925
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if not var_0_5:isTriggerSkill(arg_3_1.skillID) and not var_0_5:isReflect(arg_3_1.skillID) then
		if arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() then
			local var_3_0 = arg_3_1.target:getBuffsByID(arg_3_0.AwakeMarkBuffID)

			for iter_3_0, iter_3_1 in ipairs(var_3_0) do
				if iter_3_1:getTableID() == arg_3_0.AwakeMarkBuffID then
					iter_3_1.leftCount_ = iter_3_1:getTime()
				end
			end

			if #var_3_0 < var_0_7 then
				local var_3_1 = arg_3_0:newBuff({
					arg_3_0.AwakeMarkBuffID
				}, arg_3_1.target, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				arg_3_1.target:addBuffs(var_3_1)
			end
		end

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and #arg_3_1.target:getBuffsByID(arg_3_0.AwakeMarkBuffID) >= var_0_8 then
			arg_3_0:addBuffs({
				var_0_4.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
					fighter = arg_3_0,
					target = arg_3_0
				})
			})
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 then
		var_4_2 = var_4_2 + #arg_4_1.target:getBuffsByID(arg_4_0.AwakeMarkBuffID) * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_6
	end

	if arg_4_0:isHasBuffByID(var_0_10) and var_4_2 > 0 then
		var_4_2 = var_4_2 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_9

		arg_4_0:removeBuffByID(var_0_10)

		local var_4_6 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		for iter_4_0, iter_4_1 in ipairs(var_4_6) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_1 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_3),
			skillID = arg_5_3,
			fighter = arg_5_0,
			target = arg_5_2
		})

		var_5_1:setIsHit(true)
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_0, var_5_1)
	end

	return var_5_0
end

return var_0_3
