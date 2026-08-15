local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yangfeng", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 10001134
local var_0_12 = 10001135
local var_0_13 = 10
local var_0_14 = 10001133
local var_0_15 = 10
local var_0_16 = 6

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.purpleCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1:getSummonType() == var_0_2.summonMonsterType.None and arg_2_0.purpleCount[iter_2_1] and arg_2_0.purpleCount[iter_2_1] >= var_0_13 then
				local var_2_0 = arg_2_0:createAttackUnits({
					iter_2_1
				}, var_0_14)

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end

				arg_2_0.purpleCount[iter_2_1] = 0
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID

	if var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if var_0_2.weightedChoise({
			0.5,
			0.5
		}) == 1 then
			local var_3_1 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_11)

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
				table.insert(arg_3_0.records_.special_units, iter_3_1)
			end
		else
			local var_3_2 = arg_3_0:createAttackUnits({
				arg_3_1.target
			}, var_0_12)

			for iter_3_2, iter_3_3 in ipairs(var_3_2) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
				table.insert(arg_3_0.records_.special_units, iter_3_3)
			end
		end
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_3 = var_0_8:summonMonster(var_3_0)

		if next(var_3_3) == nil then
			return
		end

		for iter_3_4, iter_3_5 in ipairs(var_3_3) do
			local var_3_4 = arg_3_0:getSkillLevelByID(var_3_0)
			local var_3_5 = arg_3_0.hero_:getColor()
			local var_3_6 = arg_3_1.target:getX()
			local var_3_7 = var_0_1.ctx.battle.adjustX(var_3_6, arg_3_0)
			local var_3_8 = {
				x = var_3_7,
				y = arg_3_1.target:getY()
			}

			arg_3_0:setSummonMonsters(iter_3_5, var_3_4, var_3_5, var_3_8)
		end

		arg_3_1.target:x(arg_3_0:getX() + (arg_3_0:getFlipX() and -1 or 1) * 50)
		arg_3_1.target:y(arg_3_0:getY())
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if var_4_2 > 0 and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if not arg_4_0.purpleCount[arg_4_1.target] then
			arg_4_0.purpleCount[arg_4_1.target] = 0
		end

		arg_4_0.purpleCount[arg_4_1.target] = arg_4_0.purpleCount[arg_4_1.target] + 1
		var_4_2 = var_4_2 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_16 + var_0_15
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_0 = arg_5_0:getSummonMonster()
	else
		local var_5_1 = var_0_6.new()

		var_5_1:populateWithTableID(arg_5_1)

		var_5_1.level_ = arg_5_2 or var_5_1.level_
		var_5_1.color_ = arg_5_3 or var_5_1.color_

		for iter_5_0, iter_5_1 in ipairs(var_5_1.skillLev_) do
			local var_5_2 = var_5_1:getSkillId(iter_5_0)
			local var_5_3 = arg_5_0.hero_:getSkillLevelByID(var_5_2)

			if var_5_3 and var_5_3 > 0 then
				var_5_1.skillLev_[iter_5_0] = var_5_3
			end
		end

		local var_5_4 = var_5_1:className()

		var_5_0 = var_0_1.ctx.battle.requireFighter(var_5_4).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_0:populateWithHero(var_5_1)
		var_5_0:initModels()
		var_5_0.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_0.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0:setFormationDelay(0, 100)
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_5_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_5_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_5_0:setTeamType(arg_5_0:getTeamType())

	var_5_0.summoner = arg_5_0

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y)
	var_5_0:updateHp(var_5_0:getHpLimit())
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()

	local var_5_5 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_5, var_5_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_5_0.summonMonsters_, var_5_0)
end

return var_0_3
