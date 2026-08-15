local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Manchong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 10001337
local var_0_9 = 10001338
local var_0_10 = 30010208
local var_0_11 = 450
local var_0_12 = 40011438
local var_0_13 = 900
local var_0_14 = 0.2
local var_0_15 = 40010208
local var_0_16 = 0.4
local var_0_17 = 50010208
local var_0_18 = 300
local var_0_19 = 30
local var_0_20 = 40011431
local var_0_21 = 40011432
local var_0_22 = 40011434
local var_0_23 = 10001339
local var_0_24 = 10001340
local var_0_25 = 80010208
local var_0_26 = 40012677
local var_0_27 = 40012678
local var_0_28 = 0.4
local var_0_29 = 0.25
local var_0_30 = 0.3
local var_0_31 = {
	40012679,
	40012680,
	40012681,
	40012682
}
local var_0_32 = {
	var_0_2.AttributeType.AD,
	var_0_2.AttributeType.AP,
	var_0_2.AttributeType.HUJIA,
	var_0_2.AttributeType.MOKANG
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("death_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.mirrorHeros = {}
	arg_2_0.isEnerging = false
	arg_2_0.isImmuneControl = false
	arg_2_0.isEscapeEnemyMove = false
	arg_2_0.coffin = nil
	arg_2_0.coffinTarget = nil
	arg_2_0.energyLeftCount = 0
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 then
		arg_3_0.GreenSkillID = 10002486
		arg_3_0.BlueAddADBuffID1 = 40012683
		arg_3_0.BlueAddADBuffID2 = 40012684
		arg_3_0.EnergySummonMonsterID = 80000325
	else
		arg_3_0.GreenSkillID = 20010208
		arg_3_0.BlueAddADBuffID1 = 40011437
		arg_3_0.BlueAddADBuffID2 = 40012684
		arg_3_0.EnergySummonMonsterID = 80000303
	end
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_2 then
		return var_0_4.B1(arg_4_0, arg_4_1)
	end

	if not arg_4_2.targets_ or not next(arg_4_2.targets_) then
		return
	end

	local var_4_0 = arg_4_2.targets_
	local var_4_1, var_4_2 = var_4_0[#var_4_0]:getPos()
	local var_4_3 = 99999999
	local var_4_4

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if iter_4_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_5, var_4_6 = iter_4_1:getPos()
			local var_4_7 = math.abs(var_4_5 - var_4_1)

			if var_4_7 <= var_4_3 and not arg_4_2.recordTargets_[iter_4_1.fighterIndex] then
				var_4_4 = iter_4_1
				var_4_3 = var_4_7
			end
		end
	end

	if not var_4_4 then
		arg_4_2:clearCollisionNum()

		local var_4_8 = 0

		for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
			if iter_4_3:getSummonType() == var_0_2.summonMonsterType.None and not iter_4_3:isDeath() and not iter_4_3:isAffected() then
				local var_4_9 = iter_4_3:getAttrByType(var_0_2.AttributeType.AGILE)

				if var_4_8 <= var_4_9 then
					var_4_4 = iter_4_3
					var_4_8 = var_4_9
				end
			end
		end
	end

	return {
		var_4_4
	}
end

function var_0_3.onApplyEnergyChildSkill1(arg_5_0, arg_5_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_1
		}, var_0_23)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.onApplyEnergyChildSkill2(arg_6_0, arg_6_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_1
		}, var_0_24)

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_1.skillID == arg_7_0.GreenSkillID then
		if arg_7_1.target:getTeamType() == arg_7_0:getTeamType() then
			local var_7_0 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_9)

			for iter_7_0, iter_7_1 in ipairs(var_7_0) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		else
			local var_7_1 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_8)

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end

	if arg_7_1.skillID == var_0_17 then
		if arg_7_0:getSkillLevelByID(var_0_17) < arg_7_1.target:getLevel() or arg_7_1.target:isBoss() then
			arg_7_0:onApplyEnergyChildSkill2(arg_7_1.target)
		elseif not arg_7_0.coffin or arg_7_0.coffin:isDeath() then
			arg_7_0.isImmuneControl = true
			arg_7_0.isEscapeEnemyMove = true

			arg_7_0:getFighterModel():playAnimation_("gongji04", true)

			local var_7_2 = 0

			for iter_7_4, iter_7_5 in ipairs(arg_7_0.sideTeam_) do
				if not iter_7_5:isDeath() and iter_7_5.hero_:getHeroType() == var_0_2.HeroType.WISE and iter_7_5:getSummonType() == var_0_2.summonMonsterType.None then
					var_7_2 = var_7_2 + 1
				end
			end

			arg_7_0.energyLeftCount = math.max(var_0_18 - var_7_2 * var_0_19, 0)

			local var_7_3 = {
				x = arg_7_1.target:getX(),
				y = arg_7_1.target:getY()
			}

			arg_7_0.coffin = arg_7_0:setSummonMonsters(arg_7_0.EnergySummonMonsterID, arg_7_0:getSkillLevelByID(var_0_17), arg_7_0.hero_:getColor(), var_7_3, var_0_17)
			arg_7_0.coffinTarget = arg_7_1.target

			local var_7_4 = var_0_6.new({
				tableID = var_0_20,
				start = var_0_1.ctx.battle.count,
				level = arg_7_0:getSkillLevelByID(var_0_17),
				skillID = var_0_17,
				fighter = arg_7_0,
				target = arg_7_0.coffinTarget
			})

			arg_7_0.coffinTarget:addBuffs({
				var_7_4
			})
		end

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_5 = arg_7_1.target:getAP() * var_0_28

			for iter_7_6, iter_7_7 in ipairs(arg_7_0.selfTeam_) do
				if not iter_7_7:isDeath() and not iter_7_7:isAffected() then
					local var_7_6 = arg_7_0:createNewBuffs({
						var_0_27
					}, iter_7_7, var_0_25)

					var_7_6[1].manualRevise = var_7_5

					iter_7_7:addBuffs(var_7_6)
				end
			end

			local var_7_7 = arg_7_0:createNewBuffs({
				var_0_26
			}, arg_7_1.target, var_0_25)

			arg_7_1.target:addBuffs(var_7_7)
		end
	end
