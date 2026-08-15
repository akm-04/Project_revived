local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Gaolan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 40011198
local var_0_12 = 10001087
local var_0_13 = {
	40011199,
	40011200,
	40011201,
	40011205
}
local var_0_14 = 10
local var_0_15 = 10001088
local var_0_16 = 40011202
local var_0_17 = 2
local var_0_18 = 10001086
local var_0_19 = 40011205

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.purpleCount = 0
	arg_1_0.isAddPurpleBuff = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_2_0.isAddPurpleBuff then
		arg_2_0.isAddPurpleBuff = true

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if not iter_2_1:isDeath() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_2_0 = arg_2_0:createNewBuffs({
					var_0_16
				}, iter_2_1, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple), arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

				iter_2_1:addBuffs(var_2_0)
			end
		end
	end
end

function var_0_3.die(arg_3_0)
	var_0_3.super.die(arg_3_0)

	if arg_3_0.summonMonsters_ and next(arg_3_0.summonMonsters_) then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.summonMonsters_) do
			if not iter_3_1:isDeath() then
				iter_3_1:updateHp(0)
				iter_3_1:die()
			end
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.selfTeam_) do
		if iter_3_3:isHasBuffByID(var_0_16) then
			iter_3_3:removeBuffByID(var_0_16)
		end
	end
end

function var_0_3.neverDieFeedBack(arg_4_0, arg_4_1)
	arg_4_1:updateHp(1)
	arg_4_1:removeBuffByID(var_0_16)

	arg_4_0.purpleCount = arg_4_0.purpleCount + 1

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_1
		}, var_0_18)

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	if arg_4_0.purpleCount >= var_0_17 then
		for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
			if iter_4_3:isHasBuffByID(var_0_16) then
				iter_4_3:removeBuffByID(var_0_16)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID

	if var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_1 = arg_5_0:selectTargetByTypeD1(arg_5_1.target)

		for iter_5_0, iter_5_1 in pairs(var_5_1) do
			local var_5_2 = arg_5_1.target:getY() - iter_5_1:getY()
			local var_5_3 = var_5_2 - var_5_2 % 10

			iter_5_1:pos(arg_5_1.target:getX(), iter_5_1:getY() + var_5_3)
		end

		local var_5_4 = arg_5_0:createAttackUnits(var_5_1, var_0_15)

		for iter_5_2, iter_5_3 in ipairs(var_5_4) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end
	elseif var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_5_0:isHasBuffByID(var_0_11) then
			arg_5_0:removeBuffByID(var_0_11)
		end

		local var_5_5 = 0

		for iter_5_4, iter_5_5 in pairs(arg_5_0.sideTeam_) do
			if not iter_5_5:isDeath() and arg_5_0:getTeamType() ~= iter_5_5:getTeamType() then
				local var_5_6 = false

				for iter_5_6, iter_5_7 in pairs(var_0_13) do
					if iter_5_5:isHasBuffByID(iter_5_7) then
						var_5_6 = true
					end
				end

				if var_5_6 and var_5_5 < var_0_14 then
					var_5_5 = var_5_5 + 1

					local var_5_7 = arg_5_0:createAttackUnits({
						arg_5_0
					}, var_0_12)

					for iter_5_8, iter_5_9 in ipairs(var_5_7) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_9)
						table.insert(arg_5_0.records_.special_units, iter_5_9)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if var_6_3 > 0 and arg_6_1.skillID == var_0_18 then
		var_6_3 = arg_6_1.target:getHpLimit() * 0.35
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_19 then
		local var_7_0 = var_0_8:summonMonster(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		if next(var_7_0) == nil then
			return
		end

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			local var_7_1 = arg_7_0:getSkillLevelByID(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))
			local var_7_2 = arg_7_0.hero_:getColor()
			local var_7_3 = arg_7_1.target:getX()
			local var_7_4 = var_0_1.ctx.battle.adjustX(var_7_3, arg_7_0)
			local var_7_5 = {
				x = var_7_4,
				y = arg_7_1.target:getY()
			}

			arg_7_0:setSummonMonsters(iter_7_1, var_7_1, var_7_2, var_7_5, arg_7_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_19 and arg_8_0.summonMonsters_ and arg_8_0.summonMonsters_[arg_8_1] and not arg_8_0.summonMonsters_[arg_8_1]:isDeath() then
		arg_8_0.summonMonsters_[arg_8_1]:updateHp(0)
		arg_8_0.summonMonsters_[arg_8_1]:die()
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_6.new()

		var_9_1:populateWithTableID(arg_9_1)

		var_9_1.level_ = arg_9_2 or var_9_1.level_
		var_9_1.color_ = arg_9_3 or var_9_1.color_

		for iter_9_0, iter_9_1 in ipairs(var_9_1.skillLev_) do
			local var_9_2 = var_9_1:getSkillId(iter_9_0)
			local var_9_3 = arg_9_0.hero_:getSkillLevelByID(var_9_2)

			if var_9_3 and var_9_3 > 0 then
				var_9_1.skillLev_[iter_9_0] = var_9_3
			end
		end

		local var_9_4 = var_9_1:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_4).new({
			is_arena = arg_9_0.isInArena_
		})

		var_9_0:populateWithHero(var_9_1)
		var_9_0:initModels()
		var_9_0.fighterModel:initHeaderView(arg_9_0:getTeamType() - 1)

		var_9_0.fighterIndex = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0:setFormationDelay(0, 100)
	end

	var_9_0:setTeamType(arg_9_0:getTeamType())

	var_9_0.summoner = arg_9_0

	var_9_0.fighterModel:pos(arg_9_4.x, arg_9_4.y)
	var_9_0:updateHp(var_9_0:getHpLimit())
	var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
	var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_9_0:born()
	var_9_0:setGlobalBuffs()

	local var_9_5 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_9_5, var_9_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()

	arg_9_0.summonMonsters_[arg_9_5] = var_9_0
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1)
	local var_10_0 = {}
	local var_10_1 = var_0_8:scope(var_0_15) / 2

	if not arg_10_1 then
		return {}
	end

	x1, y1 = arg_10_1.fighterModel:getPosition()

	table.insert(var_10_0, arg_10_1)

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		local var_10_2, var_10_3 = iter_10_1.fighterModel:getPosition()

		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and var_10_1 >= math.abs(x1 - var_10_2) and iter_10_1 ~= arg_10_1 then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

return var_0_3
