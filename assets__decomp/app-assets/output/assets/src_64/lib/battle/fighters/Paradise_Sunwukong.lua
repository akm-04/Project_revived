local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseSunwukong", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = var_0_2.tables.dbuff
local var_0_11 = 15
local var_0_12 = 7
local var_0_13 = 0.1
local var_0_14 = 0.005
local var_0_15 = 20010087
local var_0_16 = 10
local var_0_17 = 1
local var_0_18 = 20
local var_0_19 = {
	{
		40010213,
		40010250
	},
	{
		40010214,
		40010251
	}
}

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

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_2 = var_0_7:summonMonster(var_3_0)

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

			arg_3_0:setSummonMonsters(iter_3_1, var_3_3, var_3_4, var_3_7, var_0_15, var_3_0)
		end

		local var_3_8 = arg_3_0:getFlipX() and arg_3_0:getX() + 50 or arg_3_0:getX() - 50
		local var_3_9 = var_0_1.ctx.battle.adjustX(var_3_8, arg_3_0)

		arg_3_0:x(var_3_9)
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_10 = var_0_7:summonMonster(var_3_0)

		if next(var_3_10) == nil then
			return
		end

		for iter_3_2, iter_3_3 in ipairs(var_3_10) do
			local var_3_11 = arg_3_0:getSkillLevelByID(var_3_0)
			local var_3_12 = arg_3_0.hero_:getColor()
			local var_3_13 = arg_3_0:getX() < var_3_1:getX() and var_3_1:getX() + 100 or var_3_1:getX() - 100
			local var_3_14 = var_0_1.ctx.battle.adjustX(var_3_13, arg_3_0)
			local var_3_15 = {
				x = var_3_14,
				y = var_3_1:getY()
			}

			if var_3_1:avoidHeroMoveBehind() then
				var_3_15.x = var_3_15.x - var_3_1:getFighterModel():getContentSize().width
			end

			arg_3_0:setSummonMonsters(iter_3_3, var_3_11, var_3_12, var_3_15)
		end

		local var_3_16 = var_0_19[math.random(#var_0_19)]

		for iter_3_4 = 1, #var_3_16 do
			var_3_1:addBuffs(arg_3_0:newBuff(var_3_16[iter_3_4], var_3_0, arg_3_0:getSkillLevelByID(var_3_0), var_3_1))
		end
	end
end

function var_0_3.newBuff(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0 = var_0_5.new({
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

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6)
	if arg_5_0:getSummonCount() >= var_0_12 then
		return
	end

	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_5_1 = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0 = var_0_1.ctx.battle.summonMonsters[var_5_1]
	else
		local var_5_2 = var_0_6.new()

		var_5_2:populateWithTableID(arg_5_1)

		var_5_2.level_ = arg_5_2 or var_5_2.level_
		var_5_2.color_ = arg_5_3 or var_5_2.color_

		for iter_5_0, iter_5_1 in ipairs(var_5_2.skillLev_) do
			local var_5_3 = arg_5_0.hero_:getSkillLevel(iter_5_0)

			if var_5_3 and var_5_3 > 0 then
				var_5_2.skillLev_[iter_5_0] = var_0_0.clone(var_5_3)
			end
		end

		local var_5_4 = var_5_2:className()

		var_5_0 = var_0_1.ctx.battle.requireFighter(var_5_4).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_0:populateWithHero(var_5_2)
		var_5_0:initModels()
		var_5_0.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_0.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0:setFormationDelay(0, 100)
	end

	var_5_0:setTeamType(arg_5_0:getTeamType())

	var_5_0.summoner = arg_5_0

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y - #arg_5_0.summonMonsters_)
	var_5_0:updateHp(var_5_0:getHpLimit())
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()

	if arg_5_5 then
		var_5_0:addBuffs(arg_5_0:newBuff(arg_5_5, arg_5_6, arg_5_2, var_5_0))
	end

	local var_5_5 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_5, var_5_0)
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
	if arg_6_1.rootID_ == arg_6_0:getEnergySkillID() then
		arg_6_0.beginJump_ = true

		local var_6_0 = arg_6_0:getFlipX() and 120 or -120
		local var_6_1 = var_0_7:pretime(arg_6_1.rootID_)
		local var_6_2 = {}

		arg_6_0.buffMovePath_ = {}

		for iter_6_0 = 1, var_0_11 + var_6_1 do
			if iter_6_0 <= var_6_1 then
				table.insert(arg_6_0.buffMovePath_, {
					0,
					0
				})
			else
				table.insert(arg_6_0.buffMovePath_, {
					var_6_0 / var_0_11,
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

	if var_7_1 == arg_7_0:getEnergySkillID() then
		local var_7_4 = var_0_7:summonMonster(var_7_3)

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
	end
end

function var_0_3.checkSkillBreak(arg_8_0, arg_8_1, arg_8_2)
	var_0_3.super.checkSkillBreak(arg_8_0, arg_8_1, arg_8_2)

	if arg_8_1 == var_0_2.BreakSkillType.AD and not arg_8_0:isAdBreakImmortal() and arg_8_0.beginJump_ then
		arg_8_0.buffMovePath_ = {}
		arg_8_0.beginJump_ = nil
	end
end

function var_0_3.getSummonCount(arg_9_0)
	local var_9_0 = 0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonMonsters_) do
		if not iter_9_1:isDeath() then
			var_9_0 = var_9_0 + 1
		end
	end

	return var_9_0
end

function var_0_3.calculateUnitData(arg_10_0, arg_10_1)
	local var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5 = var_0_3.super.calculateUnitData(arg_10_0, arg_10_1)
	local var_10_6 = arg_10_1.skillID

	if var_0_7:father(var_10_6) == arg_10_0:getEnergySkillID() then
		var_10_2 = var_10_2 + arg_10_0:getSummonCount() * arg_10_0:getSkillLevelByID(var_10_6) * var_0_16
	end

	return var_10_0, var_10_1, var_10_2, var_10_3, var_10_4, var_10_5
end

function var_0_3.getShanBi(arg_11_0)
	return var_0_3.super.getShanBi(arg_11_0) + var_0_17 * arg_11_0:getLevel()
end

function var_0_3.addBuffs(arg_12_0, arg_12_1)
	for iter_12_0 = #arg_12_1, 1, -1 do
		local var_12_0 = arg_12_1[iter_12_0]

		if var_12_0:getAttrType() == var_0_2.AttributeType.AD_HIT_RATE then
			local var_12_1 = var_12_0:initAttr()
			local var_12_2 = var_12_0:step()

			if var_12_1 < 0 or var_12_2 < 0 then
				table.remove(arg_12_1, iter_12_0)
			end
		end
	end

	var_0_3.super.addBuffs(arg_12_0, arg_12_1)
end

function var_0_3.selectTargetByTypeD9(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0
	local var_13_1
	local var_13_2

	if arg_13_2 and arg_13_2.targets_ then
		local var_13_3 = arg_13_2.targets_
		local var_13_4

		var_13_1, var_13_4 = var_13_3[#var_13_3]:getPos()
	else
		local var_13_5

		var_13_1, var_13_5 = arg_13_0:getPos()
	end

	local var_13_6 = arg_13_0.targetTeam_
	local var_13_7
	local var_13_8

	for iter_13_0, iter_13_1 in ipairs(var_13_6) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1 ~= arg_13_0 and iter_13_1:getSummonType() == 0 then
			local var_13_9, var_13_10 = iter_13_1:getPos()
			local var_13_11 = math.abs(var_13_1 - var_13_9)

			if (not var_13_7 or var_13_11 < var_13_7) and (not arg_13_2 or not arg_13_2.recordTargets_[iter_13_1.fighterIndex]) then
				var_13_7 = var_13_11
				var_13_8 = iter_13_1
			end
		end
	end

	local var_13_12 = {}

	if var_13_8 then
		var_13_12 = {
			var_13_8
		}
	end

	return var_13_12
end

function var_0_3.isHurtBreak(arg_14_0, arg_14_1, arg_14_2)
	return false
end

return var_0_3
