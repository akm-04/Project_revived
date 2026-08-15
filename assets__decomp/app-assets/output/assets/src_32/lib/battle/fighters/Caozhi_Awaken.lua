local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caozhi", var_0_1.ctx.battle.requireFighter("Caozhi"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010457
}
local var_0_6 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTargets_ = {}
	arg_1_0.awakeBuffTargets_ = {}
	arg_1_0.saveHeroNums_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if not arg_2_0:isDeath() and arg_2_0.saveHeroNums_ < var_0_6 and var_0_1.ctx.battle.count % 30 < 1 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and not arg_2_0.awakeBuffTargets_[iter_2_1] and not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				arg_2_0.awakeBuffTargets_[iter_2_1] = true

				local var_2_0 = arg_2_0:newBuff(var_0_5, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end
end

function var_0_3.neverDieFeedBack(arg_3_0, arg_3_1)
	arg_3_1:updateHp(1)

	local var_3_0 = arg_3_0:newBuff({
		40010456
	}, arg_3_1, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	arg_3_1:addBuffs(var_3_0)

	arg_3_0.saveHeroNums_ = arg_3_0.saveHeroNums_ + 1

	if arg_3_0.saveHeroNums_ >= var_0_6 then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.awakeBuffTargets_) do
			if iter_3_0:isHasBuffByID(unpack(var_0_5)) then
				for iter_3_2, iter_3_3 in ipairs(var_0_5) do
					iter_3_0:removeBuffByID(iter_3_3)
				end
			end
		end
	end
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

return var_0_3
