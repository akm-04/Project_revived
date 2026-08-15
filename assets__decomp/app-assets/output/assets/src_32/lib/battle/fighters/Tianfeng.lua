local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Tianfeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = 60
local var_0_9 = 100
local var_0_10 = 100
local var_0_11 = 80010088
local var_0_12 = 40011382
local var_0_13 = 80020088
local var_0_14 = var_0_2.tables.elementEquip
local var_0_15 = 20001495
local var_0_16 = 10002394
local var_0_17 = 40012606
local var_0_18 = 0.05
local var_0_19 = 10000342
local var_0_20 = 10000343
local var_0_21 = 10000346

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.canMake = true
	arg_1_0.doShanbi = true
	arg_1_0.littleMushroom = {}
	arg_1_0.hugeMushroom = {}
end

function var_0_3.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5, arg_2_6, arg_2_7)
	local var_2_6 = arg_2_1.fighter
	local var_2_7 = arg_2_1.target

	if arg_2_0.skinSkillID_ == var_0_13 and (arg_2_1.skillID == var_0_19 or arg_2_1.skillID == var_0_20 or arg_2_1.skillID == var_0_21) and var_2_6:getTeamType() == arg_2_0:getTeamType() then
		local var_2_8 = arg_2_0:createAttackUnits({
			arg_2_1.target
		}, var_0_13)

		for iter_2_0, iter_2_1 in ipairs(var_2_8) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
			table.insert(arg_2_0.records_.special_units, iter_2_1)
		end
	end

	return var_2_0, var_2_1, var_2_2, var_2_3, var_2_4, var_2_5
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_16 and arg_3_5 > 0 then
		arg_3_5 = arg_3_5 + arg_3_0:getHpLimit() * var_0_18
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.die(arg_4_0)
	if (not arg_4_0.isSkinSkillOn_ or arg_4_0.skinSkillID_ ~= var_0_11) and next(arg_4_0.summonMonsters_) ~= true then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.summonMonsters_) do
			if not iter_4_1:isDeath() then
				iter_4_1:updateHp(0)
				iter_4_1:die()
			end
		end
	end

	var_0_3.super.die(arg_4_0)

	if arg_4_0.killer_ and arg_4_0.killer_:getTeamType() ~= arg_4_0:getTeamType() and arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_11 then
		local var_4_0 = var_0_5.new({
			tableID = var_0_12,
			start = var_0_1.ctx.battle.count,
			level = arg_4_0:getSkillLevelByID(var_0_11),
			skillID = var_0_11,
			fighter = arg_4_0,
			target = arg_4_0.killer_
		})

		arg_4_0.killer_:addBuffs({
			var_4_0
		})
	end
end

function var_0_3.singleLoop(arg_5_0)
	var_0_3.super.singleLoop(arg_5_0)

	if arg_5_0:acttionInBlack() and not arg_5_0:isDeath() then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.summonMonsters_) do
			if iter_5_1:isDeath() then
				table.remove(arg_5_0.summonMonsters_, iter_5_0)
			end
		end
	end

	if arg_5_0:acttionInBlack() and not arg_5_0:isDeath() then
		for iter_5_2, iter_5_3 in ipairs(arg_5_0.littleMushroom) do
			if iter_5_3:isDeath() then
				arg_5_0:setSpeedBuff(1)
				table.remove(arg_5_0.littleMushroom, iter_5_2)
			end
		end
	end

	if arg_5_0:acttionInBlack() and not arg_5_0:isDeath() then
		for iter_5_4, iter_5_5 in ipairs(arg_5_0.hugeMushroom) do
			if iter_5_5:isDeath() then
				arg_5_0:setSpeedBuff(3)
				table.remove(arg_5_0.hugeMushroom, iter_5_4)
			end
		end
	end

	if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_11 then
		if arg_5_0:acttionInBlack() then
			for iter_5_6, iter_5_7 in ipairs(arg_5_0.summonMonsters_) do
				if iter_5_7:isDeath() then
					table.remove(arg_5_0.summonMonsters_, iter_5_6)
				end
			end
		end

		if arg_5_0:acttionInBlack() then
			for iter_5_8, iter_5_9 in ipairs(arg_5_0.littleMushroom) do
				if iter_5_9:isDeath() then
					table.remove(arg_5_0.littleMushroom, iter_5_8)
				end
			end
		end
	end
