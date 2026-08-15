local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.requireFighter("Xiaowu"))
local var_0_4 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.magicCritHarms_ = 0
	arg_1_0.count_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if not arg_2_0.count_ then
		arg_2_0.count_ = true

		local var_2_0 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_1 = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_2_2 = var_0_4:descNumInit(var_2_1)[1]
		local var_2_3 = var_0_4:descNumStep(var_2_1)[1]
		local var_2_4 = var_0_4:descNumInit(var_2_1)[2] * 0.01
		local var_2_5 = var_0_4:descNumStep(var_2_1)[2] * 0.01

		arg_2_0.awakeHarm_ = math.max(var_2_2 + var_2_3 * var_2_0, 0)
		arg_2_0.awakeHarmRate_ = math.max(var_2_4 + var_2_5 * var_2_0, 0)
	end

	if not arg_2_0:isDeath() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("magic_crit_info")) do
			arg_2_0.magicCritHarms_ = math.min(arg_2_0.awakeHarm_, arg_2_0.magicCritHarms_ + iter_2_1[2])
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
				table.insert(var_3_0, iter_3_1)
			end
		end

		local var_3_1 = arg_3_0:createAttackUnits(var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		for iter_3_2, iter_3_3 in ipairs(var_3_1) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		local var_4_0 = arg_4_0.awakeHarmRate_ * arg_4_0.magicCritHarms_

		if var_4_0 > 0 then
			arg_4_4 = arg_4_4 + var_4_0 * var_4_0 / (var_4_0 + 12 * math.max(arg_4_1.target:getMoKang() - arg_4_0:getDMoKang(), 0)) * arg_4_1.target:getAPJianShang()
		end
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

return var_0_3
