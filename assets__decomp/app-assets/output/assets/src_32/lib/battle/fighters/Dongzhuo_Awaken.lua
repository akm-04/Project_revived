local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dongzhuo", var_0_1.ctx.battle.requireFighter("Dongzhuo"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 0
local var_0_6 = 6
local var_0_7 = 40010979
local var_0_8 = {
	40012114,
	40012115
}
local var_0_9 = {
	40012118,
	40012119
}
local var_0_10 = 100
local var_0_11 = 50
local var_0_12 = 200
local var_0_13 = 10001973
local var_0_14 = 30010013
local var_0_15 = 30010016

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceBlueTarget = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if var_0_1.ctx.battle.count % 30 == 0 and not arg_2_0:isDeath() then
		arg_2_0:cureSelfTeam()
		arg_2_0:checkAwakeTwiceBuff()
	end
end

function var_0_3.cureSelfTeam(arg_3_0)
	local var_3_0 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isAffected() and not iter_3_1:isDeath() then
			local var_3_1 = iter_3_1:getHp()
			local var_3_2 = var_0_5 + var_0_6 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

			iter_3_1:updateHp(var_3_1 + var_3_2)

			var_3_0 = var_3_0 + var_3_2
		end
	end

	if arg_3_0.isSkinSkillOn_ and var_3_0 > 0 and arg_3_0.skinCureCount_ < arg_3_0.maxCureToHarm then
		arg_3_0.skinCureCount_ = arg_3_0.skinCureCount_ + var_3_0

		if arg_3_0.skinCureCount_ > arg_3_0.maxCureToHarm then
			arg_3_0.skinCureCount_ = arg_3_0.maxCureToHarm
		end
	end
end

function var_0_3.checkAwakeTwiceBuff(arg_4_0)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_4_0 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:isHasBuffByID(var_0_14) then
				for iter_4_2, iter_4_3 in ipairs(arg_4_0.sideTeam_) do
					if not iter_4_3:isDeath() and not iter_4_3:isAffected() and math.abs(iter_4_1:getX() - iter_4_3:getX()) <= var_0_12 then
						var_4_0[iter_4_3] = true

						if not arg_4_0.awakeTwiceBlueTarget[iter_4_3] then
							local var_4_1 = arg_4_0:createNewBuffs(var_0_9, iter_4_3, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

							iter_4_3:addBuffs(var_4_1)
						end
					end
				end
			end
		end

		for iter_4_4, iter_4_5 in pairs(arg_4_0.awakeTwiceBlueTarget) do
			if not var_4_0[iter_4_4] then
				iter_4_4:removeBuffByID(var_0_9[1])
				iter_4_4:removeBuffByID(var_0_9[2])
			end
		end

		arg_4_0.awakeTwiceBlueTarget = var_4_0
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_4:father(arg_5_1.skillID) == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() then
		local var_5_0 = arg_5_0:createNewBuffs(var_0_8, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_5_1.target:addBuffs(var_5_0)
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_15 and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_6_1.manualDharm = var_0_10 + var_0_11 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	end
end

function var_0_3.beforeDamageHarm(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_1 > 0 and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_7_0:isHasBuffByID(var_0_15) then
		local var_7_0 = arg_7_0:createNewBuffs(var_0_8, arg_7_2.fighter, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

		arg_7_2.fighter:addBuffs(var_7_0)
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_8_1:getTableID() == var_0_15 then
		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() and not iter_8_1:isAffected() and (iter_8_1:isHasBuffByID(var_0_8[1]) or iter_8_1:isHasBuffByID(var_0_8[2]) or iter_8_1:isHasBuffByID(var_0_9[1]) or iter_8_1:isHasBuffByID(var_0_9[2])) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_8_0 = arg_8_0:createAttackUnits({
					iter_8_1
				}, var_0_13)

				for iter_8_2, iter_8_3 in ipairs(var_8_0) do
					table.insert(arg_8_0.moveAttackUnits_, iter_8_3)
					table.insert(arg_8_0.records_.special_units, iter_8_3)
				end
			end
		end
	end
end

return var_0_3
