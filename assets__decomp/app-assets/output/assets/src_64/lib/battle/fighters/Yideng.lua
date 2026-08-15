local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yideng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.hero
local var_0_10 = 0.2
local var_0_11 = 0.002
local var_0_12 = 40011953
local var_0_13 = 10
local var_0_14 = 900
local var_0_15 = 4.5
local var_0_16 = 22
local var_0_17 = 10001806

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueSelfHero = nil
	arg_1_0.blueSideHero = nil
	arg_1_0.sideHeroEnergyInfo = {}
	arg_1_0.purpleSkillCount = 0
	arg_1_0.isChanged = false
	arg_1_0.purpleBuffs = {}
	arg_1_0.records_.purple_buff_add = {}
	arg_1_0.summonMonsters_ = {}
	arg_1_0.greenEffects = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0.purpleSkillCount > 0 and arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_2_0.purpleSkillCount = arg_2_0.purpleSkillCount + 1

		if arg_2_0.purpleSkillCount > var_0_14 - var_0_15 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) then
			arg_2_0.purpleSkillCount = 0
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_2_0.blueSelfHero and arg_2_0.blueSideHero and not arg_2_0.blueSelfHero:isDeath() and not arg_2_0.blueSideHero:isDeath() and not arg_2_0.blueSelfHero:isAffected() and not arg_2_0.blueSideHero:isAffected() then
		arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count] = arg_2_0.blueSideHero:getEnergy()

		if arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count - 1] and arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count] - arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count - 1] > 0 then
			local var_2_0 = arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count] - arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count - 1]

			arg_2_0.blueSelfHero:updateEnergyBy(var_2_0 * (var_0_10 + arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_11))

			if arg_2_0.sideHeroEnergyInfo[var_0_1.ctx.battle.count] < var_0_2.ENERGY_DECIMAL_BASE then
				arg_2_0.blueSideHero:updateEnergyBy(-var_2_0 * (var_0_10 + arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_11))
			end
		end
	end

	if not arg_2_0.isChanged and arg_2_0.blueSelfHero and arg_2_0.blueSideHero then
		arg_2_0.isChanged = true

		if not arg_2_0.blueSelfHero:isBoss() and not arg_2_0.blueSideHero:isBoss() then
			local var_2_1, var_2_2 = arg_2_0.blueSelfHero:getPos()

			arg_2_0.blueSelfHero:pos(arg_2_0.blueSideHero:getPos())
			arg_2_0.blueSideHero:pos(var_2_1, var_2_2)
		end
	end
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:updateGreenEffect()
end

function var_0_3.updateGreenEffect(arg_4_0)
	if next(arg_4_0.greenEffects) ~= nil then
		for iter_4_0 = #arg_4_0.greenEffects, 1, -1 do
			arg_4_0.greenEffects[iter_4_0].time = arg_4_0.greenEffects[iter_4_0].time - 1

			if arg_4_0.greenEffects[iter_4_0].time == 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_0 = arg_4_0:createAttackUnits(arg_4_0.greenEffects[iter_4_0].targets, var_0_17)

				for iter_4_1, iter_4_2 in ipairs(var_4_0) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_2)
					table.insert(arg_4_0.records_.special_units, iter_4_2)
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_1.target:getTeamType() == arg_5_0:getTeamType() then
		arg_5_0.blueSelfHero = arg_5_1.target
	elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_5_1.target:getTeamType() ~= arg_5_0:getTeamType() then
		arg_5_0.blueSideHero = arg_5_1.target
	elseif arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		local var_5_0 = var_0_8:summonMonster(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		if next(var_5_0) == nil then
			return
		end

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			local var_5_1 = arg_5_0:getSkillLevelByID(arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))
			local var_5_2 = arg_5_0.hero_:getColor()
			local var_5_3 = arg_5_0:getTeamType() == var_0_2.TeamType.A and 0 or var_0_2.STAGE_WIDTH
			local var_5_4 = {
				y = 400,
				x = var_5_3
			}

			arg_5_0:setSummonMonsters(iter_5_1, var_5_1, var_5_2, var_5_4)
		end
	elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_5_5 = arg_5_0:getTargets(var_0_17)
		local var_5_6
		local var_5_7

		for iter_5_2, iter_5_3 in ipairs(var_5_5) do
			if not var_5_6 or var_5_6:getX() < iter_5_3:getX() then
				var_5_6 = iter_5_3
			end

			if not var_5_7 or var_5_7:getX() > iter_5_3:getX() then
				var_5_7 = iter_5_3
			end
		end

		if var_5_6 and var_5_7 then
			local var_5_8 = (var_5_6:getX() + var_5_7:getX()) / 2
			local var_5_9 = {
				time = var_0_16,
				targets = var_5_5
			}
			local var_5_10 = var_0_1.ctx.battle.getSpine(arg_5_1.skillID, "area", 1)

			var_5_10:addTo(var_0_1.ctx.battle.unitBottomLayer)
			var_5_10:pos(var_5_8, arg_5_0:getY())
			var_5_10:playOnce()
			table.insert(arg_5_0.greenEffects, var_5_9)
		end
	end