end

function var_0_3.setSummonMonsters(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_0 = arg_8_0:getSummonMonster()
	else
		local var_8_1 = var_0_5.new()

		var_8_1:populateWithTableID(arg_8_1)

		var_8_1.level_ = arg_8_2 or var_8_1.level_
		var_8_1.color_ = arg_8_3 or var_8_1.color_

		for iter_8_0, iter_8_1 in ipairs(var_8_1.skillLev_) do
			local var_8_2 = arg_8_0.hero_:getSkillLevel(iter_8_0)

			if var_8_2 and var_8_2 > 0 then
				var_8_1.skillLev_[iter_8_0] = var_0_0.clone(var_8_2)
			end
		end

		local var_8_3 = var_8_1:className()

		var_8_0 = var_0_1.ctx.battle.requireFighter(var_8_3).new({
			is_arena = arg_8_0.isInArena_
		})

		var_8_0:populateWithHero(var_8_1)
		var_8_0:initModels()
		var_8_0.fighterModel:initHeaderView(arg_8_0:getTeamType() - 1)

		var_8_0.fighterIndex = arg_8_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_8_0:setFormationDelay(0, 0)
	end

	var_8_0:setTeamType(arg_8_0:getTeamType())

	var_8_0.summoner = arg_8_0

	var_8_0.fighterModel:pos(arg_8_4.x, arg_8_4.y)

	var_8_0.isImmuneControl = true
	var_8_0.isEscapeEnemyMove = true

	var_8_0:updateHp(var_8_0:getHpLimit())
	var_8_0:getFighterModel():flipX(arg_8_0:getTeamType() == var_0_2.TeamType.B)
	var_8_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_8_0:born()
	var_8_0:setGlobalBuffs()

	local var_8_4 = var_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_8_4, var_8_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_8_0)
	var_0_1.ctx.battle.updateZorder()

	return var_8_0
