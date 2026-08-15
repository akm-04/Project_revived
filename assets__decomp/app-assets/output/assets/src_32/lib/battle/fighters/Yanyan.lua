local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yanyan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 10001751
local var_0_5 = 40011881
local var_0_6 = 0.1
local var_0_7 = 4.5
local var_0_8 = 12
local var_0_9 = 80010236
local var_0_10 = {
	40012432,
	40012433
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueCount = 0
	arg_1_0.purpleTarget = nil
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.PurpleBuff = 40012446
	else
		arg_2_0.PurpleBuff = 40011883
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_3_0 = arg_3_0:createNewBuffs({
			var_0_5
		}, arg_3_0, arg_3_1.skillID)

		arg_3_0:addBuffs(var_3_0)
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0.blueCount = 2
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == var_0_4 then
		arg_4_0.blueCount = arg_4_0.blueCount - 1
	end

	if arg_4_0.skinSkillIndex_ == 1 then
		local var_4_0 = arg_4_0:getTargets(arg_4_1.rootID_)

		if #var_4_0 > 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_4_0[1]:getTeamType() ~= arg_4_0:getTeamType() then
			local var_4_1 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_9)

			for iter_4_0, iter_4_1 in ipairs(var_4_1) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		if #var_4_0 > 0 and var_4_0[1]:getTeamType() ~= arg_4_0:getTeamType() then
			for iter_4_2 = 1, #var_4_0 do
				local var_4_2 = arg_4_0:createNewBuffs(var_0_10, arg_4_0, arg_4_0:getEnergySkillID())

				arg_4_0:addBuffs(var_4_2)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % 30 == 1 then
		local var_5_0
		local var_5_1

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			local var_5_2 = iter_5_1:getAttrByType(var_0_2.AttributeType.AGILE)

			if iter_5_1 ~= arg_5_0 and not iter_5_1:isDeath() and not iter_5_1:isAffected() and (not var_5_0 or var_5_1 < var_5_2) then
				var_5_0 = iter_5_1
				var_5_1 = var_5_2
			end
		end

		var_5_0 = var_5_0 or arg_5_0

		if arg_5_0.purpleTarget and arg_5_0.purpleTarget ~= var_5_0 then
			arg_5_0.purpleTarget:removeBuffByID(arg_5_0.PurpleBuff)
			arg_5_0:addPurpleBuff(var_5_0)
		elseif not arg_5_0.purpleTarget then
			arg_5_0:addPurpleBuff(var_5_0)
		end
	end
end

function var_0_3.addPurpleBuff(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0:createNewBuffs({
		arg_6_0.PurpleBuff
	}, arg_6_1, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	arg_6_1:addBuffs(var_6_0)

	arg_6_0.purpleTarget = arg_6_1
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_4 > 0 and arg_7_0.purpleTarget and arg_7_0.purpleTarget ~= arg_7_0 then
		local var_7_0 = var_0_8 * (arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) + 1)

		if arg_7_0:isHasBuffByID(var_0_5) then
			var_7_0 = var_7_0 * 2
		end

		arg_7_0.purpleTarget.fighterModel:playHPDeltas({
			{
				var_7_0,
				false
			}
		}, nil)
		arg_7_0.purpleTarget:updateHp(arg_7_0.purpleTarget:getHp() + var_7_0)
	end

	if arg_7_4 > 0 and arg_7_0:isHasBuffByID(var_0_5) then
		arg_7_4 = arg_7_4 + arg_7_0:getHp() * var_0_6 + var_0_7 * (arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + 1)
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)

	if arg_8_0.blueCount > 0 and var_8_0 == arg_8_0:getPugongID() then
		var_8_0 = var_0_4
	end

	return var_8_0
end

return var_0_3
