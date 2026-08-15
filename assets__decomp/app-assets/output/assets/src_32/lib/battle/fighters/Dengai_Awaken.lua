local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dengai", var_0_1.ctx.battle.requireFighter("Dengai"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 20010264
local var_0_9 = 120
local var_0_10 = {
	20010117,
	20010118,
	20010119,
	20010120
}
local var_0_11 = 20010118
local var_0_12 = 286
local var_0_13 = 18

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceTarget_ = {}
end

function var_0_3.deathFeedback(arg_2_0, arg_2_1)
	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) < 1 and not arg_2_0.isEnergyBuff_ then
		return
	end

	if arg_2_0.awakeTwiceTarget_[arg_2_1] then
		for iter_2_0, iter_2_1 in ipairs(var_0_10) do
			local var_2_0 = arg_2_0:getBuffByID(iter_2_1)

			if var_2_0 then
				var_2_0:setExtraTime(var_2_0.extraTime_ + var_0_9)

				if iter_2_1 == var_0_11 then
					var_2_0.manualRevise = var_2_0.manualRevise + (var_0_12 + var_0_13 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice))
					arg_2_0.___attrCache[var_2_0:getAttrType()] = nil
				end
			end
		end

		arg_2_0.awakeTwiceTarget_[arg_2_1] = false

		arg_2_0:afterKillAttack()
	end
end

function var_0_3.afterKillAttack(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_3_1 = var_0_7:sound(var_3_0)

	var_0_1.ctx.battle.pushSoundQueue(var_3_1)

	local var_3_2 = var_0_7:attackIndex(var_3_0)

	arg_3_0:playAttack(var_3_2)

	arg_3_0.unitSkills_ = var_0_5.new({
		fighter = arg_3_0,
		skillID = var_3_0
	})

	arg_3_0:beginAttackEnd(arg_3_0.unitSkills_)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		local var_4_0 = arg_4_1.target

		if arg_4_0.isEnergyBuff_ and var_4_0:getTeamType() ~= arg_4_0:getTeamType() and var_4_0:getSummonType() == var_0_2.summonMonsterType.None then
			arg_4_0.awakeTwiceTarget_[var_4_0] = true
		end

		if arg_4_0:getEnergySkillID() == arg_4_1.skillID then
			arg_4_0.awakeTwiceTarget_ = {}
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.updateBaseInfo(arg_5_0)
	var_0_3.super.updateBaseInfo(arg_5_0)

	if arg_5_0.isEnergyBuff_ then
		if not arg_5_0.isAddBuff then
			for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
				if not iter_5_1:isAffected() and not iter_5_1:isDeath() then
					local var_5_0 = {
						tableID = var_0_8,
						start = var_0_1.ctx.battle.count,
						level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
						skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
						fighter = arg_5_0,
						target = iter_5_1
					}

					iter_5_1:addBuffs({
						var_0_4.new(var_5_0)
					})
				end
			end

			arg_5_0.isAddBuff = true
		end
	else
		arg_5_0.isAddBuff = false
	end
end

return var_0_3
