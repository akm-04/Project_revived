local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Wangshuang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = 40010159
local var_0_9 = 40010160
local var_0_10 = 40010164
local var_0_11 = 20

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenTarget_ = nil
	arg_2_0.blueTargets_ = {}
	arg_2_0.summonMonsters_ = {}
	arg_2_0.aliveSummonMonstersCount = 0
end

function var_0_3.newBuff(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		local var_3_1 = var_0_7.new({
			tableID = iter_3_1,
			start = var_0_1.ctx.battle.count,
			level = arg_3_0:getSkillLevelByID(arg_3_3),
			skillID = arg_3_3,
			fighter = arg_3_0,
			target = arg_3_2
		})

		var_3_1:setIsHit(true)
		var_3_1:setDirection(arg_3_0:getFighterModel():getFlipX())
		table.insert(var_3_0, var_3_1)
	end

	return var_3_0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0.greenTarget_ = arg_4_1.target
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_4_0 = var_0_5:time(var_0_9)
		local var_4_1 = {
			hero = arg_4_1.target,
			count = var_4_0
		}

		table.insert(arg_4_0.blueTargets_, var_4_1)
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0.greenTarget_ and not arg_5_0.greenTarget_:isDeath() and not arg_5_0.greenTarget_:isHasBuffByID(var_0_8) then
		arg_5_0.greenTarget_ = nil
	end

	for iter_5_0 = #arg_5_0.blueTargets_, 1, -1 do
		local var_5_0 = arg_5_0.blueTargets_[iter_5_0]

		var_5_0.count = var_5_0.count - 1

		if var_5_0.count <= 0 then
			table.remove(arg_5_0.blueTargets_, iter_5_0)
		end
	end

	for iter_5_1, iter_5_2 in ipairs(arg_5_0:getInfoByKey("unit_info")) do
		local var_5_1 = iter_5_2.target
		local var_5_2 = iter_5_2.fighter

		if var_5_2:getTeamType() == arg_5_0:getTeamType() then
			for iter_5_3, iter_5_4 in ipairs(arg_5_0.blueTargets_) do
				if iter_5_4.hero == var_5_1 then
					var_5_2:addBuffs(arg_5_0:newBuff({
						var_0_10
					}, var_5_2, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))

					break
				end
			end
		end
	end
end

function var_0_3.die(arg_6_0)
	local var_6_0

	arg_6_0.blueTargets_ = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.summonMonsters_) do
		if not iter_6_1:isDeath() then
			iter_6_1:updateHp(0)
			iter_6_1:die()
		end
	end

	var_0_3.super.die(arg_6_0)
end

function var_0_3.deathFeedback(arg_7_0, arg_7_1)
	if arg_7_0.greenTarget_ == arg_7_1 then
		local var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
		local var_7_1 = var_0_4:summonMonster(var_7_0)
		local var_7_2 = arg_7_0:getSkillLevelByID(var_7_0)
		local var_7_3 = arg_7_0.hero_:getColor()
		local var_7_4 = {
			x = arg_7_1:getX(),
			y = arg_7_1:getY()
		}
		local var_7_5

		for iter_7_0, iter_7_1 in ipairs(var_7_1) do
			if arg_7_0.aliveSummonMonstersCount < var_0_11 then
				arg_7_0:setSummonMonsters(iter_7_1, var_7_2, var_7_3, var_7_4)
			end
		end

		arg_7_0.greenTarget_ = nil
	elseif arg_7_1.summoner == arg_7_0 and arg_7_0.aliveSummonMonstersCount > 0 then
		arg_7_0.aliveSummonMonstersCount = arg_7_0.aliveSummonMonstersCount - 1
	end
end

function var_0_3.setSummonMonsters(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_8_0 = arg_8_0:getSummonMonster()
	else
		local var_8_1 = var_0_6.new()

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
	var_8_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_8_0:born()
	var_8_0:setGlobalBuffs()

	local var_8_3 = var_8_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_8_3, var_8_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_8_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_8_0.summonMonsters_, var_8_0)

	arg_8_0.aliveSummonMonstersCount = arg_8_0.aliveSummonMonstersCount + 1
end

return var_0_3
