local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ParadiseBulishi", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")

function var_0_3.deathFeedback(arg_1_0, arg_1_1)
	var_0_3.super.deathFeedback(arg_1_0, arg_1_1)

	if arg_1_1.killer_ and arg_1_1.killer_ == arg_1_0 then
		local var_1_0 = var_0_4:summonMonster(arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		for iter_1_0, iter_1_1 in ipairs(var_1_0) do
			local var_1_1 = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
			local var_1_2 = arg_1_0.hero_:getColor()
			local var_1_3 = {
				x = arg_1_1:getX(),
				y = arg_1_1:getY()
			}

			arg_1_0:setSummonMonsters(iter_1_1, var_1_1, var_1_2, var_1_3)
		end
	end
end

function var_0_3.setSummonMonsters(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4)
	local var_2_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_2_1 = arg_2_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_2_0 = var_0_1.ctx.battle.summonMonsters[var_2_1]
	else
		local var_2_2 = var_0_5.new()

		var_2_2:populateWithTableID(arg_2_1)

		var_2_2.level_ = arg_2_2 or var_2_2.level_
		var_2_2.color_ = arg_2_3 or var_2_2.color_

		for iter_2_0, iter_2_1 in pairs(var_2_2.skillLev_) do
			var_2_2.skillLev_[iter_2_0] = arg_2_0.hero_.skillLev_[iter_2_0]
		end

		local var_2_3 = var_2_2:className()

		var_2_0 = var_0_1.ctx.battle.requireFighter(var_2_3).new({
			is_arena = arg_2_0.isInArena_
		})

		var_2_0:populateWithHero(var_2_2)
		var_2_0:initModels()
		var_2_0.fighterModel:initHeaderView(arg_2_0:getTeamType() - 1)

		var_2_0.fighterIndex = arg_2_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_2_0:setFormationDelay(0, 100)
	end

	var_2_0:setTeamType(arg_2_0:getTeamType())

	var_2_0.summoner = arg_2_0

	var_2_0.fighterModel:pos(arg_2_4.x, arg_2_4.y)
	var_2_0:updateHp(var_2_0:getHpLimit())
	var_2_0:getFighterModel():flipX(arg_2_0:getTeamType() == var_0_2.TeamType.B)
	var_2_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_2_0:born()
	var_2_0:setGlobalBuffs()

	local var_2_4 = var_2_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_2_4, var_2_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_2_0)
	var_0_1.ctx.battle.updateZorder()
end

function var_0_3.isHurtBreak(arg_3_0, arg_3_1, arg_3_2)
	return false
end

return var_0_3
