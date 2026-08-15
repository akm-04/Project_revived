local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Feiyi", var_0_1.ctx.battle.requireFighter("Feiyi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 0.004
local var_0_7 = 0
local var_0_8 = 30000
local var_0_9 = 40010994
local var_0_10 = 10000911
local var_0_11 = 40012132
local var_0_12 = 40012133
local var_0_13 = 10001983
local var_0_14 = 0
local var_0_15 = 0.001
local var_0_16 = 40012659

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeDeHp = 0
	arg_1_0.createAwakeSkill = false
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	if arg_2_1:getTableID() == var_0_12 then
		local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_6 + var_0_7
		local var_2_1 = arg_2_1.target:getHpLimit() * var_2_0

		if var_2_1 > var_0_8 then
			var_2_1 = var_0_8
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			arg_2_1:setManualDharm(var_2_1)
		end
	end

	if arg_2_1:getTableID() == var_0_9 or arg_2_1:getTableID() == var_0_11 then
		arg_2_0.createAwakeSkill = false

		local var_2_2 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_6 + var_0_7
		local var_2_3 = arg_2_1.target:getHpLimit() * var_2_2

		if var_2_3 > var_0_8 then
			var_2_3 = var_0_8
		end

		arg_2_0.awakeDeHp = arg_2_0.awakeDeHp + var_2_3

		table.insert(arg_2_0.energyTargets_, {
			target = arg_2_1.target,
			dHp = var_2_3
		})

		local var_2_4 = arg_2_1.target:getTempHpLimit() + var_2_3

		arg_2_1.target:setTempHpLimit(var_2_4)

		local var_2_5 = arg_2_1.target:getHp()

		if var_2_5 > arg_2_1.target:getHpLimit() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_6 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_10)

			for iter_2_0, iter_2_1 in ipairs(var_2_6) do
				iter_2_1.change_harm = var_2_5 - arg_2_1.target:getHpLimit()

				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end

	if arg_2_1:getTableID() == var_0_16 then
		arg_2_1.manualRevise = arg_2_0.awakeDeHp * (var_0_14 + var_0_15 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
		arg_2_0.awakeDeHp = 0
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getTableID() == var_0_9 or arg_3_1:getTableID() == var_0_11 then
		for iter_3_0 = 1, #arg_3_0.energyTargets_ do
			if arg_3_0.energyTargets_[iter_3_0].target == arg_3_1.target then
				local var_3_0 = arg_3_1.target:getTempHpLimit() - arg_3_0.energyTargets_[iter_3_0].dHp

				arg_3_1.target:setTempHpLimit(var_3_0)
				table.remove(arg_3_0.energyTargets_, iter_3_0)

				break
			end
		end

		if not arg_3_0.createAwakeSkill then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_1 = arg_3_0:createAttackUnits({
					arg_3_0
				}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_3_1, iter_3_2 in ipairs(var_3_1) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_2)
					table.insert(arg_3_0.records_.special_units, iter_3_2)
				end
			end

			arg_3_0.createAwakeSkill = true
		end
	end
end

return var_0_3
