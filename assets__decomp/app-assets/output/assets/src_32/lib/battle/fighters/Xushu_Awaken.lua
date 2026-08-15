local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xushu", var_0_1.ctx.battle.requireFighter("Xushu"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 0
local var_0_7 = 0.08
local var_0_8 = 40011368
local var_0_9 = 300
local var_0_10 = 30

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.extraMP_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_1.ctx.battle.count > 1 and var_0_1.ctx.battle.count % var_0_9 == 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() then
				local var_2_0 = iter_2_1:getBuffs()
				local var_2_1 = false

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					if var_0_5:dbuffType(iter_2_3:getTableID()) == var_0_2.DBuffType.CHEN_MO and iter_2_3:getTableID() ~= var_0_8 then
						iter_2_3.leftCount_ = iter_2_3.leftCount_ + var_0_10
						var_2_1 = true

						break
					end
				end

				if not var_2_1 then
					local var_2_2 = var_0_4.new({
						tableID = var_0_8,
						start = var_0_1.ctx.battle.count,
						level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice),
						skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice),
						fighter = arg_2_0,
						target = iter_2_1
					})

					iter_2_1:addBuffs({
						var_2_2
					})
				end
			end
		end
	end

	if var_0_1.ctx.battle.count ~= 1 then
		return
	end

	arg_2_0:checkWiseNum()
end

function var_0_3.checkWiseNum(arg_3_0)
	local var_3_0 = 0
	local var_3_1 = 0
	local var_3_2 = arg_3_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	local var_3_3 = arg_3_0:getTeamType() ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	for iter_3_0, iter_3_1 in ipairs(var_3_2) do
		if not iter_3_1:isDeath() and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None and iter_3_1.hero_:getHeroType() == var_0_2.HeroType.WISE then
			var_3_0 = var_3_0 + 1
		end
	end

	for iter_3_2, iter_3_3 in ipairs(var_3_3) do
		if not iter_3_3:isDeath() and iter_3_3:getSummonType() == var_0_2.summonMonsterType.None and iter_3_3.hero_:getHeroType() == var_0_2.HeroType.WISE then
			var_3_1 = var_3_1 + 1
		end
	end

	if var_3_0 < var_3_1 then
		arg_3_0.extraMP_ = (var_3_1 - var_3_0) * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * var_0_7
	else
		arg_3_0.extraMP_ = 0
	end
end

function var_0_3.deathFeedback(arg_4_0)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) < 1 then
		return
	end

	arg_4_0:checkWiseNum()
end

function var_0_3.getCountReMp(arg_5_0)
	return var_0_3.super.getCountReMp(arg_5_0) + arg_5_0.extraMP_
end

return var_0_3
