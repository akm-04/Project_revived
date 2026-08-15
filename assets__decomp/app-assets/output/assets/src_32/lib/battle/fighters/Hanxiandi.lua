local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hanxiandi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = 30010031
local var_0_9 = 10
local var_0_10 = 30010030
local var_0_11 = 0.1
local var_0_12 = 80010058
local var_0_13 = 0.2
local var_0_14 = 0.002
local var_0_15 = 60020058

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.isSummon = false
	arg_2_0.summonMonsters_ = {}
	arg_2_0.count = false
	arg_2_0.sortedHero = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.isSkinSkillOn_ and not arg_3_0.isSummon and not var_0_1.ctx.battle.walk2NextBattle_ then
		arg_3_0.isSummon = true

		local var_3_0 = var_0_4:summonMonster(var_0_12)

		if next(var_3_0) == nil then
			return
		end

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			local var_3_1 = arg_3_0:getSkillLevelByID(var_0_12)
			local var_3_2 = arg_3_0.hero_:getColor()
			local var_3_3 = {
				x = 560,
				y = 500
			}

			arg_3_0:setSummonMonsters(iter_3_1, var_3_1, var_3_2, var_3_3)
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
		local var_3_4 = iter_3_3.target

		if var_3_4 and var_3_4:getTeamType() ~= arg_3_0:getTeamType() and arg_3_0:isStunBuff(iter_3_3) then
			local var_3_5 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_3_6 = var_3_4:getBuffsByID(var_0_8)

			if next(var_3_6) ~= nil then
				for iter_3_4, iter_3_5 in ipairs(var_3_6) do
					iter_3_5.leftCount_ = iter_3_5:getTime()
				end
			end

			if #var_3_6 < var_0_9 - 1 and arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
				local var_3_7 = var_0_13 + arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) * var_0_14

				if var_0_2.weightedChoise({
					var_3_7,
					1 - var_3_7
				}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and not var_3_4:isDeath() and not var_3_4:isAffected() then
					local var_3_8 = arg_3_0:createAttackUnits({
						var_3_4
					}, var_0_15)

					for iter_3_6, iter_3_7 in ipairs(var_3_8) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_7)
						table.insert(arg_3_0.records_.special_units, iter_3_7)
					end
				end
			end

			if #var_3_6 ~= var_0_9 then
				var_3_4:addBuffs(arg_3_0:newBuff(var_0_8, var_3_5, arg_3_0:getSkillLevelByID(var_3_5), var_3_4))
			end
		end
	end
end

