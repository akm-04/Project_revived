local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiaxu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 80010007
local var_0_5 = 10001178
local var_0_6 = 10001180
local var_0_7 = 10001182
local var_0_8 = 10001183
local var_0_9 = 0.003
local var_0_10 = 40011295
local var_0_11 = 90

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.guaTargets = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_4 then
		for iter_2_0, iter_2_1 in pairs(arg_2_0.guaTargets) do
			if (iter_2_1 == 0 or iter_2_1 == var_0_11) and iter_2_0:isHasBuffByID(var_0_10) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits({
					iter_2_0
				}, var_0_5)

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end

			arg_2_0.guaTargets[iter_2_0] = arg_2_0.guaTargets[iter_2_0] + 1
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID

	if arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_4 and (var_3_0 == arg_3_0:getPugongID() or var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_1 = arg_3_0:getLevel() * var_0_9

		if var_0_2.weightedChoise({
			var_3_1,
			1 - var_3_1
		}) == 1 then
			if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
				local var_3_2 = arg_3_0:createAttackUnits({
					arg_3_1.target
				}, var_0_7)

				for iter_3_0, iter_3_1 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end

				local var_3_3 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_8)

				for iter_3_2, iter_3_3 in ipairs(var_3_3) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			else
				local var_3_4 = arg_3_0:createAttackUnits({
					arg_3_1.target
				}, var_0_6)

				for iter_3_4, iter_3_5 in ipairs(var_3_4) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_5)
					table.insert(arg_3_0.records_.special_units, iter_3_5)
				end
			end
		end
	elseif arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_4 and (var_3_0 == var_0_7 or var_3_0 == var_0_6) and arg_3_1.collisionNum <= 1 then
		arg_3_0.guaTargets[arg_3_1.target] = 0
	end
end

return var_0_3
