local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseGanning", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = 6
local var_0_9 = 60
local var_0_10 = 120
local var_0_11 = 200
local var_0_12 = 450
local var_0_13 = 80032004
local var_0_14 = 89220004
local var_0_15 = 40010233
local var_0_16 = 40010211
local var_0_17 = 40010212

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.isHurtBreak(arg_2_0, arg_2_1, arg_2_2)
	return false
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.summonMirrows_ = {}
	arg_3_0.summonMonsters_ = {}
	arg_3_0.selectMirrow_ = nil
	arg_3_0.canMake = true
	arg_3_0.shanbiTime = 0
	arg_3_0.summonTimeCount = 0
	arg_3_0.countEnergyTime = nil
	arg_3_0.boomMonsters_ = {}
	arg_3_0.beforePos = nil
end

function var_0_3.die(arg_4_0)
	if next(arg_4_0.summonMirrows_) ~= true then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.summonMirrows_) do
			if not iter_4_1[1]:isDeath() then
				iter_4_1[1]:updateHp(0)
				iter_4_1[1]:die()
			end
		end
	end

	if next(arg_4_0.summonMonsters_) ~= true then
		for iter_4_2, iter_4_3 in ipairs(arg_4_0.summonMonsters_) do
			if not iter_4_3:isDeath() then
				iter_4_3:updateHp(0)
				iter_4_3:die()
			end
		end
	end

	var_0_3.super.die(arg_4_0)
end

function var_0_3.singleLoop(arg_5_0)
	var_0_3.super.singleLoop(arg_5_0)

	if arg_5_0.shanbiTime > 0 then
		arg_5_0.shanbiTime = arg_5_0.shanbiTime - 1
	end

	if arg_5_0:acttionInBlack() and not arg_5_0:isDeath() then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.summonMirrows_) do
			if iter_5_1[1]:isDeath() then
				table.remove(arg_5_0.summonMirrows_, iter_5_0)
			end
		end

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.summonMonsters_) do
			if iter_5_3:isDeath() then
				table.remove(arg_5_0.summonMonsters_, iter_5_2)
			end
		end
	end

	if arg_5_0:acttionInBlack() and not arg_5_0:isDeath() and arg_5_0.unitSkills_ and arg_5_0.unitSkills_.rootID_ == arg_5_0:getEnergySkillID() and arg_5_0.frontTime then
		arg_5_0.frontTime = arg_5_0.frontTime - 1

		if arg_5_0.frontTime == 0 then
			if next(arg_5_0.summonMirrows_) ~= nil then
				for iter_5_4, iter_5_5 in ipairs(arg_5_0.summonMirrows_) do
					if not iter_5_5[1]:isDeath() then
						iter_5_5[1]:updateHp(0)
						iter_5_5[1]:die()
					end
				end

				arg_5_0.summonMirrows_ = {}
			end

			local var_5_0 = var_0_5:summonMonster(arg_5_0:getEnergySkillID())

			if next(var_5_0) == nil then
				return
			end

			for iter_5_6, iter_5_7 in ipairs(var_5_0) do
				local var_5_1 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
				local var_5_2 = arg_5_0.hero_:getColor()

				arg_5_0:setSummonMirrows(iter_5_7, var_5_1, var_5_2)
			end

			arg_5_0.countEnergyTime = var_0_12
			arg_5_0.frontTime = nil
		end
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.selectMirrow_ then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0:getInfoByKey("attack_info")) do
			if iter_6_1.rootID_ == iter_6_1.fighter_:getEnergySkillID() then
				if iter_6_1.fighter_ == arg_6_0.selectMirrow_ then
					arg_6_0.countEnergyTime = nil

					if next(arg_6_0.summonMirrows_) then
						for iter_6_2, iter_6_3 in ipairs(arg_6_0.summonMirrows_) do
							if not iter_6_3[1]:isDeath() then
								iter_6_3[1]:updateHp(0)
								iter_6_3[1]:die()
							end
						end
					end

					arg_6_0.selectMirrow_ = nil

					arg_6_0.fighterModel:pos(arg_6_0.beforePos.x, arg_6_0.beforePos.y)
					arg_6_0:getFighterModel():flipX(arg_6_0:getTeamType() == var_0_2.TeamType.B)
				elseif next(arg_6_0.summonMirrows_) then
					for iter_6_4, iter_6_5 in ipairs(arg_6_0.summonMirrows_) do
						if not iter_6_5[1]:isDeath() and iter_6_1.fighter_ == iter_6_5[2] then
							arg_6_0:setMonsterBoom(iter_6_5[1])
							table.remove(arg_6_0.summonMirrows_, iter_6_4)
						end
					end

					if #arg_6_0.summonMirrows_ == 0 then
						arg_6_0.fighterModel:pos(arg_6_0.beforePos.x, arg_6_0.beforePos.y)
						arg_6_0:getFighterModel():flipX(arg_6_0:getTeamType() == var_0_2.TeamType.B)

						arg_6_0.selectMirrow_ = nil
					end
				end
			end
		end
	end

	if arg_6_0.countEnergyTime then
		arg_6_0.countEnergyTime = arg_6_0.countEnergyTime - 1

		if arg_6_0.countEnergyTime == 0 and arg_6_0.summonMirrows_ and next(arg_6_0.summonMirrows_) then
			for iter_6_6, iter_6_7 in ipairs(arg_6_0.summonMirrows_) do
				if not iter_6_7[1]:isDeath() then
					arg_6_0:setMonsterBoom(iter_6_7[1])
				end
			end

			arg_6_0.summonMirrows_ = {}
			arg_6_0.selectMirrow_ = nil

			arg_6_0.fighterModel:pos(arg_6_0.beforePos.x, arg_6_0.beforePos.y)
			arg_6_0:getFighterModel():flipX(arg_6_0:getTeamType() == var_0_2.TeamType.B)
		end
	end

	if arg_6_0.boomMonsters_ and next(arg_6_0.boomMonsters_) then
		for iter_6_8, iter_6_9 in ipairs(arg_6_0.boomMonsters_) do
			iter_6_9[1] = iter_6_9[1] - 1

			if iter_6_9[1] == 1 then
				iter_6_9[2]:updateHp(0)
				iter_6_9[2]:die()
				table.remove(arg_6_0.boomMonsters_, iter_6_8)
			end
		end
	end