end

function var_0_3.toDoPerFrames(arg_9_0)
	if arg_9_0.coffin and not arg_9_0.coffin:isDeath() then
		arg_9_0.isEnerging = true
	else
		arg_9_0.isEnerging = false
	end

	for iter_9_0, iter_9_1 in ipairs(arg_9_0:getInfoByKey("death_info")) do
		if iter_9_1 == arg_9_0.coffin and arg_9_0.coffinTarget:isHasBuffByID(var_0_20) then
			if not arg_9_0:isDeath() then
				arg_9_0:onEnergySkillEnd()
			end

			arg_9_0.coffinTarget:removeBuffByID(var_0_20)
			arg_9_0:onApplyEnergyChildSkill1(arg_9_0.coffinTarget)
		end

		if arg_9_0.skinSkillIndex_ == 1 and iter_9_1:getTeamType() ~= arg_9_0:getTeamType() then
			local var_9_0 = arg_9_0:createNewBuffs(var_0_31, arg_9_0, var_0_25)

			for iter_9_2, iter_9_3 in ipairs(var_9_0) do
				local var_9_1 = var_0_32[iter_9_2]

				iter_9_3.manualRevise = iter_9_1:getAttrByType(var_9_1) * var_0_29
				iter_9_3.manualRevise = math.min(iter_9_3.manualRevise, arg_9_0:getAttrByType(var_9_1) * var_0_30)
			end

			arg_9_0:addBuffs(var_9_0)
		end
	end

	if arg_9_0.energyLeftCount > 0 then
		arg_9_0.energyLeftCount = arg_9_0.energyLeftCount - 1
	elseif arg_9_0.coffin and not arg_9_0.coffin:isDeath() and arg_9_0.coffinTarget and arg_9_0.coffinTarget:isHasBuffByID(var_0_20) and not arg_9_0.coffinTarget:isHasBuffByID(var_0_21) then
		if not arg_9_0:isDeath() then
			arg_9_0:onEnergySkillEnd()
		end

		arg_9_0.coffinTarget:removeBuffByID(var_0_20)

		local var_9_2 = var_0_6.new({
			tableID = var_0_22,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(var_0_17),
			skillID = var_0_17,
			fighter = arg_9_0,
			target = arg_9_0.coffin
		})

		arg_9_0.coffin:addBuffs({
			var_9_2
		})

		local var_9_3 = var_0_6.new({
			tableID = var_0_21,
			start = var_0_1.ctx.battle.count,
			level = arg_9_0:getSkillLevelByID(var_0_17),
			skillID = var_0_17,
			fighter = arg_9_0,
			target = arg_9_0.coffinTarget
		})

		arg_9_0.coffinTarget:addBuffs({
			var_9_3
		})
	end

	if arg_9_0:isDeath() then
		return
	end

	if arg_9_0:getSkillLevelByID(var_0_10) > 0 then
		for iter_9_4, iter_9_5 in ipairs(arg_9_0.selfTeam_) do
			if not iter_9_5:isDeath() and not iter_9_5:isAffected() and iter_9_5:getSummonType() == var_0_2.summonMonsterType.None and iter_9_5.hero_:getHeroType() ~= var_0_2.HeroType.WISE and not iter_9_5:isHasBuffByID(arg_9_0.BlueAddADBuffID1) then
				local var_9_4 = var_0_6.new({
					tableID = arg_9_0.BlueAddADBuffID1,
					start = var_0_1.ctx.battle.count,
					level = arg_9_0:getSkillLevelByID(var_0_10),
					skillID = var_0_10,
					fighter = arg_9_0,
					target = iter_9_5
				})

				iter_9_5:addBuffs({
					var_9_4
				})

				if arg_9_0.skinSkillIndex_ == 1 then
					local var_9_5 = var_0_6.new({
						tableID = arg_9_0.BlueAddADBuffID2,
						start = var_0_1.ctx.battle.count,
						level = arg_9_0:getSkillLevelByID(var_0_10),
						skillID = var_0_10,
						fighter = arg_9_0,
						target = iter_9_5
					})

					iter_9_5:addBuffs({
						var_9_5
					})
				end
			end
		end
	end

	if arg_9_0.coffin and not arg_9_0.coffin:isDeath() then
		for iter_9_6, iter_9_7 in ipairs(arg_9_0.sideTeam_) do
			if not iter_9_7:isDeath() and iter_9_7:getSummonType() == var_0_2.summonMonsterType.None and iter_9_7 ~= arg_9_0.coffinTarget then
				return
			end
		end

		arg_9_0.coffin:forceDie()

		arg_9_0.isImmuneControl = false
		arg_9_0.isEscapeEnemyMove = false

		if arg_9_0.coffinTarget and not arg_9_0.coffinTarget:isDeath() then
			arg_9_0.coffinTarget:removeBuffByID(var_0_20)
			arg_9_0.coffinTarget:removeBuffByID(var_0_21)
		end
	end
