local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Weiyan", var_0_1.ctx.battle.requireFighter("Weiyan"))
local var_0_4 = var_0_2.tables.hero
local var_0_5 = var_0_2.tables.model
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 40010084
local var_0_9 = 40010085
local var_0_10 = 300
local var_0_11 = 600
local var_0_12 = 90
local var_0_13 = 50010006

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.juggernautCount = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0.juggernautCount then
		arg_2_0.juggernautCount = arg_2_0.juggernautCount - 1

		if arg_2_0.juggernautCount <= 0 then
			arg_2_0.juggernautCount = nil
		end
	end
end

function var_0_3.die(arg_3_0)
	arg_3_0.fighterModel:hideHeaderView()

	if arg_3_0.reviveCount_ then
		-- block empty
	elseif arg_3_0:canReborn() then
		arg_3_0:addSlowDownBuff()

		if not arg_3_0.dieCounts_ then
			arg_3_0.dieCounts_ = {}
		end

		table.insert(arg_3_0.dieCounts_, var_0_1.ctx.battle.count)

		arg_3_0.reviveCount_ = var_0_1.ctx.battle.count + var_0_2.tables.battleConfig.reviveCount

		arg_3_0:getFighterModel():die()

		if var_0_1.ctx.battle.infoListener.death_info then
			table.insert(var_0_1.ctx.battle.infoListener.death_info, arg_3_0)
		end

		return
	end

	arg_3_0.hasReborn_ = true
	arg_3_0.rebornDuration = var_0_11

	var_0_3.super.die(arg_3_0)
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = var_0_7.new({
		tableID = arg_4_1,
		start = var_0_1.ctx.battle.count,
		level = arg_4_3,
		skillID = arg_4_2,
		fighter = arg_4_0,
		target = arg_4_4
	})

	return {
		var_4_0
	}
end

function var_0_3.addSlowDownBuff(arg_5_0)
	local var_5_0 = var_0_9
	local var_5_1 = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	local var_5_2 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			local var_5_3 = arg_5_0:newBuff(var_5_0, var_5_1, var_5_2, iter_5_1)

			iter_5_1:addBuffs(var_5_3)
		end
	end
end

function var_0_3.checkReborn(arg_6_0)
	if arg_6_0.isDead_ then
		return
	end

	if arg_6_0.reviveFinish_ and arg_6_0.reviveFinish_ == var_0_1.ctx.battle.count then
		arg_6_0.reviveFinish_ = nil
		arg_6_0.reviveCount_ = nil
		arg_6_0.hasReborn_ = true
		arg_6_0.juggernautCount = var_0_10
		arg_6_0.rebornDuration = var_0_11

		local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_1 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_2 = var_0_6:init(var_6_0)
		local var_6_3 = var_0_6:step(var_6_0)
		local var_6_4 = math.min(var_6_2 + var_6_3 * var_6_1, arg_6_0:getHpLimit())

		arg_6_0:updateHp(var_6_4)
		arg_6_0.fighterModel:hideHeaderView(true)

		arg_6_0.playReborn_ = false
		arg_6_0.leftInterval_ = 0
		arg_6_0.skillRoll_ = false

		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
			arg_6_0:awakeTwiceSkillDeal()
		end

		arg_6_0:resumeIdle()

		local var_6_5 = var_0_8
		local var_6_6 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
		local var_6_7 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
		local var_6_8 = arg_6_0:newBuff(var_6_5, var_6_6, var_6_7, arg_6_0)

		arg_6_0:addBuffs(var_6_8)
	end

	if not arg_6_0.reviveCount_ or arg_6_0.reviveCount_ > var_0_1.ctx.battle.count or arg_6_0.playReborn_ then
		return
	end

	arg_6_0.playReborn_ = true

	local var_6_9 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_6_10 = var_0_6:attackIndex(var_6_9)
	local var_6_11 = var_0_5:duration(arg_6_0:getModelID(), var_6_10)

	arg_6_0.reviveFinish_ = var_0_1.ctx.battle.count + var_6_11

	if var_6_10 then
		arg_6_0:playAttack(var_6_10, function()
			arg_6_0:resumeIdle()
		end)
	end
end

function var_0_3.isAffected(arg_8_0)
	if arg_8_0.juggernautCount then
		return true
	else
		return var_0_3.super.isAffected(arg_8_0)
	end
end

function var_0_3.getTargets(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.bloodyTarget_ and not arg_9_0.bloodyTarget_:isDeath() and not arg_9_0.bloodyTarget_:isAffected() then
		return {
			arg_9_0.bloodyTarget_
		}
	end

	return var_0_3.super.getTargets(arg_9_0, arg_9_1, arg_9_2)
end

function var_0_3.awakeTwiceSkillDeal(arg_10_0, arg_10_1)
	if not arg_10_1 then
		arg_10_0.atkIncCount = 3
	elseif arg_10_0.juggernautCount then
		arg_10_0.juggernautCount = arg_10_0.juggernautCount + var_0_12
	end

	local var_10_0 = 1
	local var_10_1

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_10_2 = iter_10_1:getHp() / iter_10_1:getHpLimit()

			if var_10_2 < var_10_0 then
				var_10_0 = var_10_2
				var_10_1 = iter_10_1
			end
		end
	end

	if var_10_1 then
		arg_10_0.bloodyTarget_ = var_10_1
	end
end

function var_0_3.deathFeedback(arg_11_0, arg_11_1)
	if arg_11_1 == arg_11_0.bloodyTarget_ then
		arg_11_0.bloodyTarget_ = nil

		arg_11_0:awakeTwiceSkillDeal(true)
	end
end

function var_0_3.createUnits(arg_12_0, arg_12_1)
	if skillID ~= var_0_13 then
		if arg_12_0.atkIncCount then
			arg_12_0.atkInc = true
			arg_12_0.atkIncCount = arg_12_0.atkIncCount - 1

			if arg_12_0.atkIncCount <= 0 then
				arg_12_0.atkIncCount = nil
			end
		else
			arg_12_0.atkInc = nil
		end
	end

	var_0_3.super.createUnits(arg_12_0, arg_12_1)
end

function var_0_3.calculateUnitData(arg_13_0, arg_13_1)
	local var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5 = var_0_3.super.calculateUnitData(arg_13_0, arg_13_1)

	if arg_13_1.skillID ~= var_0_13 and arg_13_0.atkInc then
		var_13_2 = var_13_2 + arg_13_0:getIncV()
	end

	return var_13_0, var_13_1, var_13_2, var_13_3, var_13_4, var_13_5
end

function var_0_3.getIncV(arg_14_0)
	local var_14_0 = arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	local var_14_1 = arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice)
	local var_14_2 = var_0_6:init(var_14_0)
	local var_14_3 = var_0_6:step(var_14_0)

	return (arg_14_0:getHpLimit() - arg_14_0:getHp()) * (var_14_2 + var_14_3 * var_14_1) / 100
end

return var_0_3