end

function var_0_3.setSpeedBuff(arg_6_0, arg_6_1)
	for iter_6_0 = 1, arg_6_1 do
		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_6_1 = {
				arg_6_0
			}
			local var_6_2 = arg_6_0:createAttackUnits(var_6_1, var_6_0)

			for iter_6_1, iter_6_2 in ipairs(var_6_2) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_2)
				table.insert(arg_6_0.records_.special_units, iter_6_2)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {}

	if arg_7_2 and arg_7_2.manualTargets_ then
		return arg_7_2.manualTargets_
	end

	local var_7_1 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.sideTeam_) do
		if not iter_7_1:isDeath() and iter_7_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_7_2, var_7_3 = iter_7_1.fighterModel:getPosition()

			table.insert(var_7_1, iter_7_1)
		end
	end

	if #var_7_1 == 0 then
		return var_7_0
	end

	if arg_7_0:getTeamType() == var_0_2.TeamType.A then
		table.sort(var_7_1, function(arg_8_0, arg_8_1)
			return arg_8_0.fighterModel:getPosition() < arg_8_1.fighterModel:getPosition()
		end)
	else
		table.sort(var_7_1, function(arg_9_0, arg_9_1)
			return arg_9_0.fighterModel:getPosition() > arg_9_1.fighterModel:getPosition()
		end)
	end

	if #var_7_1 <= 3 then
		var_7_0 = {
			var_7_1[1]
		}
	else
		var_7_0 = {
			var_7_1[2]
		}
	end

	return var_7_0
end

function var_0_3.selectTargetByTypeD2(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	if arg_10_2 and arg_10_2.manualTargets_ then
		return arg_10_2.manualTargets_
	end

	local var_10_1 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_10_2, var_10_3 = iter_10_1.fighterModel:getPosition()

			table.insert(var_10_1, iter_10_1)
		end
	end

	if #var_10_1 == 0 then
		return var_10_0
	end

	if arg_10_0:getTeamType() == var_0_2.TeamType.A then
		table.sort(var_10_1, function(arg_11_0, arg_11_1)
			return arg_11_0.fighterModel:getPosition() < arg_11_1.fighterModel:getPosition()
		end)
	else
		table.sort(var_10_1, function(arg_12_0, arg_12_1)
			return arg_12_0.fighterModel:getPosition() > arg_12_1.fighterModel:getPosition()
		end)
	end

	local var_10_4
	local var_10_5

	if #var_10_1 <= 3 then
		local var_10_6

		var_10_4, var_10_6 = var_10_1[1].fighterModel:getPosition()
	else
		local var_10_7

		var_10_4, var_10_7 = var_10_1[2].fighterModel:getPosition()
	end

	for iter_10_2, iter_10_3 in ipairs(var_10_1) do
		local var_10_8, var_10_9 = iter_10_3.fighterModel:getPosition()

		if arg_10_0:getFlipX() == false and arg_10_0:getTeamType() == var_0_2.TeamType.A or arg_10_0:getFlipX() == true and arg_10_0:getTeamType() == var_0_2.TeamType.B then
			if var_10_8 > var_10_4 - var_0_6:scope(arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) / 2 + var_0_9 and var_10_8 < var_10_4 + var_0_9 then
				table.insert(var_10_0, iter_10_3)
			end
		elseif var_10_8 < var_0_6:scope(arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) / 2 + var_10_4 + var_0_9 and var_10_8 >= var_10_4 + var_0_9 then
			table.insert(var_10_0, iter_10_3)
		end
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD3(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}

	if arg_13_2 and arg_13_2.manualTargets_ then
		return arg_13_2.manualTargets_
	end

	local var_13_1 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_13_2, var_13_3 = iter_13_1.fighterModel:getPosition()

			table.insert(var_13_1, iter_13_1)
		end
	end

	if #var_13_1 == 0 then
		return var_13_0
	end

	if arg_13_0:getTeamType() == var_0_2.TeamType.A then
		table.sort(var_13_1, function(arg_14_0, arg_14_1)
			return arg_14_0.fighterModel:getPosition() < arg_14_1.fighterModel:getPosition()
		end)
	else
		table.sort(var_13_1, function(arg_15_0, arg_15_1)
			return arg_15_0.fighterModel:getPosition() > arg_15_1.fighterModel:getPosition()
		end)
	end

	local var_13_4
	local var_13_5

	if #var_13_1 <= 3 then
		local var_13_6

		var_13_4, var_13_6 = var_13_1[1].fighterModel:getPosition()
	else
		local var_13_7

		var_13_4, var_13_7 = var_13_1[2].fighterModel:getPosition()
	end

	for iter_13_2, iter_13_3 in ipairs(var_13_1) do
		local var_13_8, var_13_9 = iter_13_3.fighterModel:getPosition()

		if arg_13_0:getFlipX() == false and arg_13_0:getTeamType() == var_0_2.TeamType.A or arg_13_0:getFlipX() == true and arg_13_0:getTeamType() == var_0_2.TeamType.B then
			if var_13_8 < var_0_6:scope(arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) / 2 + var_13_4 + var_0_9 and var_13_8 >= var_13_4 + var_0_9 then
				table.insert(var_13_0, iter_13_3)
			end
		elseif var_13_8 > var_13_4 - var_0_6:scope(arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy)) / 2 + var_0_9 and var_13_8 < var_13_4 + var_0_9 then
			table.insert(var_13_0, iter_13_3)
		end
	end

	return var_13_0
