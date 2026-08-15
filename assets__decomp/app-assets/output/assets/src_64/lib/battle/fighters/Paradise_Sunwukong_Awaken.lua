local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseSunwukong", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 20010092
local var_0_11 = 20010093
local var_0_12 = 15
local var_0_13 = 7
local var_0_14 = 0.1
local var_0_15 = 0.005

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
	arg_1_0.beginJump_ = nil
	arg_1_0.records_.pugong_summon = {}
end

function var_0_3.die(arg_2_0)
	if next(arg_2_0.summonMonsters_) ~= true then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
			if not iter_2_1:isDeath() then
				iter_2_1:updateHp(0)
				iter_2_1:die()
			end
		end
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID
	local var_3_1 = arg_3_1.target

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_2 = var_0_6:summonMonster(var_3_0)

		if next(var_3_2) == nil then
			return
		end

		for iter_3_0, iter_3_1 in ipairs(var_3_2) do
			local var_3_3 = arg_3_0:getSkillLevelByID(var_3_0)
			local var_3_4 = arg_3_0.hero_:getColor()
			local var_3_5 = arg_3_0:getFlipX() and arg_3_0:getX() - 75 or arg_3_0:getX() + 75
			local var_3_6 = var_0_1.ctx.battle.adjustX(var_3_5, arg_3_0)
			local var_3_7 = {
				x = var_3_6,
				y = arg_3_0:getY() - 150 + 100 * iter_3_0
			}

			arg_3_0:setSummonMonsters(iter_3_1, var_3_3, var_3_4, var_3_7)
		end

		local var_3_8 = arg_3_0:getFlipX() and arg_3_0:getX() + 50 or arg_3_0:getX() - 50
		local var_3_9 = var_0_1.ctx.battle.adjustX(var_3_8, arg_3_0)

		arg_3_0:x(var_3_9)
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_10 = var_0_6:summonMonster(var_3_0)

		if next(var_3_10) == nil then
			return
		end

		for iter_3_2, iter_3_3 in ipairs(var_3_10) do
			local var_3_11 = arg_3_0:getSkillLevelByID(var_3_0)
			local var_3_12 = arg_3_0.hero_:getColor()
			local var_3_13

			if var_3_1:isBoss() then
				local var_3_14 = var_3_1:getFlipX() == true and -1 or 1

				var_3_13 = var_3_1:getX() + var_3_14 * 100
			else
				var_3_13 = arg_3_0:getX() < var_3_1:getX() and var_3_1:getX() + 100 or var_3_1:getX() - 100
			end

			local var_3_15 = var_0_1.ctx.battle.adjustX(var_3_13, arg_3_0)
			local var_3_16 = {
				x = var_3_15,
				y = var_3_1:getY()
			}

			if var_3_1:avoidHeroMoveBehind() then
				var_3_16.x = var_3_16.x - var_3_1:getFighterModel():getContentSize().width
			end

			arg_3_0:setSummonMonsters(iter_3_3, var_3_11, var_3_12, var_3_16)
		end
	end
end

function var_0_3.setSummonMonsters(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	if arg_4_0:getSummonCount() >= var_0_13 then
		return
	end

	local var_4_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0 = var_0_1.ctx.battle.summonMonsters[var_4_1]
	else
		local var_4_2 = var_0_5.new()

		var_4_2:populateWithTableID(arg_4_1)

		var_4_2.level_ = arg_4_2 or var_4_2.level_
		var_4_2.color_ = arg_4_3 or var_4_2.color_

		for iter_4_0, iter_4_1 in ipairs(var_4_2.skillLev_) do
			local var_4_3 = arg_4_0.hero_:getSkillLevel(iter_4_0)

			if var_4_3 and var_4_3 > 0 then
				var_4_2.skillLev_[iter_4_0] = var_0_0.clone(var_4_3)
			end
		end

		local var_4_4 = var_4_2:className()

		var_4_0 = var_0_1.ctx.battle.requireFighter(var_4_4).new({
			is_arena = arg_4_0.isInArena_
		})

		var_4_0:populateWithHero(var_4_2)
		var_4_0:initModels()
		var_4_0.fighterModel:initHeaderView(arg_4_0:getTeamType() - 1)

		var_4_0.fighterIndex = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0:setFormationDelay(0, 100)
	end

	var_4_0:setTeamType(arg_4_0:getTeamType())

	var_4_0.summoner = arg_4_0

	var_4_0.fighterModel:pos(arg_4_4.x, arg_4_4.y - #arg_4_0.summonMonsters_)
	var_4_0:getFighterModel():flipX(arg_4_0:getTeamType() == var_0_2.TeamType.B)
	var_4_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_4_0:born()
	var_4_0:setGlobalBuffs()
	var_4_0:updateHp(var_4_0:getHpLimit())

	local var_4_5 = var_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_4_5, var_4_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_4_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_4_0.summonMonsters_, var_4_0)

	if var_4_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_4_0.summonMonster_ then
			arg_4_0.summonMonster_:updateHp(0)
			arg_4_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_4_0.summonMonsters_, arg_4_0.summonMonster_)
		end

		arg_4_0.summonMonster_ = var_4_0
	elseif var_4_0.summonType_ == var_0_2.summonMonsterType.Copy then
		-- block empty
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	if arg_5_1.rootID_ == arg_5_0:getEnergySkillID() then
		arg_5_0.beginJump_ = true

		local var_5_0 = arg_5_0:getFlipX() and 120 or -120
		local var_5_1 = var_0_6:pretime(arg_5_1.rootID_)
		local var_5_2 = {}

		arg_5_0.buffMovePath_ = {}

		for iter_5_0 = 1, var_0_12 + var_5_1 do
			if iter_5_0 <= var_5_1 then
				table.insert(arg_5_0.buffMovePath_, {
					0,
					0
				})
			else
				table.insert(arg_5_0.buffMovePath_, {
					var_5_0 / var_0_12,
					0
				})
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)
end

