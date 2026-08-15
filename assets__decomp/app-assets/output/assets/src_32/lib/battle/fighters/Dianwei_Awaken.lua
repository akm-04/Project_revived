local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dianwei", var_0_1.ctx.battle.requireFighter("Dianwei"))
local var_0_4 = 10000134
local var_0_5 = 0.05
local var_0_6 = 0
local var_0_7 = 0.004
local var_0_8 = 10000685

function var_0_3.die(arg_1_0)
	arg_1_0:deathSkill()
	var_0_3.super.die(arg_1_0)
end

function var_0_3.deathSkill(arg_2_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_2_0 = false

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
		if not iter_2_1:isDeath() or iter_2_1:canReborn() then
			var_2_0 = true
		end
	end

	if not var_2_0 then
		return
	end

	local var_2_1 = {}

	for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_3:isDeath() and not iter_2_3:isAffected() then
			table.insert(var_2_1, iter_2_3)
		end
	end

	if next(var_2_1) then
		local var_2_2 = arg_2_0:createAttackUnits(var_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_2_4, iter_2_5 in ipairs(var_2_2) do
			iter_2_5.arrived = false

			table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
			table.insert(arg_2_0.records_.special_units, iter_2_5)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_6 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

	if var_3_6 > 0 then
		if arg_3_1.skillID == var_0_4 or arg_3_1.rootSkill == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_3_1.skillID == arg_3_0:getEnergySkillID() then
			local var_3_7 = arg_3_1.target:getAP()

			var_3_2 = var_3_2 + (var_0_6 + var_0_7 * var_3_6) * var_3_7 * arg_3_1.target:getAPJianShang()

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_8 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_8)

				for iter_3_0, iter_3_1 in ipairs(var_3_8) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
					table.insert(arg_3_0.records_.special_units, iter_3_1)
				end
			end
		elseif arg_3_1.skillID == var_0_8 then
			var_3_2 = var_3_2 + arg_3_0:getHp() * var_0_5
		end
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

return var_0_3