end

function var_0_3.buffRemoveAction(arg_10_0, arg_10_1)
	if arg_10_1:getTableID() == var_0_21 then
		arg_10_0.coffin:forceDie()
	end
end

function var_0_3.forceDie(arg_11_0)
	if arg_11_0:getSkillLevelByID(var_0_10) > 0 then
		for iter_11_0, iter_11_1 in ipairs(arg_11_0.selfTeam_) do
			if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and iter_11_1.hero_:getHeroType() ~= var_0_2.HeroType.WISE and iter_11_1:isHasBuffByID(arg_11_0.BlueAddADBuffID1) then
				iter_11_1:removeBuffByID(arg_11_0.BlueAddADBuffID1)
				iter_11_1:removeBuffByID(arg_11_0.BlueAddADBuffID2)
			end
		end
	end

	for iter_11_2, iter_11_3 in ipairs(arg_11_0.mirrorHeros) do
		if not iter_11_3:isDeath() then
			iter_11_3:forceDie()
		end
	end

	if arg_11_0.coffin and not arg_11_0.coffin:isDeath() and arg_11_0.coffinTarget and not arg_11_0.coffinTarget:isDeath() then
		arg_11_0.coffin:forceDie()
	end

	var_0_3.super.forceDie(arg_11_0)
end

function var_0_3.updateUnitDataBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	local var_12_0 = arg_12_2
	local var_12_1 = arg_12_3
	local var_12_2 = arg_12_4
	local var_12_3 = arg_12_5
	local var_12_4 = arg_12_6
	local var_12_5 = arg_12_7

	if arg_12_0:getSkillLevelByID(var_0_10) > 0 and arg_12_1.attackType == var_0_2.AttackType.AD and arg_12_1.fighter:getTeamType() == arg_12_0:getTeamType() and arg_12_1.target:getTeamType() ~= arg_12_0:getTeamType() and var_12_2 > 0 and var_0_1.ctx.battle.count > var_0_13 then
		var_12_4 = var_12_4 + var_12_2 * var_0_14
	end

	return var_12_0, var_12_1, var_12_2, var_12_3, var_12_4, var_12_5
end

function var_0_3.updateUnitInfoBySpecialHero(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	if arg_13_0:getSkillLevelByID(var_0_10) > 0 and arg_13_1.attackType == var_0_2.AttackType.AD and arg_13_1.fighter:getTeamType() == arg_13_0:getTeamType() and arg_13_1.target:getTeamType() ~= arg_13_0:getTeamType() and arg_13_4 > 0 and var_0_1.ctx.battle.count > var_0_11 then
		local var_13_0 = var_0_6.new({
			tableID = var_0_12,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0:getSkillLevelByID(var_0_10),
			skillID = var_0_10,
			fighter = arg_13_0,
			target = arg_13_1.target
		})

		arg_13_1.target:addBuffs({
			var_13_0
		})
	end
end

function var_0_3.deathFeedback(arg_14_0, arg_14_1)
	if arg_14_0:getSkillLevelByID(var_0_15) > 0 and arg_14_0:getTeamType() ~= arg_14_1:getTeamType() and arg_14_0:getSummonType() == var_0_2.summonMonsterType.None and arg_14_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_14_0:summonHeroMirror(arg_14_1, var_0_15)
	end
end

function var_0_3.onEnergySkillEnd(arg_15_0)
	arg_15_0:playAttack(5)

	arg_15_0.isImmuneControl = false
	arg_15_0.isEscapeEnemyMove = false
end

function var_0_3.checkEnergySkill(arg_16_0)
	if arg_16_0.isEnerging then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_16_0)
