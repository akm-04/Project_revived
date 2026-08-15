local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guyong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = 40010978
local var_0_9 = 10000903
local var_0_10 = 40010976
local var_0_11 = 40010977
local var_0_12 = 10
local var_0_13 = 6
local var_0_14 = 3
local var_0_15 = 40010975
local var_0_16 = 80010169
local var_0_17 = 10001460
local var_0_18 = {
	40011510,
	40011511
}
local var_0_19 = 80020169
local var_0_20 = 300
local var_0_21 = -45
local var_0_22 = 40012197

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
	arg_1_0:listenInfo("action_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 2 then
		arg_2_0.BlueShowBuffID = 40012198
		arg_2_0.BlueDragonPugong1 = 10002049
		arg_2_0.BlueDragonPugong2 = 10002050
		arg_2_0.BlueDragonPugong3 = 10002051
		arg_2_0.PurpleChildSkillID = 10002054
	else
		arg_2_0.BlueShowBuffID = 40010974
		arg_2_0.BlueDragonPugong1 = 10000896
		arg_2_0.BlueDragonPugong2 = 10000897
		arg_2_0.BlueDragonPugong3 = 10000898
		arg_2_0.PurpleChildSkillID = 10000900
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.summonMonsters_ = {}
	arg_3_0.blueTotalHp_ = {
		0,
		0
	}
	arg_3_0.blueTotalHarm_ = {
		0,
		0
	}
	arg_3_0.blueTotalHpJudge_ = false
	arg_3_0.blueDragonSoul_ = 0
	arg_3_0.blueDragonLev_ = nil
	arg_3_0.purpleCenterTarget_ = nil
	arg_3_0.isEnergyType = false
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		if arg_4_0.summonMonsters_ and next(arg_4_0.summonMonsters_) then
			for iter_4_0 = #arg_4_0.summonMonsters_, 1, -1 do
				if not arg_4_0.summonMonsters_[iter_4_0]:isDeath() then
					arg_4_0.summonMonsters_[iter_4_0]:specialAttack()
				end
			end

			arg_4_0.summonMonsters_ = {}
		end

		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not arg_4_0.blueTotalHpJudge_ then
		arg_4_0.blueTotalHpJudge_ = true

		for iter_4_1, iter_4_2 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_2:isDeath() and not iter_4_2:isAffected() then
				arg_4_0.blueTotalHp_[1] = arg_4_0.blueTotalHp_[1] + iter_4_2:getHpLimit()
			end
		end

		for iter_4_3, iter_4_4 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_4:isDeath() and not iter_4_4:isAffected() then
				arg_4_0.blueTotalHp_[2] = arg_4_0.blueTotalHp_[2] + iter_4_4:getHpLimit()
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and (not arg_4_0.blueDragonLev_ or arg_4_0.blueDragonLev_ < 3) then
		for iter_4_5, iter_4_6 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_0 = iter_4_6.harm
			local var_4_1 = iter_4_6.target

			if var_4_0 > 0 and var_4_1:getTeamType() == arg_4_0:getTeamType() then
				arg_4_0.blueTotalHarm_[1] = arg_4_0.blueTotalHarm_[1] + var_4_0
			elseif var_4_0 > 0 then
				arg_4_0.blueTotalHarm_[2] = arg_4_0.blueTotalHarm_[2] + var_4_0
			end
		end

		local var_4_2 = 0

		if arg_4_0.blueTotalHp_[1] > 0 then
			var_4_2 = var_4_2 + math.floor(100 * arg_4_0.blueTotalHarm_[1] / (arg_4_0.blueTotalHp_[1] * var_0_13))
		end

		if arg_4_0.blueTotalHp_[2] > 0 then
			var_4_2 = var_4_2 + math.floor(100 * arg_4_0.blueTotalHarm_[2] / (arg_4_0.blueTotalHp_[2] * var_0_14))
		end

		arg_4_0.blueDragonSoul_ = var_4_2

		arg_4_0:changeBlueType()
	end

	if arg_4_0.isEnergyType and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_3 = {}

		for iter_4_7, iter_4_8 in ipairs(arg_4_0:getInfoByKey("action_info")) do
			local var_4_4 = iter_4_8.fighter
			local var_4_5 = iter_4_8.action_type

			if not var_4_4:isDeath() and not var_4_4:isAffected() and var_4_4:getTeamType() ~= arg_4_0:getTeamType() and (var_4_5 == var_0_2.ActionType.walk or var_4_5 == var_0_2.ActionType.attack) then
				table.insert(var_4_3, var_4_4)
			end
		end

		if next(var_4_3) then
			local var_4_6 = arg_4_0:createAttackUnits(var_4_3, var_0_9)

			for iter_4_9, iter_4_10 in ipairs(var_4_6) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_10)
				table.insert(arg_4_0.records_.special_units, iter_4_10)
			end
		end
	end
