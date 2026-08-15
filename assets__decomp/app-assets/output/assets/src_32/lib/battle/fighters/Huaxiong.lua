local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huaxiong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 20010231
local var_0_8 = 300

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.bubbles = {}
	arg_2_0.blueBubbles = {}
	arg_2_0.summonMonsters_ = {}
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 then
		arg_3_0.GreenSkill = 10001972
		arg_3_0.BlueSkill = 10001970
	else
		arg_3_0.GreenSkill = 10000337
		arg_3_0.BlueSkill = 10000338
	end
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)
	arg_4_0:updateSkill()
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	if var_0_0.table.keyof(arg_5_0.summonMonsters_, arg_5_1) then
		arg_5_0:createBubble(arg_5_1:getX(), arg_5_1:getY())
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 then
		return
	end

	for iter_6_0, iter_6_1 in ipairs(var_0_1.ctx.battle.infoList.buff_info) do
		if iter_6_1:getType() == var_0_2.BuffType.CONTINUE_HARM and iter_6_1:getHarm() > 0 and not iter_6_1.target:isDeath() then
			local var_6_0 = var_0_5.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
				skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_6_0,
				target = iter_6_1.target
			})

			var_6_0:setDirection(iter_6_1.target:getFlipX())

			var_6_0.leftCount_ = iter_6_1.leftCount_

			iter_6_1.target:addBuffs({
				var_6_0
			})
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_7_0)
	if var_0_3.super.getFrontSkill(arg_7_0) == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and next(arg_7_0.bubbles) == nil then
		return arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_7_0)
end

function var_0_3.setSummonMonsters(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_0 = arg_8_0:getSummonMonster()
	else
		local var_8_1 = var_0_4.new()

		var_8_1:populateWithTableID(arg_8_1)

		var_8_1.level_ = arg_8_2 or var_8_1.level_
		var_8_1.color_ = arg_8_3 or var_8_1.color_

		for iter_8_0, iter_8_1 in pairs(var_8_1.skillLev_) do
			var_8_1.skillLev_[iter_8_0] = arg_8_0.hero_.skillLev_[iter_8_0]
		end

		local var_8_2 = var_8_1:className()

		var_8_0 = var_0_1.ctx.battle.requireFighter(var_8_2).new({
			is_arena = arg_8_0.isInArena_
		})

		var_8_0:populateWithHero(var_8_1)
		var_8_0:initModels()
		var_8_0.fighterModel:initHeaderView(arg_8_0:getTeamType() - 1)

		var_8_0.fighterIndex = arg_8_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_8_0:setFormationDelay(0, 100)
	end

	var_8_0:setTeamType(arg_8_0:getTeamType())

	var_8_0.summoner = arg_8_0

	var_8_0.fighterModel:pos(arg_8_4.x, arg_8_4.y - #arg_8_0.summonMonsters_)
	var_8_0:updateHp(var_8_0:getHpLimit())
	var_8_0:getFighterModel():flipX(arg_8_0:getTeamType() == var_0_2.TeamType.B)
	var_8_0:born()
	var_8_0:setGlobalBuffs()

	local var_8_3 = var_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_8_3, var_8_0)
	var_8_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	table.insert(var_0_1.ctx.battle.yOrder, var_8_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_8_0.summonMonsters_, var_8_0)
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.skillID

	if var_9_0 == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0.bubbles) do
			arg_9_0:createBlueBubble(iter_9_0)
		end
	end

	local var_9_1 = var_0_6:summonMonster(var_9_0)

	if next(var_9_1) == nil then
		return
	end

	for iter_9_2, iter_9_3 in ipairs(var_9_1) do
		local var_9_2 = arg_9_0:getSkillLevelByID(var_9_0)
		local var_9_3 = arg_9_0.hero_:getColor()
		local var_9_4 = arg_9_1.target:getX()
		local var_9_5 = arg_9_1.target:getY()
		local var_9_6

		var_9_4 = var_9_4 > arg_9_0:getX() and var_9_4 - 50 or var_9_4 + 150

		local var_9_7 = var_9_5 - 50
		local var_9_8 = var_0_1.ctx.battle.adjustX(var_9_4, arg_9_0)
		local var_9_9 = {
			x = var_9_8,
			y = var_9_7
		}

		arg_9_0:setSummonMonsters(iter_9_3, var_9_2, var_9_3, var_9_9)
	end
end

function var_0_3.createBubble(arg_10_0, arg_10_1, arg_10_2)
	for iter_10_0, iter_10_1 in ipairs(arg_10_0.bubbles) do
		if math.abs(iter_10_1.x - arg_10_1) < 100 then
			arg_10_0.bubbles[iter_10_0].rate = arg_10_0.bubbles[iter_10_0].rate + 0.5

			return
		end
	end

	local var_10_0 = {
		rate = 1,
		x = arg_10_1,
		y = arg_10_2
	}

	table.insert(arg_10_0.bubbles, var_10_0)

	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_10_1 = arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_10_2, var_10_3 = var_0_6:areaResource(var_10_1)

	if var_10_2 and var_10_2 ~= "" and var_10_3 and var_10_3 ~= "" then
		local var_10_4 = var_0_1.ctx.battle.getSpine(var_10_1, "area", arg_10_0:getScale())

		var_10_0.effect = var_10_4

		var_10_4:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_10_4:pos(arg_10_1, arg_10_2)
		var_10_4:playRepeat()
		var_10_4:flipX(arg_10_1 < arg_10_0:getX())
	end
