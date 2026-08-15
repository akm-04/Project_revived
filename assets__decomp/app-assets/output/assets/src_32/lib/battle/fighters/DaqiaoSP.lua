local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("DaqiaoSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = 40012767
local var_0_6 = 0.01
local var_0_7 = 0.0002
local var_0_8 = 10002579
local var_0_9 = 0.1
local var_0_10 = 0.002
local var_0_11 = 20020277
local var_0_12 = 0.2
local var_0_13 = 0.004
local var_0_14 = 40012757
local var_0_15 = 0.01
local var_0_16 = 0.0003
local var_0_17 = {
	40012761,
	40012762
}
local var_0_18 = {
	40012763,
	40012764
}
local var_0_19 = {
	40012765,
	40012766
}
local var_0_20 = 300

function var_0_3.toDoPerFrames(arg_1_0)
	if arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % var_0_20 == 1 then
		local var_1_0
		local var_1_1

		for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
			if iter_1_1 ~= arg_1_0 and not iter_1_1:isDeath() and not iter_1_1:isAffected() and (not var_1_0 or var_1_1 > iter_1_1:getHp() / iter_1_1:getHpLimit()) then
				var_1_0 = iter_1_1
				var_1_1 = iter_1_1:getHp() / iter_1_1:getHpLimit()
			end
		end

		if arg_1_0.purpleTarget and (var_1_0 ~= arg_1_0.purpleTarget or arg_1_0:isDeath()) then
			arg_1_0.purpleTarget:removeBuffByID(var_0_19[1])
			arg_1_0.purpleTarget:removeBuffByID(var_0_19[2])

			arg_1_0.purpleTarget = nil
		end

		if arg_1_0:isDeath() then
			return
		end

		if var_1_0 then
			arg_1_0.purpleTarget = var_1_0

			local var_1_2 = arg_1_0:createNewBuffs(var_0_19, var_1_0, arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_1_0:addBuffs(var_1_2)
		end
	end
end

function var_0_3.buffAddAction(arg_2_0, arg_2_1)
	var_0_3.super.buffAddAction(arg_2_0, arg_2_1)

	if arg_2_1:getTableID() == var_0_5 then
		arg_2_1.manualHarmRevise = (arg_2_1.target:getHpLimit() - arg_2_1.target:getHp()) * (var_0_6 + var_0_7 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
	elseif arg_2_1:getTableID() == var_0_14 then
		arg_2_1.manualHarmRevise = arg_2_1.target:getHpLimit() * (var_0_15 + var_0_16 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	elseif arg_2_1:getTableID() == var_0_17[1] then
		local var_2_0 = arg_2_1.target
		local var_2_1 = arg_2_1:getAttr()
		local var_2_2 = -var_2_0:getAD() * var_2_1
		local var_2_3 = var_0_4.A31(arg_2_0)[1]
		local var_2_4 = arg_2_0:createNewBuffs({
			var_0_18[1]
		}, var_2_3, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		var_2_4[1].manualRevise = var_2_2

		var_2_3:addBuffs(var_2_4)
	elseif arg_2_1:getTableID() == var_0_17[2] then
		local var_2_5 = arg_2_1.target
		local var_2_6 = arg_2_1:getAttr()
		local var_2_7 = -var_2_5:getAP() * var_2_6
		local var_2_8 = var_0_4.A31(arg_2_0)[1]
		local var_2_9 = arg_2_0:createNewBuffs({
			var_0_18[2]
		}, var_2_8, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		var_2_9[1].manualRevise = var_2_7

		var_2_8:addBuffs(var_2_9)
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_8 then
		arg_3_5 = (arg_3_1.target:getHpLimit() - arg_3_1.target:getHp()) * (var_0_9 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))
	elseif arg_3_1.skillID == var_0_11 then
		arg_3_5 = (arg_3_1.target:getHpLimit() - arg_3_1.target:getHp()) * (var_0_12 + var_0_13 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