end

function var_0_3.changeBlueType(arg_5_0)
	local var_5_0 = -1

	if arg_5_0.blueDragonSoul_ > 0 then
		var_5_0 = math.floor(arg_5_0.blueDragonSoul_ / 10)
		var_5_0 = var_5_0 > 3 and 3 or var_5_0
	end

	if var_5_0 == arg_5_0.blueDragonLev_ then
		return
	end

	arg_5_0.blueDragonLev_ = var_5_0

	arg_5_0:removeBuffByID(arg_5_0.BlueShowBuffID)

	local var_5_1 = {
		arg_5_0.BlueShowBuffID
	}

	if var_5_0 == 2 then
		table.insert(var_5_1, var_0_15)
	end

	local var_5_2 = arg_5_0:newBuff(var_5_1, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	arg_5_0:addBuffs(var_5_2)
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	local var_6_0 = var_0_3.super.getOrbOfFrontSkill(arg_6_0)

	if var_0_4:father(var_6_0) == arg_6_0:getPugongID() and arg_6_0.blueDragonLev_ then
		if arg_6_0.blueDragonLev_ == 1 then
			var_6_0 = arg_6_0.BlueDragonPugong1
		elseif arg_6_0.blueDragonLev_ == 2 then
			var_6_0 = arg_6_0.BlueDragonPugong2
		elseif arg_6_0.blueDragonLev_ == 3 then
			var_6_0 = arg_6_0.BlueDragonPugong3
		end
	end

	return var_6_0
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if arg_7_1.rootID_ == arg_7_0:getEnergySkillID() then
		if arg_7_0.skinSkillID_ == var_0_19 then
			local var_7_0 = arg_7_0:createNewBuffs({
				var_0_22
			}, arg_7_0, var_0_19)

			arg_7_0:addBuffs(var_7_0)
		end

		arg_7_0.isEnergyType = true

		arg_7_0:setImmuneControl(true)

		if arg_7_0.skinSkillID_ == var_0_16 then
			for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
					local var_7_1 = arg_7_0:newBuff({
						var_0_10,
						var_0_11,
						var_0_10,
						var_0_11,
						var_0_10,
						var_0_11
					}, iter_7_1, var_0_16, arg_7_0:getLevel())

					iter_7_1:addBuffs(var_7_1)
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getTableID() == arg_8_0.BlueShowBuffID then
		arg_8_1:setActNum(arg_8_0.blueDragonLev_ + 2)
	elseif arg_8_1:getTableID() == var_0_10 then
		local var_8_0 = #arg_8_1.target:getBuffsByID(var_0_10) + 1

		if var_8_0 > 10 then
			var_8_0 = 10
		end

		arg_8_1:setActNum(var_8_0)

		if arg_8_0.skinSkillID_ == var_0_16 then
			local var_8_1 = arg_8_0:newBuff(var_0_18, arg_8_0, var_0_16, arg_8_0:getLevel())

			arg_8_0:addBuffs(var_8_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	var_0_3.super.buffRemoveAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_8 then
		if arg_9_0.skinSkillID_ == var_0_19 then
			arg_9_0:updateEnergyBy(var_0_20)
			arg_9_0:removeBuffByID(var_0_22)
		end

		arg_9_0.isEnergyType = false

		arg_9_0:setImmuneControl(false)

		if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_9_0:purpleAttack()
		end
	end
end

function var_0_3.purpleAttack(arg_10_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_10_0:isCreatingUnits() then
		return
	end

	local var_10_0 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	local var_10_1 = var_0_4:sound(var_10_0)

	var_0_1.ctx.battle.pushSoundQueue(var_10_1)

	local var_10_2 = var_0_4:attackIndex(var_10_0)

	arg_10_0:playAttack(var_10_2)

	arg_10_0.unitSkills_ = var_0_7.new({
		fighter = arg_10_0,
		skillID = var_10_0
	})

	arg_10_0:beginAttackEnd(arg_10_0.unitSkills_)
end

function var_0_3.applySingleUnit(arg_11_0, arg_11_1)
	var_0_3.super.applySingleUnit(arg_11_0, arg_11_1)

	if var_0_4:father(arg_11_1.skillID) == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_11_1.skillID == var_0_17 then
		arg_11_0:summonMonsters(arg_11_1.skillID)
	end

	if arg_11_0.skinSkillID_ == var_0_19 and arg_11_1.skillID == var_0_9 then
		arg_11_1.target:updateEnergyBy(var_0_21)
	end
end

function var_0_3.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	local var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5 = var_0_3.super.updateUnitDataByFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)

	if var_12_2 > 0 and arg_12_1.skillID == arg_12_0.PurpleChildSkillID and arg_12_0.purpleCenterTarget_ then
		local var_12_6 = arg_12_1.target:getX()
		local var_12_7 = arg_12_0.purpleCenterTarget_:getX()

		var_12_2 = var_12_2 * (1 - math.abs(var_12_7 - var_12_6) / 1000)
	end

	return var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = arg_13_4 or arg_13_0:getSkillLevelByID(arg_13_3) or 0
	local var_13_1 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_2 = var_0_5.new({
			tableID = iter_13_1,
			start = var_0_1.ctx.battle.count,
			level = var_13_0,
			skillID = arg_13_3,
			fighter = arg_13_0,
			target = arg_13_2
		})

		var_13_2:setIsHit(true)
		var_13_2:setDirection(arg_13_0:getFighterModel():getFlipX())
		table.insert(var_13_1, var_13_2)
	end

	return var_13_1
end

function var_0_3.summonMonsters(arg_14_0, arg_14_1)
	local var_14_0 = var_0_4:summonMonster(arg_14_1)

	if next(var_14_0) == nil then
		return
	end

	for iter_14_0, iter_14_1 in ipairs(var_14_0) do
		local var_14_1 = arg_14_0:getSkillLevelByID(arg_14_1)
		local var_14_2 = arg_14_0.hero_:getColor()
		local var_14_3 = arg_14_0:getFlipX() and -1 or 1
		local var_14_4 = arg_14_0:getX() + var_14_3 * 100
		local var_14_5 = var_0_1.ctx.battle.adjustX(var_14_4, arg_14_0)
		local var_14_6 = {
			x = var_14_5,
			y = arg_14_0:getY()
		}

		arg_14_0:setSummonMonsters(iter_14_1, var_14_1, var_14_2, var_14_6)
	end
end

function var_0_3.setSummonMonsters(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4)
	local var_15_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_15_0 = arg_15_0:getSummonMonster()
	else
		local var_15_1 = var_0_6.new()

		var_15_1:populateWithTableID(arg_15_1)

		var_15_1.level_ = arg_15_2 or var_15_1.level_
		var_15_1.color_ = arg_15_3 or var_15_1.color_

		for iter_15_0, iter_15_1 in ipairs(var_15_1.skillLev_) do
			local var_15_2 = arg_15_0.hero_:getSkillLevel(iter_15_0)

			if var_15_2 and var_15_2 > 0 then
				var_15_1.skillLev_[iter_15_0] = var_0_0.clone(var_15_2)
			end
		end

		local var_15_3 = var_15_1:className()

		var_15_0 = var_0_1.ctx.battle.requireFighter(var_15_3).new({
			is_arena = arg_15_0.isInArena_
		})

		var_15_0:populateWithHero(var_15_1)
		var_15_0:initModels()
		var_15_0.fighterModel:initHeaderView(arg_15_0:getTeamType() - 1)

		var_15_0.fighterIndex = arg_15_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_15_0:setFormationDelay(0, 100)
	end

	var_15_0.fighterModel:hideHeaderView(false)
	var_15_0:setTeamType(arg_15_0:getTeamType())

	var_15_0.summoner = arg_15_0

	var_15_0.fighterModel:pos(arg_15_4.x, arg_15_4.y)
	var_15_0:getFighterModel():flipX(arg_15_0:getTeamType() == var_0_2.TeamType.B)
	var_15_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_15_0:born()
	var_15_0:setGlobalBuffs()
	var_15_0:updateHp(var_15_0:getHpLimit())
	table.insert(arg_15_0.summonMonsters_, var_15_0)

	local var_15_4 = var_15_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_15_4, var_15_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_15_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.selectTargetByTypeC30(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_2 and arg_16_2.manualTargets_ then
		return arg_16_2.manualTargets_
	end

	local function var_16_0(arg_17_0, arg_17_1)
		local var_17_0 = {}

		table.insert(var_17_0, arg_17_0)

		for iter_17_0, iter_17_1 in ipairs(arg_16_0.sideTeam_) do
			if not iter_17_1:isDeath() and not iter_17_1:isAffected() and iter_17_1 ~= arg_17_0 and arg_17_1 >= math.abs(iter_17_1:getX() - arg_17_0:getX()) then
				table.insert(var_17_0, iter_17_1)
			end
		end

		return var_17_0
	end

	local var_16_1 = {}
	local var_16_2 = 0
	local var_16_3
	local var_16_4 = var_0_4:scope(arg_16_1) * 0.5

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() then
			local var_16_5 = var_16_0(iter_16_1, var_16_4)

			if var_16_2 < #var_16_5 then
				var_16_1 = var_16_5
				var_16_2 = #var_16_5
				var_16_3 = iter_16_1
			end
		end
	end

	arg_16_0.purpleCenterTarget_ = var_16_3

	return var_16_1
end

function var_0_3.checkEnergySkill(arg_18_0)
	if arg_18_0.isEnergyType then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_18_0)
end

return var_0_3
