local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caohong", var_0_1.ctx.battle.requireFighter("Caohong"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = {
	40010273,
	40010274
}
local var_0_6 = {
	40010271,
	40010272
}
local var_0_7 = {
	40010609,
	40010610,
	40010611,
	40010612
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeTwiceAliveNum_ = 0
	arg_1_0.records_.buff_one = {}
	arg_1_0.records_.buff_two = {}
end

function var_0_3.die(arg_2_0)
	var_0_3.super.die(arg_2_0)

	if arg_2_0:isNeverDie() then
		return
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
		if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
			local var_2_0 = arg_2_0:newBuff(var_0_6, iter_2_1, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

			iter_2_1:addBuffs(var_2_0)
		end
	end

	if arg_2_0.killer_ and not arg_2_0.killer_:isDeath() and not arg_2_0.killer_:isAffected() then
		local var_2_1 = arg_2_0:newBuff(var_0_5, arg_2_0.killer_, arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		arg_2_0.killer_:addBuffs(var_2_1)
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		if arg_2_0.killer_ then
			local var_2_2 = 1
			local var_2_3

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				var_2_2 = arg_2_0.buffOne_[tostring(var_0_1.ctx.battle.count)] or 1
				var_2_3 = arg_2_0.buffTwo_[tostring(var_0_1.ctx.battle.count)] or 2
			else
				var_2_2 = math.random(1, #var_0_7)

				while not var_2_3 or var_2_3 == var_2_2 do
					var_2_3 = math.random(1, #var_0_7)
				end

				arg_2_0.records_.buff_one[tostring(var_0_1.ctx.battle.count)] = var_2_2
				arg_2_0.records_.buff_two[tostring(var_0_1.ctx.battle.count)] = var_2_3
			end

			local var_2_4 = {}

			for iter_2_2, iter_2_3 in ipairs(var_0_7) do
				if iter_2_2 == var_2_2 or iter_2_2 == var_2_3 then
					table.insert(var_2_4, iter_2_3)
				end
			end

			local var_2_5 = arg_2_0:newBuff(var_2_4, arg_2_0.killer_, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			arg_2_0.killer_:addBuffs(var_2_5)
		end

		local var_2_6 = {}

		for iter_2_4, iter_2_5 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_5:isDeath() and not iter_2_5:isAffected() and iter_2_5:getSummonType() == var_0_2.summonMonsterType.None then
				arg_2_0.awakeTwiceAliveNum_ = arg_2_0.awakeTwiceAliveNum_ + 1

				if iter_2_5 ~= arg_2_0.killer_ then
					table.insert(var_2_6, iter_2_5)
				end
			end
		end

		for iter_2_6, iter_2_7 in ipairs(var_2_6) do
			local var_2_7 = math.random(1, #var_0_7)
			local var_2_8 = arg_2_0:newBuff({
				var_0_7[var_2_7]
			}, iter_2_7, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			iter_2_7:addBuffs(var_2_8)
		end
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	var_0_3.super.buffAddAction(arg_3_0, arg_3_1)

	if arg_3_1:getSkillID() == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice) then
		arg_3_1:setExtraTime(arg_3_0.awakeTwiceAliveNum_ * 60)
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

function var_0_3.setupReport(arg_5_0, arg_5_1)
	var_0_3.super.setupReport(arg_5_0, arg_5_1)

	arg_5_0.buffOne_ = arg_5_1.buff_one or {}
	arg_5_0.buffTwo_ = arg_5_1.buff_two or {}
end

function var_0_3.writeReport(arg_6_0)
	local var_6_0 = var_0_3.super.writeReport(arg_6_0)

	var_6_0.buff_one = arg_6_0.records_.buff_one
	var_6_0.buff_two = arg_6_0.records_.buff_two

	return var_6_0
end

return var_0_3