end

function var_0_3.setMonsterBoom(arg_7_0, arg_7_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_7_0 = {
		x = arg_7_1:getX(),
		y = arg_7_1:getY()
	}
	local var_7_1 = arg_7_0.sideTeam_
	local var_7_2 = {}
	local var_7_3 = var_0_5:scope(var_0_13)

	for iter_7_0, iter_7_1 in ipairs(var_7_1) do
		local var_7_4 = iter_7_1:getX()

		if not iter_7_1:isDeath() and not iter_7_1:isAffected() and var_7_3 >= math.abs(var_7_4 - var_7_0.x) then
			table.insert(var_7_2, iter_7_1)
		end
	end

	local var_7_5 = arg_7_0:createAttackUnits(var_7_2, var_0_13)

	for iter_7_2, iter_7_3 in ipairs(var_7_5) do
		table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
		table.insert(arg_7_0.records_.special_units, iter_7_3)
	end

	arg_7_1:addBuffs(arg_7_0:newBuff(var_0_15, var_0_13, 1, arg_7_1))
	arg_7_1:getFighterModel():setVisible(false)
	table.insert(arg_7_0.boomMonsters_, {
		var_0_6:time(var_0_15),
		arg_7_1
	})
end

function var_0_3.beginAttackEnd(arg_8_0, arg_8_1)
	var_0_3.super.beginAttackEnd(arg_8_0, arg_8_1)

	if arg_8_1.rootID_ == arg_8_0:getEnergySkillID() then
		arg_8_0.frontTime = var_0_5:pretime(arg_8_0:getEnergySkillID())
	end
end

function var_0_3.getAPShanBi(arg_9_0)
	return var_0_11
end

function var_0_3.playShanbi(arg_10_0, arg_10_1)
	var_0_3.super.playShanbi(arg_10_0, arg_10_1)

	if arg_10_0.shanbiTime == 0 and arg_10_0.canMake == false then
		arg_10_0.canMake = true
	end

	if arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_10_0.canMake == true then
		local var_10_0 = var_0_14
		local var_10_1

		if var_0_5:type(arg_10_1.skillID) == var_0_2.AttackType.AP then
			var_10_1 = var_0_17
		else
			var_10_1 = var_0_16
		end

		local var_10_2 = arg_10_0:getSkillLevelByID(arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))
		local var_10_3 = arg_10_0.hero_:getColor()
		local var_10_4 = arg_10_0:getFlipX() and arg_10_0:getX() - 15 * math.random() or arg_10_0:getX() + 15 * math.random()
		local var_10_5 = var_0_1.ctx.battle.adjustX(var_10_4, arg_10_0)
		local var_10_6 = {
			x = var_10_5,
			y = arg_10_0:getY()
		}

		arg_10_0:setSummonMonsters(var_10_0, var_10_2, var_10_3, var_10_6, var_10_1)

		arg_10_0.canMake = false
		arg_10_0.shanbiTime = var_0_9
	end
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	if #arg_11_0.summonMonsters_ >= var_0_8 then
		return
	end

	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_11_1 = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0 = var_0_1.ctx.battle.summonMonsters[var_11_1]
	else
		local var_11_2 = var_0_7.new()

		var_11_2:populateWithTableID(arg_11_1)

		var_11_2.level_ = arg_11_2 or var_11_2.level_
		var_11_2.color_ = arg_11_3 or var_11_2.color_

		for iter_11_0, iter_11_1 in ipairs(var_11_2.skillLev_) do
			local var_11_3 = arg_11_0.hero_:getSkillLevel(iter_11_0)

			if var_11_3 and var_11_3 > 0 then
				var_11_2.skillLev_[iter_11_0] = var_0_0.clone(var_11_3)
			end
		end

		local var_11_4 = var_11_2:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_4).new({
			is_arena = arg_11_0.isInArena_
		})

		var_11_0:populateWithHero(var_11_2)
		var_11_0:initModels()
		var_11_0.fighterModel:initHeaderView(arg_11_0:getTeamType() - 1)

		var_11_0.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0:setFormationDelay(0, 100)
	end

	var_11_0:setTeamType(arg_11_0:getTeamType())

	var_11_0.summoner = arg_11_0

	local var_11_5 = {}

	for iter_11_2 = 1, var_0_8 do
		var_11_5[iter_11_2] = iter_11_2
	end

	for iter_11_3, iter_11_4 in ipairs(arg_11_0.summonMonsters_) do
		var_11_5[iter_11_4.SummonIndex] = 0
	end

	for iter_11_5, iter_11_6 in ipairs(var_11_5) do
		if iter_11_6 ~= 0 then
			var_11_0.SummonIndex = iter_11_6

			break
		end

		if iter_11_6 == var_0_8 then
			var_11_0.SummonIndex = 1
		end
	end

	local var_11_6 = 0

	if var_11_0.SummonIndex % 2 == 1 then
		var_11_6 = math.floor((var_11_0.SummonIndex + 1) / 2) * -50
	else
		var_11_6 = math.floor((var_11_0.SummonIndex + 1) / 2) * 30
	end

	var_11_0.fighterModel:pos(arg_11_4.x, arg_11_4.y + var_11_6)
	var_11_0:updateHp(var_11_0:getHpLimit())
	var_11_0:getFighterModel():flipX(arg_11_0:getTeamType() == var_0_2.TeamType.B)
	var_11_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_11_0:born()
	var_11_0:setGlobalBuffs()

	if arg_11_5 == var_0_16 then
		var_11_0:setMonsterType(1)
	else
		var_11_0:setMonsterType(2)
	end

	local var_11_7 = arg_11_0:newBuff(arg_11_5, 10010031, 1, var_11_0)

	var_11_7[1]:setYongJiu()
	var_11_0:addBuffs(var_11_7)

	local var_11_8 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_8, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_11_0.summonMonsters_, var_11_0)
