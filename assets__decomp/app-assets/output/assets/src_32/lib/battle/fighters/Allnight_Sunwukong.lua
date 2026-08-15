local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Sunwukong", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 15
local var_0_11 = 40012213
local var_0_12 = 40012214
local var_0_13 = 40012215
local var_0_14 = 40012216
local var_0_15 = 8
local var_0_16 = {
	81200002,
	81200007,
	81200008,
	81200003,
	81200004,
	81200005,
	81200009,
	81200006
}
local var_0_17 = 40012211
local var_0_18 = 0.5
local var_0_19 = 40012212
local var_0_20 = 0.5
local var_0_21 = 0.1
local var_0_22 = 40012217

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)
	arg_2_0:setupSkill()
end

function var_0_3.setupSkill(arg_3_0)
	if not arg_3_0.skillIDs_ then
		arg_3_0.skillIDs_ = {}

		local var_3_0 = arg_3_0.hero_:getSkillId()

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			arg_3_0.skillIDs_[iter_3_1] = true
		end
	end
end

function var_0_3.isHasSkill(arg_4_0, arg_4_1)
	return arg_4_0.skillIDs_[arg_4_1]
end

function var_0_3.die(arg_5_0)
	if next(arg_5_0.summonMonsters_) ~= true then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.summonMonsters_) do
			if not iter_5_1:isDeath() then
				iter_5_1:updateHp(0)
				iter_5_1:die()
			end
		end
	end

	var_0_3.super.die(arg_5_0)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = arg_6_1.target

	if var_0_6:father(var_6_0) == var_0_16[1] then
		local var_6_2 = var_0_6:summonMonster(var_6_0)

		if next(var_6_2) == nil then
			return
		end

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			local var_6_3 = arg_6_0:getSkillLevelByID(var_6_0)
			local var_6_4 = arg_6_0.hero_:getColor()
			local var_6_5 = arg_6_0:getFlipX() and arg_6_0:getX() - 75 or arg_6_0:getX() + 75
			local var_6_6 = var_0_1.ctx.battle.adjustX(var_6_5, arg_6_0)
			local var_6_7 = {
				x = var_6_6,
				y = arg_6_0:getY() - 200 + 100 * iter_6_0
			}

			arg_6_0:setSummonMonsters(iter_6_1, var_6_3, var_6_4, var_6_7)
		end

		local var_6_8 = arg_6_0:getFlipX() and arg_6_0:getX() + 50 or arg_6_0:getX() - 50
		local var_6_9 = var_0_1.ctx.battle.adjustX(var_6_8, arg_6_0)

		arg_6_0:x(var_6_9)
	elseif var_0_6:father(var_6_0) == var_0_16[4] then
		local var_6_10 = var_0_6:summonMonster(var_6_0)

		if next(var_6_10) == nil then
			return
		end

		for iter_6_2, iter_6_3 in ipairs(var_6_10) do
			local var_6_11 = arg_6_0:getSkillLevelByID(var_6_0)
			local var_6_12 = arg_6_0.hero_:getColor()
			local var_6_13

			if var_6_1:isBoss() then
				local var_6_14 = var_6_1:getFlipX() == true and -1 or 1

				var_6_13 = var_6_1:getX() + var_6_14 * 100
			else
				var_6_13 = arg_6_0:getX() < var_6_1:getX() and var_6_1:getX() + 100 or var_6_1:getX() - 100
			end

			local var_6_15 = var_0_1.ctx.battle.adjustX(var_6_13, arg_6_0)
			local var_6_16 = {
				x = var_6_15,
				y = var_6_1:getY() - 150 + 100 * iter_6_2
			}

			if var_6_1:avoidHeroMoveBehind() then
				var_6_16.x = var_6_16.x - var_6_1:getFighterModel():getWidth()
			end

			arg_6_0:setSummonMonsters(iter_6_3, var_6_11, var_6_12, var_6_16)
		end
	elseif var_0_6:father(var_6_0) == var_0_16[5] then
		local var_6_17 = var_0_6:summonMonster(var_6_0)

		if next(var_6_17) == nil then
			return
		end

		for iter_6_4, iter_6_5 in ipairs(var_6_17) do
			local var_6_18 = arg_6_0:getSkillLevelByID(var_6_0)
			local var_6_19 = arg_6_0.hero_:getColor()
			local var_6_20

			if var_6_1:isBoss() then
				local var_6_21 = var_6_1:getFlipX() == true and -1 or 1

				var_6_20 = var_6_1:getX() + var_6_21 * 100
			else
				var_6_20 = arg_6_0:getX() < var_6_1:getX() and var_6_1:getX() + 100 or var_6_1:getX() - 100
			end

			local var_6_22 = var_0_1.ctx.battle.adjustX(var_6_20, arg_6_0)
			local var_6_23 = {
				x = var_6_22,
				y = var_6_1:getY()
			}

			if var_6_1:avoidHeroMoveBehind() then
				var_6_23.x = var_6_23.x - var_6_1:getFighterModel():getWidth()
			end

			arg_6_0:setSummonMonsters(iter_6_5, var_6_18, var_6_19, var_6_23)
		end
	end