end

function var_0_3.die(arg_6_0)
	if next(arg_6_0.summonMonsters_) ~= true then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.summonMonsters_) do
			if not iter_6_1:isDeath() then
				iter_6_1:updateHp(0)
				iter_6_1:die()
			end
		end
	end

	var_0_3.super.die(arg_6_0)
end

function var_0_3.setSummonMonsters(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_7_0 = arg_7_0:getSummonMonster()
	else
		local var_7_1 = var_0_4.new()

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
		var_7_0.fighterModel:hideHeaderView()

		var_7_0.fighterIndex = arg_7_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)
	end

	var_7_0:setTeamType(arg_7_0:getTeamType())

	var_7_0.summoner = arg_7_0

	var_7_0.fighterModel:pos(arg_7_4.x, arg_7_4.y)
	var_7_0:getFighterModel():flipX(arg_7_0:getTeamType() == var_0_2.TeamType.B)
	var_7_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_7_0:born()
	var_7_0:setGlobalBuffs()
	var_7_0:updateHp(var_7_0:getHpLimit())
	table.insert(arg_7_0.summonMonsters_, var_7_0)

	local var_7_4 = var_7_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_7_4, var_7_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_7_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.beginAttackEnd(arg_8_0, arg_8_1)
	var_0_3.super.beginAttackEnd(arg_8_0, arg_8_1)

	if var_0_8:father(arg_8_1.rootID_) == arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if arg_8_0.purpleBuffAdd[tostring(var_0_1.ctx.battle.count)] and type(arg_8_0.purpleBuffAdd[tostring(var_0_1.ctx.battle.count)]) == "table" then
				for iter_8_0, iter_8_1 in pairs(arg_8_0.purpleBuffAdd[tostring(var_0_1.ctx.battle.count)]) do
					for iter_8_2, iter_8_3 in ipairs(arg_8_0.sideTeam_) do
						if iter_8_3.fighterIndex == iter_8_0 and not iter_8_3:isDeath() and not iter_8_3:isAffected() and iter_8_1 and next(iter_8_1) then
							for iter_8_4, iter_8_5 in ipairs(iter_8_1) do
								local var_8_0 = var_0_5.new({
									tableID = iter_8_5.buffID,
									start = var_0_1.ctx.battle.count,
									level = iter_8_5.level,
									skillID = iter_8_5.skillID,
									fighter = arg_8_0,
									target = iter_8_3
								})

								iter_8_3:addBuffs({
									var_8_0
								})
							end
						end
					end
				end
			end
		else
			local var_8_1 = {}

			for iter_8_6, iter_8_7 in ipairs(arg_8_0.sideTeam_) do
				if not iter_8_7:isDeath() and not iter_8_7:isAffected() then
					table.insert(var_8_1, iter_8_7)
				end
			end

			if var_8_1 and next(var_8_1) then
				for iter_8_8, iter_8_9 in ipairs(arg_8_0.purpleBuffs) do
					local var_8_2 = var_8_1[math.random(#var_8_1)]

					iter_8_9.fighter = arg_8_0
					iter_8_9.target = var_8_2
					iter_8_9.startCount_ = var_0_1.ctx.battle.count

					var_8_2:addBuffs({
						iter_8_9
					})

					if not arg_8_0.records_.purple_buff_add[tostring(var_0_1.ctx.battle.count)] then
						arg_8_0.records_.purple_buff_add[tostring(var_0_1.ctx.battle.count)] = {}
					end

					if not arg_8_0.records_.purple_buff_add[tostring(var_0_1.ctx.battle.count)][var_8_2.fighterIndex] then
						arg_8_0.records_.purple_buff_add[tostring(var_0_1.ctx.battle.count)][var_8_2.fighterIndex] = {}
					end

					local var_8_3 = {
						buffID = iter_8_9:getTableID(),
						level = iter_8_9:getLevel(),
						skillID = iter_8_9:getSkillID()
					}

					table.insert(arg_8_0.records_.purple_buff_add[tostring(var_0_1.ctx.battle.count)][var_8_2.fighterIndex], var_8_3)
				end

				arg_8_0.purpleBuffs = {}
			end
		end

		arg_8_0.purpleSkillCount = 1
	end
end

function var_0_3.addBuffBySpecialHero(arg_9_0, arg_9_1)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_9_0.purpleSkillCount <= 0 then
		local var_9_0 = false

		for iter_9_0 = #arg_9_1, 1, -1 do
			local var_9_1 = arg_9_1[iter_9_0]

			if var_9_1.fighter.__cname ~= arg_9_0.__cname and var_9_1.target:getTeamType() == arg_9_0:getTeamType() and var_9_1.fighter:getTeamType() ~= arg_9_0:getTeamType() and var_9_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and (var_9_1:isMoveUnable() or var_9_1:getYx() > 0) and var_9_1:canRemove() then
				table.insert(arg_9_0.purpleBuffs, var_9_1)
				table.remove(arg_9_1, iter_9_0)

				if #arg_9_0.purpleBuffs >= var_0_13 then
					var_9_0 = true

					break
				end
			end
		end

		if var_9_0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_9_2 = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_9_3 = var_0_8:sound(var_9_2)

			var_0_1.ctx.battle.pushSoundQueue(var_9_3)

			local var_9_4 = var_0_8:attackIndex(var_9_2)

			arg_9_0:playAttack(var_9_4)

			arg_9_0.unitSkills_ = var_0_7.new({
				fighter = arg_9_0,
				skillID = var_9_2
			})

			arg_9_0:beginAttackEnd(arg_9_0.unitSkills_)
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}
	local var_10_1
	local var_10_2

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.selfTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and not iter_10_1:isHasBuffByID(var_0_12) and (not var_10_1 or var_10_1:getDistance() > iter_10_1:getDistance()) then
			var_10_1 = iter_10_1
		end
	end

	arg_10_0.blueSelfHero = var_10_1

	if var_10_1 then
		table.insert(var_10_0, var_10_1)
	end

	for iter_10_2, iter_10_3 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_3:isDeath() and not iter_10_3:isAffected() and not iter_10_3:isHasBuffByID(var_0_12) and (not var_10_2 or var_10_2:getDistance() < iter_10_3:getDistance()) then
			var_10_2 = iter_10_3
		end
	end

	if var_10_2 then
		table.insert(var_10_0, var_10_2)
	end

	arg_10_0.blueSideHero = var_10_2

	return var_10_0
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.purpleBuffAdd = arg_11_1.purple_buff_add
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.purple_buff_add = arg_12_0.records_.purple_buff_add

	return var_12_0
end

return var_0_3