end

function var_0_3.setSummonMirrows(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA
	local var_12_1 = arg_12_0:getSelectTargetIndex(var_12_0)

	for iter_12_0, iter_12_1 in ipairs(var_12_0) do
		if iter_12_1:getSummonType() == 0 and not iter_12_1:isDeath() and iter_12_0 ~= var_12_1 then
			local var_12_2
			local var_12_3 = {
				x = iter_12_1:getX(),
				y = iter_12_1:getY()
			}

			if iter_12_1:getTeamType() == var_0_2.TeamType.A then
				var_12_3.x = var_12_3.x + var_0_10
			else
				var_12_3.x = var_12_3.x - var_0_10
			end

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				local var_12_4 = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

				var_12_2 = var_0_1.ctx.battle.summonMonsters[var_12_4]
			else
				local var_12_5 = var_0_7.new()

				var_12_5:populateWithTableID(arg_12_1)

				var_12_5.level_ = arg_12_2 or var_12_5.level_
				var_12_5.color_ = arg_12_3 or var_12_5.color_

				for iter_12_2, iter_12_3 in ipairs(var_12_5.skillLev_) do
					local var_12_6 = var_12_5:getSkillId(iter_12_2)
					local var_12_7 = arg_12_0.hero_:getSkillLevelByID(var_12_6)

					if var_12_7 and var_12_7 > 0 then
						var_12_5.skillLev_[iter_12_2] = var_0_0.clone(var_12_7)
					end
				end

				local var_12_8 = var_12_5:className()

				var_12_2 = var_0_1.ctx.battle.requireFighter(var_12_8).new({
					is_arena = arg_12_0.isInArena_
				})

				var_12_2:populateWithHero(var_12_5)
				var_12_2:initModels()
				var_12_2.fighterModel:initHeaderView(arg_12_0:getTeamType() - 1)

				var_12_2.fighterIndex = arg_12_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

				var_12_2:setFormationDelay(0, 100)
			end

			var_12_2:setMonsterType(3)
			var_12_2:setMonsterTarget(iter_12_1)
			var_12_2:setTeamType(arg_12_0:getTeamType())

			var_12_2.summoner = arg_12_0

			var_12_2.fighterModel:pos(var_12_3.x, var_12_3.y)
			var_12_2:updateHp(var_12_2:getHpLimit())
			var_12_2:getFighterModel():flipX(arg_12_0:getTeamType() == var_0_2.TeamType.B)
			var_12_2.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
			var_12_2:born()
			var_12_2:setGlobalBuffs()

			local var_12_9 = var_12_2:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

			table.insert(var_12_9, var_12_2)
			table.insert(var_0_1.ctx.battle.yOrder, var_12_2)
			var_0_1.ctx.battle.updateZorder()

			arg_12_0.copyTime = var_0_0.clone(copyExistTime)

			table.insert(arg_12_0.summonMirrows_, {
				var_12_2,
				iter_12_1
			})
		elseif iter_12_1:getSummonType() == 0 and not iter_12_1:isDeath() and iter_12_0 == var_12_1 then
			local var_12_10 = {
				x = iter_12_1:getX(),
				y = iter_12_1:getY()
			}

			if iter_12_1:getTeamType() == var_0_2.TeamType.A then
				var_12_10.x = var_12_10.x + var_0_10
			else
				var_12_10.x = var_12_10.x - var_0_10
			end

			arg_12_0.beforePos = {
				x = arg_12_0:getX(),
				y = arg_12_0:getY()
			}

			arg_12_0.fighterModel:pos(var_12_10.x, var_12_10.y)
			arg_12_0:getFighterModel():flipX(arg_12_0:getTeamType() == var_0_2.TeamType.B)

			arg_12_0.selectMirrow_ = iter_12_1
		end
	end
end

function var_0_3.newBuff(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = var_0_4.new({
		tableID = arg_13_1,
		start = var_0_1.ctx.battle.count,
		level = arg_13_3,
		skillID = arg_13_2,
		fighter = arg_13_0,
		target = arg_13_4
	})

	return {
		var_13_0
	}
end

function var_0_3.getSelectTargetIndex(arg_14_0, arg_14_1)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
		if iter_14_1:getSummonType() == 0 and not iter_14_1:isDeath() then
			table.insert(var_14_0, iter_14_0)
		end
	end

	return var_14_0[math.random(#var_14_0)]
end

function var_0_3.deathFeedback(arg_15_0, arg_15_1)
	if arg_15_0.summonMirrows_ and next(arg_15_0.summonMirrows_) then
		for iter_15_0, iter_15_1 in ipairs(arg_15_0.summonMirrows_) do
			if iter_15_1[2] == arg_15_1 then
				table.remove(arg_15_0.summonMirrows_, iter_15_0)
				arg_15_0:reSelectFighter(iter_15_1)
			end
		end
	end
end

function var_0_3.reSelectFighter(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_1[1]
	local var_16_1, var_16_2 = var_16_0:getFighterModel():getPosition()
	local var_16_3
	local var_16_4

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and not iter_16_1:isAffected() and iter_16_1 ~= arg_16_0 and iter_16_1:getSummonType() == 0 then
			local var_16_5, var_16_6 = iter_16_1.fighterModel:getPosition()
			local var_16_7 = math.abs(var_16_1 - var_16_5)

			if not var_16_3 or var_16_7 < var_16_3 then
				var_16_3 = var_16_7
				var_16_4 = iter_16_1
			end
		end
	end

	var_16_0:setMonsterTarget(var_16_4)
	table.insert(arg_16_0.summonMirrows_, {
		var_16_0,
		var_16_4
	})
end

function var_0_3.checkEnergySkill(arg_17_0)
	if arg_17_0.selectMirrow_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_17_0)
	end
end

return var_0_3