end

function var_0_3.setSummonMonsters(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	if arg_7_0:getSummonCount() >= var_0_15 then
		return
	end

	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_7_0 = arg_7_0:getSummonMonster()
	else
		local var_7_1 = var_0_5.new()

		var_7_1:populateWithTableID(arg_7_1)

		var_7_1.level_ = arg_7_2 or var_7_1.level_
		var_7_1.color_ = arg_7_3 or var_7_1.color_

		for iter_7_0, iter_7_1 in ipairs(var_7_1.skillLev_) do
			local var_7_2 = arg_7_0.hero_:getSkillLevel(iter_7_0)

			if var_7_2 and var_7_2 > 0 then
				var_7_1.skillLev_[iter_7_0] = var_0_0.clone(var_7_2)
			end
		end

		local var_7_3 = var_7_1:className()

		var_7_0 = var_0_1.ctx.battle.requireFighter(var_7_3).new({
			is_arena = arg_7_0.isInArena_
		})

		var_7_0:populateWithHero(var_7_1)
		var_7_0:initModels()
		var_7_0.fighterModel:initHeaderView(arg_7_0:getTeamType() - 1)

		var_7_0.fighterIndex = arg_7_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_7_0:setFormationDelay(0, 100)
	end

	var_7_0:setTeamType(arg_7_0:getTeamType())

	var_7_0.summoner = arg_7_0

	var_7_0.fighterModel:pos(arg_7_4.x, arg_7_4.y - #arg_7_0.summonMonsters_)
	var_7_0:getFighterModel():flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)
	var_7_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_7_0:born()
	var_7_0:setGlobalBuffs()
	var_7_0:updateHp(var_7_0:getHpLimit())

	local var_7_4 = var_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_7_4, var_7_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_7_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_7_0.summonMonsters_, var_7_0)

	if var_7_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_7_0.summonMonster_ then
			arg_7_0.summonMonster_:updateHp(0)
			arg_7_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_7_0.summonMonsters_, arg_7_0.summonMonster_)
		end

		arg_7_0.summonMonster_ = var_7_0
	elseif var_7_0.summonType_ == var_0_2.summonMonsterType.Copy then
		-- block empty
	end
end

function var_0_3.createUnits(arg_8_0)
	var_0_3.super.createUnits(arg_8_0)

	if arg_8_0.beginJump_ then
		arg_8_0.beginJump_ = nil
	end

	local var_8_0 = arg_8_0.unitSkills_
	local var_8_1 = var_8_0.rootID_
	local var_8_2, var_8_3 = var_8_0:getFront()

	if var_0_6:father(var_8_1) == var_0_16[6] then
		local var_8_4 = var_0_6:summonMonster(var_8_3)

		if next(var_8_4) == nil then
			return
		end

		for iter_8_0, iter_8_1 in ipairs(var_8_4) do
			local var_8_5 = arg_8_0:getSkillLevelByID(var_8_3)
			local var_8_6 = arg_8_0.hero_:getColor()
			local var_8_7 = arg_8_0:getFlipX() and arg_8_0:getX() - 15 or arg_8_0:getX() + 15
			local var_8_8 = var_0_1.ctx.battle.adjustX(var_8_7, arg_8_0)
			local var_8_9 = {
				x = var_8_8,
				y = arg_8_0:getY()
			}

			arg_8_0:setSummonMonsters(iter_8_1, var_8_5, var_8_6, var_8_9)
		end
	end
end

function var_0_3.beginAttackEnd(arg_9_0, arg_9_1)
	if arg_9_1.rootID_ == var_0_16[8] then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonMonsters_) do
			if not iter_9_1:isDeath() and not iter_9_1:isAffected() then
				local var_9_0 = arg_9_0:createNewBuffs({
					var_0_22
				}, iter_9_1, var_0_16[8])

				iter_9_1:addBuffs(var_9_0)
			end
		end
	end

	if var_0_6:father(arg_9_1.rootID_) == var_0_16[6] or var_0_6:father(arg_9_1.rootID_) == var_0_16[8] then
		arg_9_0.beginJump_ = true

		local var_9_1 = arg_9_0:getFlipX() and 120 or -120
		local var_9_2 = var_0_6:pretime(arg_9_1.rootID_)
		local var_9_3 = {}

		arg_9_0.buffMovePath_ = {}

		for iter_9_2 = 1, var_0_10 + var_9_2 do
			if iter_9_2 <= var_9_2 then
				table.insert(arg_9_0.buffMovePath_, {
					0,
					0
				})
			else
				table.insert(arg_9_0.buffMovePath_, {
					var_9_1 / var_0_10,
					0
				})
			end
		end
	end

	var_0_3.super.beginAttackEnd(arg_9_0, arg_9_1)