end

function var_0_3.canAttack(arg_17_0)
	if arg_17_0.coffinTarget and not arg_17_0.coffinTarget:isDeath() and arg_17_0.coffinTarget:isHasBuffByID(var_0_20) then
		return false
	end

	return var_0_3.super.canAttack(arg_17_0)
end

function var_0_3.summonHeroMirror(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_0:getSkillLevelByID(arg_18_2)
	local var_18_1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_18_1 = arg_18_0:getSummonMonster()

		if not var_18_1 then
			arg_18_0:summonMonstersErrorLog()
		end
	else
		local var_18_2 = var_0_5.new()
		local var_18_3 = arg_18_1.hero_:toParams()

		var_18_2:populate(var_18_3)

		var_18_2.level_ = var_18_0 < 100 and var_18_0 or 100

		local var_18_4 = var_18_2:className()

		var_18_1 = var_0_1.ctx.battle.requireFighter(var_18_4).new({
			is_arena = arg_18_0.isInArena_
		})

		var_18_1:populateWithHero(var_18_2)

		for iter_18_0, iter_18_1 in pairs(var_18_1.skillLevelByID_) do
			var_18_1.skillLevelByID_[iter_18_0] = var_18_0
		end

		for iter_18_2, iter_18_3 in pairs(var_18_1.skillLevelByColor_) do
			if var_18_1.hero_:getSkillId(iter_18_2) > 0 then
				var_18_1.skillLevelByColor_[iter_18_2] = var_18_0
			end
		end

		var_18_1:initModels()
		var_18_1.fighterModel:initHeaderView(arg_18_0:getTeamType() - 1)

		var_18_1.fighterIndex = arg_18_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_18_1:setFormationDelay(0, 100)

		var_18_1.startSkillQueue_ = {}
		var_18_1.skillQueue_ = arg_18_1.skillQueue_

		var_18_1:updateEnergyTo(arg_18_1:getEnergy())
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_18_1:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_18_1:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_18_1.summonType_ = var_0_2.summonMonsterType.Copy

	var_18_1:setSummonAutoFight(true)

	var_18_1.hasReborn_ = true

	var_18_1:setTeamType(arg_18_0:getTeamType())

	var_18_1.summoner = arg_18_0

	var_18_1.fighterModel:pos(arg_18_1:getPos())
	var_18_1:getFighterModel():flipX(arg_18_1:getFlipX())
	var_18_1.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_18_1:born()
	var_18_1:setGlobalBuffs()
	var_18_1:updateHp(var_18_1:getHpLimit() * var_0_16)

	local var_18_5 = var_18_1:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_18_5, var_18_1)
	table.insert(var_0_1.ctx.battle.yOrder, var_18_1)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_18_0.mirrorHeros, var_18_1)

	return var_18_1
end

function var_0_3.selectTargetByTypeD4(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = 0
	local var_19_1

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.sideTeam_) do
		if not iter_19_1:isDeath() and not iter_19_1:isAffected() and iter_19_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_19_2 = iter_19_1:getAttrByType(var_0_2.AttributeType.AP)

			if var_19_0 <= var_19_2 then
				var_19_1 = iter_19_1
				var_19_0 = var_19_2
			end
		end
	end

	return {
		var_19_1
	}
end

return var_0_3