end

function var_0_3.moveUnitArrive(arg_16_0, arg_16_1)
	var_0_3.super.moveUnitArrive(arg_16_0, arg_16_1)

	local var_16_0 = arg_16_1.skillID
	local var_16_1 = var_0_6:summonMonster(var_16_0)

	if next(var_16_1) == nil then
		return
	end

	local var_16_2 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.sideTeam_) do
		if not iter_16_1:isDeath() and iter_16_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_16_3, var_16_4 = iter_16_1.fighterModel:getPosition()

			table.insert(var_16_2, iter_16_1)
		end
	end

	if #var_16_2 == 0 then
		return
	end

	if arg_16_0:getTeamType() == var_0_2.TeamType.A then
		table.sort(var_16_2, function(arg_17_0, arg_17_1)
			return arg_17_0.fighterModel:getPosition() < arg_17_1.fighterModel:getPosition()
		end)
	else
		table.sort(var_16_2, function(arg_18_0, arg_18_1)
			return arg_18_0.fighterModel:getPosition() > arg_18_1.fighterModel:getPosition()
		end)
	end

	local var_16_5
	local var_16_6

	if #var_16_2 <= 3 then
		local var_16_7

		var_16_5, var_16_7 = var_16_2[1].fighterModel:getPosition()
	else
		local var_16_8

		var_16_5, var_16_8 = var_16_2[2].fighterModel:getPosition()
	end

	for iter_16_2, iter_16_3 in ipairs(var_16_1) do
		local var_16_9 = arg_16_0:getSkillLevelByID(arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))
		local var_16_10 = arg_16_0.hero_:getColor()
		local var_16_11 = {}

		if arg_16_0:getFlipX() then
			var_16_11 = {
				x = arg_16_1.desX_ - var_0_9,
				y = arg_16_1.desY_
			}
		end

		if var_16_0 ~= arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_16_0 ~= arg_16_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
			if arg_16_0:getTeamType() == var_0_2.TeamType.A then
				var_16_11 = {
					x = var_16_5 + var_0_9,
					y = arg_16_1.desY_
				}
			else
				var_16_11 = {
					x = var_16_5 - var_0_9,
					y = arg_16_1.desY_
				}
			end
		elseif arg_16_0:getFlipX() then
			var_16_11 = {
				x = arg_16_1.desX_,
				y = arg_16_1.desY_
			}
		else
			var_16_11 = {
				x = arg_16_1.desX_,
				y = arg_16_1.desY_
			}
		end

		arg_16_0:setSummonMonsters(iter_16_3, var_16_9, var_16_10, var_16_11, var_16_0)
	end
end