end

function var_0_3.createBlueBubble(arg_11_0, arg_11_1, arg_11_2)
	local function var_11_0(arg_12_0)
		if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
			return
		end

		local var_12_0 = arg_11_0.bubbles[arg_12_0].x
		local var_12_1 = arg_11_0.bubbles[arg_12_0].y
		local var_12_2 = arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_12_3, var_12_4 = var_0_6:areaResource(var_12_2)

		if var_12_3 and var_12_3 ~= "" and var_12_4 and var_12_4 ~= "" then
			local var_12_5 = var_0_1.ctx.battle.getSpine(var_12_2, "area", arg_11_0:getScale())

			var_12_5:addTo(var_0_1.ctx.battle.unitLayer)
			var_12_5:pos(var_12_0, var_12_1)
			var_12_5:playRepeat()
			var_12_5:flipX(arg_11_0.bubbles[arg_12_0].effect:getFlipX())

			arg_11_0.bubbles[arg_12_0].blueEffect = var_12_5
		end
	end

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.bubbles) do
		arg_11_0.blueBubbles[iter_11_0] = var_0_8

		if not arg_11_0.bubbles[iter_11_0].blueEffect or tolua.isnull(arg_11_0.bubbles[iter_11_0].blueEffect) then
			var_11_0(iter_11_0)
		end
	end
end

function var_0_3.updateSkill(arg_13_0)
	local function var_13_0(arg_14_0, arg_14_1)
		local var_14_0 = {}
		local var_14_1 = var_0_6:scope(arg_14_1)

		for iter_14_0, iter_14_1 in ipairs(arg_13_0.targetTeam_) do
			if not iter_14_1:isDeath() and not iter_14_1:isAffected() and math.abs(iter_14_1:getX() - arg_14_0) < var_14_1 / 2 then
				table.insert(var_14_0, iter_14_1)
			end
		end

		return var_14_0
	end

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.blueBubbles) do
		if arg_13_0.blueBubbles[iter_13_0] and arg_13_0.blueBubbles[iter_13_0] > 0 then
			arg_13_0.blueBubbles[iter_13_0] = arg_13_0.blueBubbles[iter_13_0] - 1

			if arg_13_0.blueBubbles[iter_13_0] < 1 and arg_13_0.bubbles[iter_13_0].blueEffect then
				arg_13_0.bubbles[iter_13_0].blueEffect:stop()

				arg_13_0.bubbles[iter_13_0].blueEffect = nil
			end
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	for iter_13_2, iter_13_3 in ipairs(arg_13_0.bubbles) do
		local var_13_1 = var_13_0(iter_13_3.x, arg_13_0.GreenSkill)
		local var_13_2 = arg_13_0:createAttackUnits(var_13_1, arg_13_0.GreenSkill)

		for iter_13_4, iter_13_5 in ipairs(var_13_2) do
			iter_13_5.rate_ = iter_13_3.rate

			table.insert(arg_13_0.moveAttackUnits_, iter_13_5)
			table.insert(arg_13_0.records_.special_units, iter_13_5)
		end

		if arg_13_0.blueBubbles[iter_13_2] and arg_13_0.blueBubbles[iter_13_2] > 0 then
			local var_13_3 = var_13_0(iter_13_3.x, arg_13_0.BlueSkill)
			local var_13_4 = arg_13_0:createAttackUnits(var_13_3, arg_13_0.BlueSkill)

			for iter_13_6, iter_13_7 in ipairs(var_13_4) do
				table.insert(arg_13_0.moveAttackUnits_, iter_13_7)
				table.insert(arg_13_0.records_.special_units, iter_13_7)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	local var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5 = var_0_3.super.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)

	if var_15_2 > 0 and arg_15_1.rate_ then
		var_15_2 = var_15_2 * arg_15_1.rate_
	end

	return var_15_0, var_15_1, var_15_2, var_15_3, var_15_4, var_15_5
end

function var_0_3.die(arg_16_0)
	var_0_3.super.die(arg_16_0)

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.bubbles) do
		if iter_16_1.effect then
			iter_16_1.effect:stop()

			iter_16_1.effect = nil
		end

		if iter_16_1.blueEffect then
			iter_16_1.blueEffect:stop()

			iter_16_1.blueEffect = nil
		end
	end

	for iter_16_2, iter_16_3 in ipairs(arg_16_0.summonMonsters_) do
		if not iter_16_3:isDeath() then
			iter_16_3:updateHp(0)
			iter_16_3:die()
		end
	end
end

return var_0_3
