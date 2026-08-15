local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunqian", var_0_1.ctx.battle.requireFighter("Sunqian"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = {
	40010351,
	40010352
}
local var_0_8 = 40011819
local var_0_9 = 0.4
local var_0_10 = 0.005

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyBuffTargets_ = {}
	arg_1_0.awakeHalo_ = nil
	arg_1_0.awakeTimes_ = 0
	arg_1_0.awakeBuffAttr_ = 0
	arg_1_0.count_ = false
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_0:getEnergySkillID() == arg_2_1.skillID and not arg_2_1.target:isDeath() then
		table.insert(arg_2_0.energyBuffTargets_, arg_2_1.target)
	elseif arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_4:father(arg_2_1.skillID) == arg_2_0:getPugongID() then
		arg_2_1.target:addBuffs({
			var_0_6.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
				fighter = arg_2_0,
				target = arg_2_1.target
			})
		})
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and arg_3_1.target:isSleep() and arg_3_4 > 0 then
		local var_3_0 = var_0_9 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		if var_0_2.weightedChoise({
			var_3_0,
			1 - var_3_0
		}) == 1 then
			arg_3_4 = arg_3_4 * 2
		end
	end

	return var_0_3.super.updateUnitDataBySpecialHero(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.count_ then
		arg_4_0.count_ = true
		arg_4_0.awakeBuffAttr_ = var_0_5:init(var_0_7[1]) + var_0_5:step(var_0_7[1]) * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	end

	if next(arg_4_0.energyBuffTargets_) and var_0_1.ctx.battle.count % 30 < 1 then
		for iter_4_0 = #arg_4_0.energyBuffTargets_, 1, -1 do
			local var_4_0 = arg_4_0.energyBuffTargets_[iter_4_0]

			if var_4_0:isDeath() or not var_4_0:isSleep() then
				table.remove(arg_4_0.energyBuffTargets_, iter_4_0)
			end
		end

		local var_4_1 = #arg_4_0.energyBuffTargets_

		if not arg_4_0.awakeHalo_ and var_4_1 > 0 then
			arg_4_0.awakeTimes_ = var_4_1

			local var_4_2 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
			local var_4_3 = {
				fighter = arg_4_0,
				effect_area = function(arg_5_0)
					return true
				end,
				manualAttr = function()
					return math.max(0, arg_4_0.awakeTimes_ - 3) * arg_4_0.awakeBuffAttr_
				end,
				target_type = var_0_2.HaloEffect.selfTeam,
				buffs = var_0_7,
				level = arg_4_0:getSkillLevelByID(var_4_2),
				skillID = var_4_2
			}

			arg_4_0.awakeHalo_ = var_4_3

			arg_4_0:addBuffHalo(var_4_3)
		elseif arg_4_0.awakeHalo_ and var_4_1 > 0 and var_4_1 ~= arg_4_0.awakeTimes_ then
			arg_4_0.awakeTimes_ = var_4_1
		elseif arg_4_0.awakeHalo_ and var_4_1 == 0 then
			arg_4_0:removeBuffHalo(arg_4_0.awakeHalo_)

			arg_4_0.awakeHalo_ = nil
			arg_4_0.awakeTimes_ = 0
		end
	end
end

return var_0_3