end

function var_0_3.checkSkillBreak(arg_10_0, arg_10_1, arg_10_2)
	var_0_3.super.checkSkillBreak(arg_10_0, arg_10_1, arg_10_2)

	if arg_10_1 == var_0_2.BreakSkillType.AD and not arg_10_0:isAdBreakImmortal() and arg_10_0.beginJump_ then
		arg_10_0.buffMovePath_ = {}
		arg_10_0.beginJump_ = nil
	end
end

function var_0_3.getAD(arg_11_0)
	local var_11_0 = var_0_3.super.getAD(arg_11_0)
	local var_11_1 = arg_11_0:getSkillLevelByID(var_0_16[7])

	if var_11_1 < 1 then
		return var_11_0
	end

	local var_11_2 = arg_11_0:getSummonCount()

	return var_11_0 + (var_0_9:init(var_0_13) + var_11_1 * var_0_9:step(var_0_13)) * var_11_2
end

function var_0_3.getADJianShang(arg_12_0)
	local var_12_0 = arg_12_0:getSkillLevelByID(var_0_16[7])

	if var_12_0 < 1 then
		return var_0_3.super.getADJianShang(arg_12_0)
	else
		local var_12_1 = arg_12_0:getAttrByType(var_0_2.AttributeType.AD_JIANSHANG)
		local var_12_2 = arg_12_0:getSummonCount()
		local var_12_3 = 1 - (1 - (var_12_1 + (var_0_9:init(var_0_11) + var_12_0 * var_0_9:step(var_0_11)) * var_12_2)) * (1 + arg_12_0:getCourseJianshang())

		if var_12_3 <= 0.1 then
			var_12_3 = 0.1
		end

		return var_12_3
	end
end

function var_0_3.getAPJianShang(arg_13_0)
	local var_13_0 = arg_13_0:getSkillLevelByID(var_0_16[7])

	if var_13_0 < 1 then
		return var_0_3.super.getAPJianShang(arg_13_0)
	else
		local var_13_1 = arg_13_0:getAttrByType(var_0_2.AttributeType.AP_JIANSHANG)
		local var_13_2 = arg_13_0:getSummonCount()
		local var_13_3 = 1 - (1 - (var_13_1 + (var_0_9:init(var_0_12) + var_13_0 * var_0_9:step(var_0_12)) * var_13_2)) * (1 + arg_13_0:getCourseJianshang())

		if var_13_3 <= 0.1 then
			var_13_3 = 0.1
		end

		return var_13_3
	end
end

function var_0_3.getCurrentAckSpeed(arg_14_0)
	local var_14_0 = arg_14_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED)
	local var_14_1 = arg_14_0:getSkillLevelByColor(var_0_16[7])

	if var_14_1 > 0 then
		local var_14_2 = arg_14_0:getSummonCount()

		var_14_0 = var_14_0 + (var_0_9:init(var_0_14) + var_14_1 * var_0_9:step(var_0_14)) * var_14_2
	end

	local var_14_3 = math.min(var_14_0 / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

	return (math.max(var_14_3, var_0_2.MIN_ATTACK_SPEED))
end

function var_0_3.getSummonCount(arg_15_0)
	local var_15_0 = 0

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.summonMonsters_) do
		if not iter_15_1:isDeath() then
			var_15_0 = var_15_0 + 1
		end
	end

	return var_15_0
end

function var_0_3.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)
	arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7 = var_0_3.super.updateUnitDataByFighter(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7)

	if arg_16_0:isHasSkill(var_0_16[6]) and arg_16_4 > 0 then
		arg_16_4 = arg_16_4 * (1 + var_0_21 * arg_16_0:getSummonCount())
	end

	return arg_16_2, arg_16_3, arg_16_4, arg_16_5, arg_16_6, arg_16_7
end

function var_0_3.updateUnitDataByTarget(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)
	arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7 = var_0_3.super.updateUnitDataByTarget(arg_17_0, arg_17_1, arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7)

	if arg_17_1.fighter:isHasBuffByID(var_0_17) and arg_17_4 > 0 then
		arg_17_4 = arg_17_4 * (1 - var_0_18)
	end

	return arg_17_2, arg_17_3, arg_17_4, arg_17_5, arg_17_6, arg_17_7
end

function var_0_3.buffAddAction(arg_18_0, arg_18_1)
	if arg_18_1:getTableID() == var_0_19 then
		arg_18_1.manualHarmRevise = arg_18_1.target:getHpLimit() * var_0_20 / 10
	end
end

function var_0_3.isBoss(arg_19_0)
	return true
end

function var_0_3.isBreakImmortal(arg_20_0)
	return true
end

return var_0_3