function var_0_3.createUnits(arg_6_0)
	var_0_3.super.createUnits(arg_6_0)

	if arg_6_0.beginJump_ then
		arg_6_0.beginJump_ = nil
	end

	local var_6_0 = arg_6_0.unitSkills_
	local var_6_1 = var_6_0.rootID_
	local var_6_2, var_6_3 = var_6_0:getFront()

	if var_6_1 == arg_6_0:getEnergySkillID() then
		local var_6_4 = var_0_6:summonMonster(var_6_3)

		if next(var_6_4) == nil then
			return
		end

		for iter_6_0, iter_6_1 in ipairs(var_6_4) do
			local var_6_5 = arg_6_0:getSkillLevelByID(var_6_3)
			local var_6_6 = arg_6_0.hero_:getColor()
			local var_6_7 = arg_6_0:getFlipX() and arg_6_0:getX() - 15 or arg_6_0:getX() + 15
			local var_6_8 = var_0_1.ctx.battle.adjustX(var_6_7, arg_6_0)
			local var_6_9 = {
				x = var_6_8,
				y = arg_6_0:getY()
			}

			arg_6_0:setSummonMonsters(iter_6_1, var_6_5, var_6_6, var_6_9)
		end
	elseif var_6_3 == arg_6_0:getPugongID() then
		local var_6_10 = false

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_6_0.pugongSummon_[tostring(var_0_1.ctx.battle.count)] then
				var_6_10 = true
			end
		else
			local var_6_11 = math.min(1, var_0_14 + var_0_15 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green))

			var_6_10 = var_0_2.weightedChoise({
				var_6_11,
				1 - var_6_11
			}) == 1

			if var_6_10 then
				arg_6_0.records_.pugong_summon[tostring(var_0_1.ctx.battle.count)] = 1
			end
		end

		if var_6_10 then
			local var_6_12 = var_0_6:summonMonster(var_6_3)

			if next(var_6_12) == nil then
				return
			end

			for iter_6_2, iter_6_3 in ipairs(var_6_12) do
				local var_6_13 = arg_6_0:getSkillLevelByID(var_6_3)
				local var_6_14 = arg_6_0.hero_:getColor()
				local var_6_15 = arg_6_0:getFlipX() and arg_6_0:getX() - 15 or arg_6_0:getX() + 15
				local var_6_16 = var_0_1.ctx.battle.adjustX(var_6_15, arg_6_0)
				local var_6_17 = {
					x = var_6_16,
					y = arg_6_0:getY()
				}

				arg_6_0:setSummonMonsters(iter_6_3, var_6_13, var_6_14, var_6_17)
			end
		end
	end
end

function var_0_3.checkSkillBreak(arg_7_0, arg_7_1)
	var_0_3.super.checkSkillBreak(arg_7_0, arg_7_1)

	if arg_7_1 == var_0_2.BreakSkillType.AD and not arg_7_0:isAdBreakImmortal() and arg_7_0.beginJump_ then
		arg_7_0.buffMovePath_ = {}
		arg_7_0.beginJump_ = nil
	end
end

function var_0_3.getAD(arg_8_0)
	local var_8_0 = var_0_3.super.getAD(arg_8_0)
	local var_8_1 = arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_8_1 < 1 then
		return var_8_0
	end

	local var_8_2 = arg_8_0:getSummonCount()

	return var_8_0 + (var_0_9:init(var_0_10) + var_8_1 * var_0_9:step(var_0_10)) * var_8_2
end

function var_0_3.getCurrentAckSpeed(arg_9_0)
	local var_9_0 = arg_9_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED)
	local var_9_1 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_9_1 > 0 then
		local var_9_2 = arg_9_0:getSummonCount()

		var_9_0 = var_9_0 + (var_0_9:init(var_0_11) + var_9_1 * var_0_9:step(var_0_11)) * var_9_2
	end

	local var_9_3 = math.min(var_9_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_9_3, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.getSummonCount(arg_10_0)
	local var_10_0 = 0

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.summonMonsters_) do
		if not iter_10_1:isDeath() then
			var_10_0 = var_10_0 + 1
		end
	end

	return var_10_0
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.pugongSummon_ = arg_11_1.pugong_summon
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.pugong_summon = arg_12_0.records_.pugong_summon

	return var_12_0
end

return var_0_3
