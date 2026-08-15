local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangping", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000692
local var_0_6 = {
	40010744,
	40010745,
	40010746
}
local var_0_7 = 240
local var_0_8 = -1
local var_0_9 = 5

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleSkillLevel = 0
	arg_1_0.purpleSkillCount_ = 0
	arg_1_0.purpleBuffNum_ = 0
	arg_1_0.purpleSkillJudge_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.purpleSkillJudge_ then
		arg_2_0.purpleSkillJudge_ = true
		arg_2_0.purpleSkillLevel = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		arg_2_0.purpleSkillCount_ = var_0_7 + var_0_8 * arg_2_0.purpleSkillLevel
	end

	if arg_2_0.purpleSkillLevel > 0 and arg_2_0.purpleBuffNum_ < var_0_9 then
		arg_2_0.purpleSkillCount_ = arg_2_0.purpleSkillCount_ - 1

		if arg_2_0.purpleSkillCount_ <= 0 then
			arg_2_0.purpleSkillCount_ = var_0_7 + var_0_8 * arg_2_0.purpleSkillLevel
			arg_2_0.purpleBuffNum_ = arg_2_0.purpleBuffNum_ + 1

			arg_2_0:addPurpleBuff()
		end
	end
end

function var_0_3.addPurpleBuff(arg_3_0)
	local var_3_0 = arg_3_0:newBuff(var_0_6, arg_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	arg_3_0:addBuffs(var_3_0)
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_1 = var_0_4.new({
			tableID = iter_4_1,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(arg_4_3),
			skillID = arg_4_3,
			fighter = arg_4_0,
			target = arg_4_2
		})

		var_4_1:setIsHit(true)
		var_4_1:setDirection(arg_4_0:getFighterModel():getFlipX())
		table.insert(var_4_0, var_4_1)
	end

	return var_4_0
end

function var_0_3.selectTargetByTypeD1(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0
	local var_5_1

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and var_5_0 < iter_5_1:getAttrByType(var_0_2.AttributeType.WISE) then
			var_5_0 = iter_5_1:getAttrByType(var_0_2.AttributeType.WISE)
			var_5_1 = iter_5_1
		end
	end

	return {
		var_5_1
	}
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_1.target.hero_:getHeroType() ~= var_0_2.HeroType.STRENGTH then
		local var_6_0 = {
			arg_6_1.target
		}
		local var_6_1 = arg_6_0:createAttackUnits(var_6_0, var_0_5)

		for iter_6_0, iter_6_1 in ipairs(var_6_1) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

return var_0_3
