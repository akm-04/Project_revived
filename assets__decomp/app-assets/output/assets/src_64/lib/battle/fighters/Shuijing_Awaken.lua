local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shuijing", var_0_1.ctx.battle.requireFighter("Shuijing"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10
local var_0_6 = 90
local var_0_7 = 40010826
local var_0_8 = 40010825
local var_0_9 = 0.0005
local var_0_10 = 0.05
local var_0_11 = 40010827
local var_0_12 = 40010828
local var_0_13 = 0.0005
local var_0_14 = 0.1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("born_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.wiseBuffTargets_ = {}
	arg_2_0.strengthMonsters_ = {}
	arg_2_0.agileBuffTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if arg_3_0:isDeath() then
		if arg_3_0.wiseBuffTargets_ and next(arg_3_0.wiseBuffTargets_) then
			for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
				if not iter_3_1:isDeath() then
					iter_3_1:removeBuffByID(var_0_11)
					iter_3_1:removeBuffByID(var_0_12)
				end
			end

			arg_3_0.wiseBuffTargets_ = {}
			arg_3_0.agileBuffTargets_ = {}
		end

		return
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.strengthMonsters_) do
		if not iter_3_3:isDeath() then
			arg_3_0:addStrengthBuff(iter_3_3)
		end
	end

	for iter_3_4, iter_3_5 in ipairs(var_0_1.ctx.battle.infoList.born_info) do
		if arg_3_0:checkIsSummon(iter_3_5) and iter_3_5:getTeamType() == arg_3_0:getTeamType() then
			local var_3_0 = iter_3_5.hero_:getHeroType()

			if var_3_0 == var_0_2.HeroType.STRENGTH then
				arg_3_0:addStrengthBuff(iter_3_5)
			elseif var_3_0 == var_0_2.HeroType.WISE then
				arg_3_0:addWiseBuff(iter_3_5)
			elseif var_3_0 == var_0_2.HeroType.AGILE then
				arg_3_0:addAgileBuff(iter_3_5)
			end
		end
	end
end

function var_0_3.checkIsSummon(arg_4_0, arg_4_1)
	if not arg_4_1:isDeath() and not arg_4_1:isAffected() and arg_4_1:getSummonType() ~= var_0_2.summonMonsterType.None and arg_4_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and arg_4_1.summoner and not arg_4_1.summoner:isDeath() and not arg_4_1.summoner:isAffected() then
		return true
	end

	return false
end

function var_0_3.addStrengthBuff(arg_5_0, arg_5_1)
	if arg_5_1.leftInterval and var_0_1.ctx.battle.count - arg_5_1.leftInterval < var_0_6 or #arg_5_1.summoner:getBuffsByID() >= var_0_5 then
		return
	end

	arg_5_1.leftInterval = var_0_1.ctx.battle.count

	local var_5_0 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_5_1 = arg_5_1:getHp()
	local var_5_2 = (var_5_0 * var_0_9 + var_0_10) * var_5_1
	local var_5_3 = arg_5_0:newBuff({
		var_0_8,
		var_0_7
	}, arg_5_1.summoner, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	var_5_3[1].dHarm_ = var_5_2

	arg_5_1.summoner:addBuffs(var_5_3)
	table.insert(arg_5_0.strengthMonsters_, arg_5_1)
end

function var_0_3.addWiseBuff(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_6_0 = arg_6_0:newBuff({
				var_0_11
			}, iter_6_1, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

			iter_6_1:addBuffs(var_6_0)

			if not arg_6_0.wiseBuffTargets_[arg_6_1] or not next(arg_6_0.wiseBuffTargets_[arg_6_1]) then
				arg_6_0.wiseBuffTargets_[arg_6_1] = {}
			end

			table.insert(arg_6_0.wiseBuffTargets_[arg_6_1], iter_6_1)
		end
	end
end

function var_0_3.addAgileBuff(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0:newBuff({
		var_0_12
	}, arg_7_1, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

	arg_7_1:addBuffs(var_7_0)

	if not arg_7_1.summoner:isHasBuffByID(var_0_12) then
		local var_7_1 = arg_7_0:newBuff({
			var_0_12
		}, arg_7_1.summoner, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		arg_7_1.summoner:addBuffs(var_7_1)
	end

	if not arg_7_0.agileBuffTargets_[arg_7_1.summoner] then
		arg_7_0.agileBuffTargets_[arg_7_1.summoner] = 1
	else
		arg_7_0.agileBuffTargets_[arg_7_1.summoner] = arg_7_0.agileBuffTargets_[arg_7_1.summoner] + 1
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_0:isDeath() then
		return
	end

	if arg_9_1:getSummonType() ~= var_0_2.summonMonsterType.None and arg_9_1:getSummonType() ~= var_0_2.summonMonsterType.Pet and arg_9_1.summoner and not arg_9_1.summoner:isDeath() then
		if arg_9_1.hero_:getHeroType() == var_0_2.HeroType.WISE and arg_9_0.wiseBuffTargets_[arg_9_1] and next(arg_9_0.wiseBuffTargets_[arg_9_1]) then
			for iter_9_0 = 1, #arg_9_0.wiseBuffTargets_[arg_9_1] do
				arg_9_0.wiseBuffTargets_[arg_9_1][iter_9_0]:removeBuffByID(var_0_11)
			end

			arg_9_0.wiseBuffTargets_[arg_9_1] = nil
		elseif arg_9_1.hero_:getHeroType() == var_0_2.HeroType.AGILE and arg_9_0.agileBuffTargets_[arg_9_1.summoner] then
			arg_9_0.agileBuffTargets_[arg_9_1.summoner] = arg_9_0.agileBuffTargets_[arg_9_1.summoner] - 1

			if arg_9_0.agileBuffTargets_[arg_9_1.summoner] <= 0 then
				arg_9_1.summoner:removeBuffByID(var_0_12)

				arg_9_0.agileBuffTargets_[arg_9_1.summoner] = nil
			end
		elseif arg_9_1.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
			local var_9_0 = false

			for iter_9_1, iter_9_2 in ipairs(arg_9_0.strengthMonsters_) do
				if not iter_9_2:isDeath() and iter_9_2.summoner and iter_9_2.summoner == arg_9_1.summoner then
					var_9_0 = true

					break
				end
			end

			if not var_9_0 then
				arg_9_1.summoner:removeBuffByID(var_0_7)
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if var_10_2 > 0 and arg_10_1.fighter:getTeamType() == arg_10_0:getTeamType() and arg_10_1.fighter:isHasBuffByID(var_0_12) then
		var_10_2 = arg_10_1.fighter:getHp() * (var_0_14 + var_0_13 * arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)) + var_10_2
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

return var_0_3
