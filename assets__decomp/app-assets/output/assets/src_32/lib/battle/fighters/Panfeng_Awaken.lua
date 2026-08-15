local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Panfeng", var_0_1.ctx.battle.requireFighter("Panfeng"))
local var_0_4 = 40012076
local var_0_5 = 10001926

function var_0_3.applySingleUnit(arg_1_0, arg_1_1)
	var_0_3.super.applySingleUnit(arg_1_0, arg_1_1)

	if arg_1_1.skillID == arg_1_0:getEnergySkillID() then
		arg_1_0:awakeSkill()
	end
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.rootID_

	if arg_2_0.awakeTarget and not arg_2_0.awakeTarget:isDeath() and not arg_2_0.awakeTarget:isAffected() and var_2_0 ~= var_0_5 and var_2_0 ~= arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_1 = arg_2_0:createAttackUnits({
			arg_2_0
		}, var_0_5)

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end
end

function var_0_3.awakeSkill(arg_3_0)
	local var_3_0 = arg_3_0.awakeTarget
	local var_3_1

	if not var_3_0 or var_3_0:isDeath() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if iter_3_1 ~= arg_3_0 and not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1.hero_:getDistanceType() == var_0_2.DistanceType.QIANPAI and (not var_3_0 or var_3_1 > math.abs(arg_3_0:getX() - iter_3_1:getX())) then
				var_3_0 = iter_3_1
				var_3_1 = math.abs(arg_3_0:getX() - iter_3_1:getX())
			end
		end
	end

	if var_3_0 and not var_3_0:isDeath() then
		arg_3_0.awakeTarget = var_3_0

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_3_2 = arg_3_0:createAttackUnits({
				var_3_0
			}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

			for iter_3_2, iter_3_3 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	end
end

function var_0_3.neverDieFeedBack(arg_4_0, arg_4_1)
	var_0_3.super.neverDieFeedBack(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_0:createNewBuffs({
		var_0_4
	}, arg_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	arg_4_1:addBuffs(var_4_0)
end

return var_0_3
