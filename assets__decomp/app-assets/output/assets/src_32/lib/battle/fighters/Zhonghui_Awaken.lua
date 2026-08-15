local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhonghui", var_0_1.ctx.battle.requireFighter("Zhonghui"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000508
local var_0_7 = 40010356

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyUseTimes_ = 0
	arg_1_0.awakeExtraHarmRate_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_6 and arg_2_0.energyUseTimes_ > 0 then
		local var_2_0 = arg_2_1.skillID
		local var_2_1 = var_0_4.new({
			tableID = var_0_7,
			start = var_0_1.ctx.battle.count,
			level = arg_2_0:getSkillLevelByID(var_2_0),
			skillID = var_2_0,
			fighter = arg_2_0,
			target = arg_2_1.target
		})

		var_2_1:setIsHit(true)
		var_2_1:setDirection(arg_2_1.target:getFighterModel():getFlipX())
		arg_2_1.target:addBuffs({
			var_2_1
		})
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.count_ then
		local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)

		arg_3_0.awakeExtraHarmRate_ = var_0_5:descNumInit(var_3_0)[2] * 0.01 + var_0_5:descNumStep(var_3_0)[2] * 0.01 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	var_0_3.super.toDoPerFrames(arg_3_0)
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	if arg_4_0.energySelfTarget_ and arg_4_0.energySelfTarget_ == arg_4_1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = {}
		local var_4_1 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_4_2 = var_0_5:scope(var_4_1)

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_1:isDeath() and not iter_4_1:isAffected() and math.abs(iter_4_1:getX() - arg_4_0:getX()) <= var_4_2 * 0.5 then
				table.insert(var_4_0, iter_4_1)
			end
		end

		local var_4_3 = arg_4_0:createAttackUnits(var_4_0, var_4_1)

		for iter_4_2, iter_4_3 in ipairs(var_4_3) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end

	var_0_3.super.deathFeedback(arg_4_0, arg_4_1)
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == var_0_6 then
		var_5_2 = var_5_2 * (1 + arg_5_0.awakeExtraHarmRate_ * arg_5_0.energyUseTimes_)
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		arg_6_0.energyUseTimes_ = arg_6_0.energyUseTimes_ + 1
	end
end

return var_0_3
