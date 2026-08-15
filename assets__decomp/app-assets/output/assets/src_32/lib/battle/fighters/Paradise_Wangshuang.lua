local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseWangshuang", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
end

function var_0_3.deathFeedback(arg_2_0, arg_2_1)
	var_0_3.super.deathFeedback(arg_2_0, arg_2_1)

	if arg_2_1.killer_ and arg_2_1.killer_ == arg_2_0 then
		local var_2_0 = var_0_4:summonMonster(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_2_0, iter_2_1 in ipairs(var_2_0) do
			local var_2_1 = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			local var_2_2 = arg_2_0.hero_:getColor()
			local var_2_3 = {
				x = arg_2_1:getX(),
				y = arg_2_1:getY()
			}

			arg_2_0:setSummonMonsters(iter_2_1, var_2_1, var_2_2, var_2_3)
		end
	end
end

function var_0_3.die(arg_3_0)
	var_0_3.super.die(arg_3_0)

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
		iter_3_1:die()
	end
end

function var_0_3.setSummonMonsters(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4)
	local var_4_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0 = var_0_1.ctx.battle.summonMonsters[var_4_1]
	else
		local var_4_2 = var_0_5.new()

		var_4_2:populateWithTableID(arg_4_1)

		var_4_2.level_ = arg_4_2 or var_4_2.level_
		var_4_2.color_ = arg_4_3 or var_4_2.color_

		for iter_4_0, iter_4_1 in pairs(var_4_2.skillLev_) do
			var_4_2.skillLev_[iter_4_0] = arg_4_0.hero_.skillLev_[iter_4_0]
		end

		local var_4_3 = var_4_2:className()

		var_4_0 = var_0_1.ctx.battle.requireFighter(var_4_3).new({
			is_arena = arg_4_0.isInArena_
		})

		var_4_0:populateWithHero(var_4_2)
		var_4_0:initModels()
		var_4_0.fighterModel:initHeaderView(arg_4_0:getTeamType() - 1)

		var_4_0.fighterIndex = arg_4_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_4_0:setFormationDelay(0, 100)
	end

	var_4_0:setTeamType(arg_4_0:getTeamType())

	var_4_0.summoner = arg_4_0

	var_4_0.fighterModel:pos(arg_4_4.x, arg_4_4.y)
	var_4_0:updateHp(var_4_0:getHpLimit())
	var_4_0:getFighterModel():flipX(arg_4_0:getTeamType() == var_0_2.TeamType.B)
	var_4_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_4_0:born()
	var_4_0:setGlobalBuffs()

	local var_4_4 = var_4_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_4_4, var_4_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_4_0)
	table.insert(arg_4_0.summonMonsters_, var_4_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.isHurtBreak(arg_5_0, arg_5_1, arg_5_2)
	return false
end

return var_0_3
