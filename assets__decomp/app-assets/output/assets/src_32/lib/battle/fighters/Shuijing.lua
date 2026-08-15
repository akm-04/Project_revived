local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shuijing", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 50010084
local var_0_8 = 80010084
local var_0_9 = 20

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("born_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.harmExtra_ = nil
	arg_2_0.summonMonsters_ = {}
	arg_2_0.nDarkElements = 0
end

function var_0_3.forceDie(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
		if not iter_3_1:isDeath() then
			iter_3_1:updateHp(0)
			iter_3_1:forceDie()
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_8 then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_0.nearestTarget_
		}, var_0_7)

		for iter_3_2, iter_3_3 in ipairs(var_3_0) do
			table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
			table.insert(arg_3_0.records_.special_units, iter_3_3)
		end
	end

	var_0_3.super.forceDie(arg_3_0)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(var_0_1.ctx.battle.infoList.born_info) do
		if iter_4_1:getTeamType() == arg_4_0:getTeamType() then
			if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and (iter_4_1:getSummonType() == var_0_2.summonMonsterType.Monster or iter_4_1:getSummonType() == var_0_2.summonMonsterType.Copy) then
				local var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
				local var_4_1 = var_0_6:scope(var_4_0)
				local var_4_2 = var_0_5.B7(arg_4_0, var_4_0)
				local var_4_3 = arg_4_0:createAttackUnits(var_4_2, var_4_0)

				for iter_4_2, iter_4_3 in ipairs(var_4_3) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
					table.insert(arg_4_0.records_.special_units, iter_4_3)
				end

				arg_4_0.harmExtra_ = iter_4_1:getHpLimit() / 6
			end

			if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_8 and iter_4_1:getSummonType() == var_0_2.summonMonsterType.Monster then
				arg_4_0.nDarkElements = math.min(var_0_9, arg_4_0.nDarkElements + 1)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID
	local var_5_1 = var_0_6:summonMonster(var_5_0)

	if next(var_5_1) == nil then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(var_5_1) do
		local var_5_2 = arg_5_0:getSkillLevelByID(var_5_0)
		local var_5_3 = arg_5_0.hero_:getColor()
		local var_5_4 = arg_5_1.target:getX()
		local var_5_5 = arg_5_1.target:getY()
		local var_5_6

		if arg_5_0 == arg_5_1.target then
			var_5_4 = arg_5_0:getFlipX() and var_5_4 - 150 or var_5_4 + 150
		else
			var_5_5 = var_5_5 + 50
			var_5_6 = true
		end

		local var_5_7 = var_0_1.ctx.battle.adjustX(var_5_4, arg_5_0)
		local var_5_8 = {
			x = var_5_7,
			y = var_5_5
		}

		arg_5_0:setSummonMonsters(iter_5_1, var_5_2, var_5_3, var_5_8, var_5_6)
	end
end

function var_0_3.setSummonMonsters(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	local var_6_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_6_0 = arg_6_0:getSummonMonster()
	else
		local var_6_1 = var_0_4.new()

		var_6_1:populateWithTableID(arg_6_1)

		var_6_1.level_ = arg_6_2 or var_6_1.level_
		var_6_1.color_ = arg_6_3 or var_6_1.color_

		for iter_6_0, iter_6_1 in pairs(var_6_1.skillLev_) do
			var_6_1.skillLev_[iter_6_0] = arg_6_0.hero_.skillLev_[iter_6_0]
		end

		local var_6_2 = var_6_1:className()

		var_6_0 = var_0_1.ctx.battle.requireFighter(var_6_2).new({
			is_arena = arg_6_0.isInArena_
		})

		var_6_0:populateWithHero(var_6_1)
		var_6_0:initModels()
		var_6_0.fighterModel:initHeaderView(arg_6_0:getTeamType() - 1)

		var_6_0.fighterIndex = arg_6_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_6_0:setFormationDelay(0, 100)
	end

	var_6_0:setTeamType(arg_6_0:getTeamType())

	var_6_0.summoner = arg_6_0

	var_6_0.fighterModel:pos(arg_6_4.x, arg_6_4.y - #arg_6_0.summonMonsters_)
	var_6_0:updateHp(var_6_0:getHpLimit())
	var_6_0:getFighterModel():flipX(arg_6_0:getTeamType() == var_0_2.TeamType.B)
	var_6_0:born()
	var_6_0:setGlobalBuffs()

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:isDeath() and arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_8 then
		var_6_0:resetHpLimit(var_6_0:getHpLimit() * (1 + arg_6_0.nDarkElements / 3))

		if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			local var_6_3 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_6_4 = var_0_6:scope(var_6_3)
			local var_6_5 = var_0_5.B7(arg_6_0, var_6_3)
			local var_6_6 = arg_6_0:createAttackUnits(var_6_5, var_6_3)

			for iter_6_2, iter_6_3 in ipairs(var_6_6) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end

			arg_6_0.harmExtra_ = var_6_0:getHpLimit() / 6
		end
	end

	local var_6_7 = var_6_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_6_7, var_6_0)

	if not arg_6_5 then
		var_6_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
		table.insert(var_0_1.ctx.battle.yOrder, var_6_0)
		var_0_1.ctx.battle.updateZorder()
	else
		var_6_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer, 100)
	end

	table.insert(arg_6_0.summonMonsters_, var_6_0)
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and var_7_2 > 0 and arg_7_0.harmExtra_ then
		var_7_2 = var_7_2 + math.min(5 * var_7_2, arg_7_0.harmExtra_)
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

return var_0_3
