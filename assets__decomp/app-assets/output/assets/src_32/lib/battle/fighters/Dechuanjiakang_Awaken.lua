local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dechuanjiakang", var_0_1.ctx.battle.requireFighter("Dechuanjiakang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 1
local var_0_8 = 20
local var_0_9 = 0.1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeQiShiCount = 0
	arg_1_0.qiShiCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.qiShiCount >= var_0_8 then
		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			local var_2_0 = math.ceil(var_0_9 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			arg_2_0.qiShiCount = math.min(var_2_0, arg_2_0.qiShiCount)

			arg_2_0:createAwakeUnit()
		else
			arg_2_0.awakeQiShiCount = arg_2_0.qiShiCount
			arg_2_0.qiShiCount = 0

			arg_2_0:updateHp(0)
			arg_2_0:forceDie()
		end
	end
end

function var_0_3.forceDie(arg_3_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (arg_3_0.qiShiCount >= var_0_7 or arg_3_0.awakeQiShiCount >= var_0_7) then
		local var_3_0 = false

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() or iter_3_1:canReborn() then
				var_3_0 = true
			end
		end

		if var_3_0 then
			local var_3_1 = arg_3_0:getTargets(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
			local var_3_2 = arg_3_0:createAttackUnits(var_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			for iter_3_2, iter_3_3 in ipairs(var_3_2) do
				iter_3_3.arrived = false

				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end

	var_0_3.super.forceDie(arg_3_0)
end

function var_0_3.createAwakeUnit(arg_4_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and (arg_4_0.qiShiCount >= var_0_7 or arg_4_0.awakeQiShiCount >= var_0_7) then
		local var_4_0 = arg_4_0:getTargets(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
		local var_4_1 = arg_4_0:createAttackUnits(var_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			iter_4_1.arrived = false

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_4 > 0 and arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		arg_5_4 = arg_5_4 * (1 + (math.max(arg_5_0.qiShiCount, arg_5_0.awakeQiShiCount) - var_0_7) * 0.1)
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

return var_0_3