function var_0_3.setSummonMonsters(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_4_0 = arg_4_0:getSummonMonster()
	else
		local var_4_1 = var_0_7.new()

		var_4_1:populateWithTableID(arg_4_1)

		var_4_1.level_ = arg_4_2 or var_4_1.level_
		var_4_1.color_ = arg_4_3 or var_4_1.color_

		for iter_4_0, iter_4_1 in ipairs(var_4_1.skillLev_) do
			local var_4_2 = var_4_1:getSkillId(iter_4_0)
			local var_4_3 = arg_4_0.hero_:getSkillLevelByID(var_4_2)

			if var_4_3 and var_4_3 > 0 then
				var_4_1.skillLev_[iter_4_0] = var_4_3
			end
		end

		local var_4_4 = var_4_1:className()

		var_4_0 = var_0_1.ctx.battle.requireFighter(var_4_4).new({
			is_arena = arg_4_0.isInArena_
		})

		var_4_0:populateWithHero(var_4_1)
		var_4_0:initModels()
		var_4_0.fighterModel:initHeaderView(arg_4_0:getTeamType() - 1)

		var_4_0.fighterIndex = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0:setFormationDelay(0, 100)
	end

	var_4_0:setTeamType(arg_4_0:getTeamType())

	var_4_0.summoner = arg_4_0

	var_4_0.fighterModel:pos(arg_4_4.x, arg_4_4.y)
	var_4_0:updateHp(var_4_0:getHpLimit())
	var_4_0:getFighterModel():flipX(arg_4_0:getTeamType() == var_0_2.TeamType.B)
	var_4_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_4_0:born()
	var_4_0:setGlobalBuffs()
	var_4_0.fighterModel:setVisible(false)

	local var_4_5 = var_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_4_5, var_4_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_4_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_4_0.summonMonsters_, var_4_0)
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0 = var_0_6.new({
		tableID = arg_5_1,
		start = var_0_1.ctx.battle.count,
		level = arg_5_3,
		skillID = arg_5_2,
		fighter = arg_5_0,
		target = arg_5_4
	})

	return {
		var_5_0
	}
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}
	local var_6_1
	local var_6_2 = arg_6_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_6_3 = arg_6_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_6_0, iter_6_1 in ipairs(var_6_3) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_6_4 = iter_6_1:getX() * var_6_2

			if not var_6_1 then
				var_6_0 = {
					iter_6_1
				}
				var_6_1 = var_6_4
			elseif var_6_1 <= var_6_4 then
				if var_6_4 == var_6_1 then
					table.insert(var_6_0, iter_6_1)
				else
					var_6_0 = {
						iter_6_1
					}
					var_6_1 = var_6_4
				end
			end
		end
	end

	local var_6_5

	if #var_6_0 > 1 then
		var_6_5 = var_6_0[math.random(1, #var_6_0)]
	else
		var_6_5 = var_6_0[1]
	end

	return {
		var_6_5
	}
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0:selectTargetByTypeD1(arg_7_1, arg_7_2)
	local var_7_1 = {}

	if not next(var_7_0) then
		return {}
	end

	local var_7_2 = var_0_4:scope(arg_7_1)
	local var_7_3 = arg_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_7_0, iter_7_1 in ipairs(var_7_3) do
		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and math.abs(iter_7_1:getX() - var_7_0[1]:getX()) <= var_7_2 / 2 then
			table.insert(var_7_1, iter_7_1)
		end
	end

	return var_7_1
end

function var_0_3.beginAttackEnd(arg_8_0, arg_8_1)
	var_0_3.super.beginAttackEnd(arg_8_0, arg_8_1)

	if arg_8_1.rootID_ == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_8_0:getPositionNum()
	end
end

function var_0_3.isStunBuff(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getTableID()

	if var_0_5:adUnable(var_9_0) and var_0_5:apUnable(var_9_0) and (var_0_5:type(var_9_0) == var_0_2.BuffType.MOVE_SKILL_LIMIT and arg_9_1:isMoveUnable() or var_0_5:type(var_9_0) == var_0_2.BuffType.MOVE and (math.abs(var_0_5:x(var_9_0)) < 10 or var_0_5:y(var_9_0) >= 50)) and not arg_9_1:isFear() and not var_0_5:pause(var_9_0) and not var_0_5:sleep(var_9_0) then
		return true
	end

	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (arg_9_1:isFear() or arg_9_1:dBuffType() == var_0_2.DBuffType.BING_DONG or arg_9_1:dBuffType() == var_0_2.DBuffType.SHI_HUA or arg_9_1:dBuffType() == var_0_2.DBuffType.MEI_HUO) then
		return true
	end

	return false
end

function var_0_3.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7 = var_0_3.super.updateUnitDataByFighter(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)

	if arg_10_1.skillID == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_10_0, iter_10_1 in ipairs(arg_10_0.sortedHero) do
			if not iter_10_1:isDeath() and iter_10_1 == arg_10_1.target then
				arg_10_4 = (1 + (iter_10_0 - 1) * var_0_11) * arg_10_4

				break
			end
		end
	end

	return arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7
end

function var_0_3.getPositionNum(arg_11_0)
	local var_11_0 = arg_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA
	local var_11_1 = arg_11_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
	local var_11_2 = {}

	local function var_11_3(arg_12_0, arg_12_1)
		if arg_12_0:getX() * var_11_1 < arg_12_1:getX() * var_11_1 then
			return true
		else
			return false
		end
	end

	for iter_11_0, iter_11_1 in ipairs(var_11_0) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			table.insert(var_11_2, iter_11_1)
		end
	end

	table.sort(var_11_2, var_11_3)

	arg_11_0.sortedHero = var_11_2
end

return var_0_3
