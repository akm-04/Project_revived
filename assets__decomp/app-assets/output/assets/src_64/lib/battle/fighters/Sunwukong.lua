local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunwukong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = var_0_2.tables.cabinetSkillTable
local var_0_11 = 20010092
local var_0_12 = 20010093
local var_0_13 = 15
local var_0_14 = 7
local var_0_15 = 0.1
local var_0_16 = 0.005
local var_0_17 = 10420005
local var_0_18 = 40012178
local var_0_19 = 0.3

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
	arg_1_0.beginJump_ = nil
	arg_1_0.records_.pugong_summon = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.extraSkillHp = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_17)] or 0
		arg_2_0.extraSkillHp = arg_2_0.extraSkillLevel * var_0_10:attrValues(var_0_17)
	end
end

function var_0_3.die(arg_3_0)
	if next(arg_3_0.summonMonsters_) ~= true then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
			if not iter_3_1:isDeath() then
				iter_3_1:updateHp(0)
				iter_3_1:die()
			end
		end
	end

	var_0_3.super.die(arg_3_0)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	local var_4_0 = arg_4_1.skillID
	local var_4_1 = arg_4_1.target

	if var_0_6:father(var_4_0) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_2 = var_0_6:summonMonster(var_4_0)

		if next(var_4_2) == nil then
			return
		end

		for iter_4_0, iter_4_1 in ipairs(var_4_2) do
			local var_4_3 = arg_4_0:getSkillLevelByID(var_4_0)
			local var_4_4 = arg_4_0.hero_:getColor()
			local var_4_5 = arg_4_0:getFlipX() and arg_4_0:getX() - 75 or arg_4_0:getX() + 75
			local var_4_6 = var_0_1.ctx.battle.adjustX(var_4_5, arg_4_0)
			local var_4_7 = {
				x = var_4_6,
				y = arg_4_0:getY() - 150 + 100 * iter_4_0
			}

			arg_4_0:setSummonMonsters(iter_4_1, var_4_3, var_4_4, var_4_7)
		end

		local var_4_8 = arg_4_0:getFlipX() and arg_4_0:getX() + 50 or arg_4_0:getX() - 50
		local var_4_9 = var_0_1.ctx.battle.adjustX(var_4_8, arg_4_0)

		arg_4_0:x(var_4_9)
	elseif var_0_6:father(var_4_0) == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_4_10 = var_0_6:summonMonster(var_4_0)

		if next(var_4_10) == nil then
			return
		end

		for iter_4_2, iter_4_3 in ipairs(var_4_10) do
			local var_4_11 = arg_4_0:getSkillLevelByID(var_4_0)
			local var_4_12 = arg_4_0.hero_:getColor()
			local var_4_13

			if var_4_1:isBoss() then
				local var_4_14 = var_4_1:getFlipX() == true and -1 or 1

				var_4_13 = var_4_1:getX() + var_4_14 * 100
			else
				var_4_13 = arg_4_0:getX() < var_4_1:getX() and var_4_1:getX() + 100 or var_4_1:getX() - 100
			end

			local var_4_15 = var_0_1.ctx.battle.adjustX(var_4_13, arg_4_0)
			local var_4_16 = {
				x = var_4_15,
				y = var_4_1:getY()
			}

			if var_4_1:avoidHeroMoveBehind() then
				var_4_16.x = var_4_16.x - var_4_1:getFighterModel():getWidth()
			end

			arg_4_0:setSummonMonsters(iter_4_3, var_4_11, var_4_12, var_4_16)
		end
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	if arg_5_0:getSummonCount() >= var_0_14 then
		return
	end

	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_0 = arg_5_0:getSummonMonster()
	else
		local var_5_1 = var_0_5.new()

		var_5_1:populateWithTableID(arg_5_1)

		var_5_1.level_ = arg_5_2 or var_5_1.level_
		var_5_1.color_ = arg_5_3 or var_5_1.color_

		for iter_5_0, iter_5_1 in ipairs(var_5_1.skillLev_) do
			local var_5_2 = arg_5_0.hero_:getSkillLevel(iter_5_0)

			if var_5_2 and var_5_2 > 0 then
				var_5_1.skillLev_[iter_5_0] = var_0_0.clone(var_5_2)
			end
		end

		local var_5_3 = var_5_1:className()

		var_5_0 = var_0_1.ctx.battle.requireFighter(var_5_3).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_0:populateWithHero(var_5_1)
		var_5_0:initModels()
		var_5_0.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_0.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0:setFormationDelay(0, 100)
	end

	if arg_5_0.extraSkillLevel > 0 and var_5_0.setExtraSkillHp then
		var_5_0:setExtraSkillHp(arg_5_0.extraSkillHp)
	end

	var_5_0:setTeamType(arg_5_0:getTeamType())

	var_5_0.summoner = arg_5_0

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y - #arg_5_0.summonMonsters_)
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()
	var_5_0:updateHp(var_5_0:getHpLimit())

	local var_5_4 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_4, var_5_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_5_0.summonMonsters_, var_5_0)

	if var_5_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_5_0.summonMonster_ then
			arg_5_0.summonMonster_:updateHp(0)
			arg_5_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_5_0.summonMonsters_, arg_5_0.summonMonster_)
		end

		arg_5_0.summonMonster_ = var_5_0
	elseif var_5_0.summonType_ == var_0_2.summonMonsterType.Copy then
		-- block empty
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	if var_0_6:father(arg_6_1.rootID_) == arg_6_0:getEnergySkillID() then
		arg_6_0.beginJump_ = true

		local var_6_0 = arg_6_0:getFlipX() and 120 or -120
		local var_6_1 = var_0_6:pretime(arg_6_1.rootID_)
		local var_6_2 = {}

		arg_6_0.buffMovePath_ = {}

		for iter_6_0 = 1, var_0_13 + var_6_1 do
			if iter_6_0 <= var_6_1 then
				table.insert(arg_6_0.buffMovePath_, {
					0,
					0
				})
			else
				table.insert(arg_6_0.buffMovePath_, {
					var_6_0 / var_0_13,
					0
				})
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.createUnits(arg_7_0)
	var_0_3.super.createUnits(arg_7_0)

	if arg_7_0.beginJump_ then
		arg_7_0.beginJump_ = nil
	end

	local var_7_0 = arg_7_0.unitSkills_
	local var_7_1 = var_7_0.rootID_
	local var_7_2, var_7_3 = var_7_0:getFront()

	if var_0_6:father(var_7_1) == arg_7_0:getEnergySkillID() then
		local var_7_4 = var_0_6:summonMonster(var_7_3)

		if next(var_7_4) == nil then
			return
		end

		for iter_7_0, iter_7_1 in ipairs(var_7_4) do
			local var_7_5 = arg_7_0:getSkillLevelByID(var_7_3)
			local var_7_6 = arg_7_0.hero_:getColor()
			local var_7_7 = arg_7_0:getFlipX() and arg_7_0:getX() - 15 or arg_7_0:getX() + 15
			local var_7_8 = var_0_1.ctx.battle.adjustX(var_7_7, arg_7_0)
			local var_7_9 = {
				x = var_7_8,
				y = arg_7_0:getY()
			}

			arg_7_0:setSummonMonsters(iter_7_1, var_7_5, var_7_6, var_7_9)
		end
	elseif var_0_6:father(var_7_3) == arg_7_0:getPugongID() then
		local var_7_10 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_7_0.pugongSummon_[tostring(var_0_1.ctx.battle.count)] then
				var_7_10 = true
			end
		else
			local var_7_11 = math.min(1, var_0_15 + var_0_16 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

			var_7_10 = var_0_2.weightedChoise({
				var_7_11,
				1 - var_7_11
			}) == 1

			if var_7_10 then
				arg_7_0.records_.pugong_summon[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_7_10 then
			local var_7_12 = var_0_6:summonMonster(var_7_3)

			if next(var_7_12) == nil then
				return
			end

			for iter_7_2, iter_7_3 in ipairs(var_7_12) do
				local var_7_13 = arg_7_0:getSkillLevelByID(var_7_3)
				local var_7_14 = arg_7_0.hero_:getColor()
				local var_7_15 = arg_7_0:getFlipX() and arg_7_0:getX() - 15 or arg_7_0:getX() + 15
				local var_7_16 = var_0_1.ctx.battle.adjustX(var_7_15, arg_7_0)
				local var_7_17 = {
					x = var_7_16,
					y = arg_7_0:getY()
				}

				arg_7_0:setSummonMonsters(iter_7_3, var_7_13, var_7_14, var_7_17)
			end
		end
	end
end

function var_0_3.checkSkillBreak(arg_8_0, arg_8_1, arg_8_2)
	var_0_3.super.checkSkillBreak(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_1 == var_0_2.BreakSkillType.AD and not arg_8_0:isAdBreakImmortal() and arg_8_0.beginJump_ then
		arg_8_0.buffMovePath_ = {}
		arg_8_0.beginJump_ = nil
	end
end

function var_0_3.getAD(arg_9_0)
	local var_9_0 = var_0_3.super.getAD(arg_9_0)
	local var_9_1 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_9_1 < 1 then
		return var_9_0
	end

	local var_9_2 = arg_9_0:getSummonCount()

	return var_9_0 + (var_0_9:init(var_0_11) + var_9_1 * var_0_9:step(var_0_11)) * var_9_2
end

function var_0_3.getCurrentAckSpeed(arg_10_0)
	local var_10_0 = arg_10_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED)
	local var_10_1 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_10_1 > 0 then
		local var_10_2 = arg_10_0:getSummonCount()

		var_10_0 = var_10_0 + (var_0_9:init(var_0_12) + var_10_1 * var_0_9:step(var_0_12)) * var_10_2
	end

	local var_10_3 = math.min(var_10_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_10_3, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.getSummonCount(arg_11_0)
	local var_11_0 = 0

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.summonMonsters_) do
		if not iter_11_1:isDeath() then
			var_11_0 = var_11_0 + 1
		end
	end

	return var_11_0
end

function var_0_3.setupReport(arg_12_0, arg_12_1)
	var_0_3.super.setupReport(arg_12_0, arg_12_1)

	arg_12_0.pugongSummon_ = arg_12_1.pugong_summon
end

function var_0_3.writeReport(arg_13_0)
	local var_13_0 = var_0_3.super.writeReport(arg_13_0)

	var_13_0.pugong_summon = arg_13_0.records_.pugong_summon

	return var_13_0
end

function var_0_3.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataByTarget(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_1.fighter:isHasBuffByID(var_0_18) and arg_14_4 > 0 then
		arg_14_4 = arg_14_4 * (1 - var_0_19)
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

return var_0_3
