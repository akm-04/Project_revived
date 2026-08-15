local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhouyu", var_0_1.ctx.battle.requireFighter("Hide_Zhouyu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000299
local var_0_6 = 40010641

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.effectTarget = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_2_1.skillID == var_0_5 then
		if arg_2_0.effectTarget == arg_2_1.target then
			arg_2_0.effectTarget = 0

			local var_2_0 = arg_2_1.target
			local var_2_1 = math.max(arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake), 20)
			local var_2_2 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(var_2_0:getLevel() - var_2_1, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

			if var_0_2.weightedChoise({
				var_2_2,
				1 - var_2_2
			}) == 1 then
				local var_2_3 = arg_2_0:newBuff({
					var_0_6
				}, arg_2_1.target, arg_2_1.skillID)

				arg_2_1.target:addBuffs(var_2_3)
			else
				var_2_0.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BUFF_MISS
				}, var_2_0:getTeamType())
			end
		else
			arg_2_0.effectTarget = arg_2_1.target
		end
	end
end

function var_0_3.newBuff(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_4.new({
			tableID = iter_3_1,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_3),
			skillID = arg_3_3,
			fighter = arg_3_0,
			target = arg_3_2
		})

		var_3_1:setIsHit(true)
		var_3_1:setDirection(arg_3_0:getFighterModel():getFlipX())
		table.insert(var_3_0, var_3_1)
	end

	return var_3_0
end

return var_0_3