function var_0_3.setSummonMonsters(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4, arg_19_5)
	if #arg_19_0.summonMonsters_ >= var_0_8 then
		return
	end

	local var_19_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_19_0 = arg_19_0:getSummonMonster()
	else
		local var_19_1 = var_0_7.new()

		var_19_1:populateWithTableID(arg_19_1)

		var_19_1.level_ = arg_19_2 or var_19_1.level_
		var_19_1.color_ = arg_19_3 or var_19_1.color_

		for iter_19_0, iter_19_1 in ipairs(var_19_1.skillLev_) do
			local var_19_2 = arg_19_0.hero_:getSkillLevel(iter_19_0)

			if var_19_2 and var_19_2 > 0 then
				var_19_1.skillLev_[iter_19_0] = var_0_0.clone(var_19_2)
			end
		end

		local var_19_3 = var_19_1:className()

		var_19_0 = var_0_1.ctx.battle.requireFighter(var_19_3).new({
			is_arena = arg_19_0.isInArena_
		})

		var_19_0:populateWithHero(var_19_1)
		var_19_0:initModels()
		var_19_0.fighterModel:initHeaderView(arg_19_0:getTeamType() - 1)

		var_19_0.fighterIndex = arg_19_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_19_0:setFormationDelay(0, 100)
	end

	var_19_0:setTeamType(arg_19_0:getTeamType())

	var_19_0.summoner = arg_19_0

	var_19_0.fighterModel:pos(arg_19_4.x, arg_19_4.y)
	var_19_0:updateHp(var_19_0:getHpLimit())
	var_19_0:getFighterModel():flipX(arg_19_0:getTeamType() == var_0_2.TeamType.B)
	var_19_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_19_0:born()
	var_19_0:setGlobalBuffs()

	local var_19_4 = var_19_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_19_4, var_19_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_19_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_19_0.summonMonsters_, var_19_0)

	if arg_19_0:hasElementEquipByID(var_0_15) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_19_5 = arg_19_0:createAttackUnits({
				arg_19_0
			}, var_0_16)

			for iter_19_2, iter_19_3 in ipairs(var_19_5) do
				table.insert(arg_19_0.moveAttackUnits_, iter_19_3)
				table.insert(arg_19_0.records_.special_units, iter_19_3)
			end
		end

		local var_19_6 = var_0_15
		local var_19_7 = var_0_14:battleAttr(var_19_6, arg_19_0:getElementEquipLevelByID(var_19_6))
		local var_19_8 = arg_19_0.hero_:getElementEquipActiveRate(var_19_6)
		local var_19_9 = arg_19_0:createNewBuffs({
			var_0_17
		}, arg_19_0, var_0_16)

		for iter_19_4, iter_19_5 in ipairs(var_19_9) do
			iter_19_5.manualRevise = var_19_7 * var_19_8
		end

		arg_19_0:addBuffs(var_19_9)
	end

	if arg_19_5 == arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) or arg_19_5 == arg_19_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_19_10 = arg_19_0.fighterModel:getPosition()
		local var_19_11 = arg_19_0.fighterModel:getPosition()

		if #arg_19_0.littleMushroom > 0 then
			for iter_19_6, iter_19_7 in ipairs(arg_19_0.littleMushroom) do
				if var_19_11 < iter_19_7.posX_ then
					var_19_11 = iter_19_7.posX_
				end

				if var_19_10 > iter_19_7.posX_ then
					var_19_10 = iter_19_7.posX_
				end
			end

			local var_19_12 = {}
			local var_19_13 = arg_19_0.littleMushroom

			table.sort(var_19_13, function(arg_20_0, arg_20_1)
				return arg_20_0.posX_ < arg_20_1.posX_
			end)

			for iter_19_8, iter_19_9 in ipairs(var_19_13) do
				if arg_19_0.fighterModel:getPosition() < iter_19_9.posX_ then
					if iter_19_8 == 1 then
						var_19_10 = arg_19_0.fighterModel:getPosition()

						if arg_19_0.fighterModel:getPosition() + var_0_10 < var_19_13[1].posX_ then
							var_19_11 = arg_19_0.fighterModel:getPosition()

							break
						end

						var_19_11 = var_19_13[#var_19_13].posX_

						for iter_19_10 = 2, #var_19_13 do
							if var_19_13[iter_19_10].posX_ - var_19_13[iter_19_10 - 1].posX_ > var_0_10 then
								var_19_11 = var_19_13[iter_19_10 - 1].posX_

								break
							end
						end

						break
					end

					for iter_19_11 = iter_19_8 - 1, 1, -1 do
						if arg_19_0.fighterModel:getPosition() - var_19_13[iter_19_8 - 1].posX_ > var_0_10 then
							var_19_10 = arg_19_0.fighterModel:getPosition()

							break
						else
							var_19_10 = var_19_13[1].posX_

							if iter_19_11 > 1 and var_19_13[iter_19_11].posX_ - var_19_13[iter_19_11 - 1].posX_ > var_0_10 then
								var_19_10 = var_19_13[iter_19_11].posX_

								break
							end
						end
					end

					for iter_19_12 = iter_19_8, #var_19_13 do
						if var_19_13[iter_19_8].posX_ - arg_19_0.fighterModel:getPosition() > var_0_10 then
							var_19_11 = arg_19_0.fighterModel:getPosition()

							break
						else
							var_19_11 = var_19_13[#var_19_13].posX_

							if iter_19_12 < #var_19_13 and var_19_13[iter_19_12 + 1].posX_ - var_19_13[iter_19_12].posX_ > var_0_10 then
								var_19_11 = var_19_13[iter_19_12].posX_

								break
							end
						end
					end

					break
				end

				if iter_19_8 == #var_19_13 then
					var_19_11 = arg_19_0.fighterModel:getPosition()

					if arg_19_0.fighterModel:getPosition() - var_0_10 > var_19_13[#var_19_13].posX_ then
						var_19_10 = arg_19_0.fighterModel:getPosition()
					else
						var_19_10 = var_19_13[1].posX_

						for iter_19_13 = #var_19_13, 2, -1 do
							if var_19_13[iter_19_13].posX_ - var_19_13[iter_19_13 - 1].posX_ > var_0_10 then
								var_19_10 = var_19_13[iter_19_13].posX_

								break
							end
						end
					end
				end
			end

			if var_19_11 < arg_19_0.fighterModel:getPosition() then
				var_19_11 = arg_19_0.fighterModel:getPosition() + var_0_10
			else
				var_19_11 = var_19_11 + var_0_10

				if var_0_1.ctx.battle.isUnlimitBattle then
					if var_19_11 > var_0_2.UNLIMIT_STAGE_WIDTH then
						var_19_11 = var_0_2.UNLIMIT_STAGE_WIDTH
					end
				elseif var_19_11 > var_0_2.STAGE_WIDTH then
					var_19_11 = var_0_2.STAGE_WIDTH
				end
			end

			if var_19_10 > arg_19_0.fighterModel:getPosition() then
				var_19_10 = arg_19_0.fighterModel:getPosition() - var_0_10
			else
				var_19_10 = var_19_10 - var_0_10

				if var_19_10 < 0 then
					var_19_10 = 0
				end
			end
		end

		if arg_19_0:getFlipX() then
			var_19_0:flipX(true)

			var_19_0.walk2Position_ = true

			var_19_0:setFormationDelay(0, var_19_10)

			if arg_19_0:getTeamType() == var_0_2.TeamType.B then
				if var_0_1.ctx.battle.isUnlimitBattle then
					var_19_0:setFormationDelay(0, var_0_2.UNLIMIT_STAGE_WIDTH - var_19_10)
				else
					var_19_0:setFormationDelay(0, var_0_2.STAGE_WIDTH - var_19_10)
				end
			end

			var_19_0.posX_ = var_19_10
		else
			var_19_0:flipX(false)

			var_19_0.walk2Position_ = true

			var_19_0:setFormationDelay(0, var_19_11)

			if arg_19_0:getTeamType() == var_0_2.TeamType.B then
				if var_0_1.ctx.battle.isUnlimitBattle then
					var_19_0:setFormationDelay(0, var_0_2.UNLIMIT_STAGE_WIDTH - var_19_11)
				else
					var_19_0:setFormationDelay(0, var_0_2.STAGE_WIDTH - var_19_11)
				end
			end

			var_19_0.posX_ = var_19_11
		end

		table.insert(arg_19_0.littleMushroom, var_19_0)
	else
		table.insert(arg_19_0.hugeMushroom, var_19_0)
	end
end

return var_0_3
