local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunce", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = 10350003
local var_0_7 = 0.0025
local var_0_8 = 6000
local var_0_9 = var_0_2.tables.cabinetSkillTable
local var_0_10 = 80010012
local var_0_11 = 40011298
local var_0_12 = 0.08
local var_0_13 = 0.5
local var_0_14 = 20
local var_0_15 = 40011297

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_6)] or 0
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_10 then
		arg_2_0:updateStateNumber(#arg_2_0:getBuffsByID(var_0_15))
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if var_0_4:father(arg_3_1.skillID) == arg_3_0:getEnergySkillID() and arg_3_0.extraSkillLevel > 0 then
		local var_3_0 = arg_3_0:getHpLimit() * arg_3_0.extraSkillLevel * var_0_9:attrValues(var_0_6) * 0.01
		local var_3_1 = var_3_0 + 8 * math.max(arg_3_1.target:getHuJia() - arg_3_0:getDHuJia(), 0)

		if var_3_1 > 0 then
			local var_3_2 = var_3_0 * var_3_0 / var_3_1 * arg_3_1.target:getADJianShang()

			arg_3_4 = arg_3_4 + math.min(var_3_2, var_0_8)
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_10 and arg_4_2 > 0 and arg_4_2 > arg_4_0:getHp() * var_0_12 then
		local var_4_0 = arg_4_2 * var_0_13

		arg_4_2 = 0

		local var_4_1 = var_0_5.new({
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getLevel(),
			skillID = var_0_10,
			fighter = arg_4_1.fighter,
			target = arg_4_0,
			manualHarmRevise = var_4_0 / var_0_14
		})

		arg_4_0:addBuffs({
			var_4_1
		})

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_2 = arg_4_0:createAttackUnits({
				arg_4_0
			}, var_0_10)

			for iter_4_0, iter_4_1 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	end

	return var_0_3.super.applyHurtFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
end

return var_0_3
