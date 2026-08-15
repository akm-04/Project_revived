local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementYuji", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 92000061
local var_0_7 = {
	40010165
}
local var_0_8 = 0.02
local var_0_9 = 0.3

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.halo_ = nil
	arg_2_0.summonMonsters_ = {}
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_1.rootID_ == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_0 = {}

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isAffected() then
				table.insert(var_3_0, iter_3_1)
			end
		end

		if next(var_3_0) then
			local var_3_1 = var_3_0[math.random(1, #var_3_0)]
			local var_3_2 = arg_3_0:getTeamType() == var_0_2.TeamType.A and 1 or -1
			local var_3_3 = arg_3_0.hero_:getColor()
			local var_3_4 = arg_3_0:getSkillLevelByID(arg_3_1.rootID_)
			local var_3_5 = {
				x = var_3_1:getX() + var_3_2 * 100,
				y = var_3_1:getY()
			}
			local var_3_6 = arg_3_0:setSummonMonsters(var_0_6, var_3_4, var_3_3, var_3_5)

			if var_3_6 then
				local var_3_7 = {
					monster = var_3_6,
					target = var_3_1
				}

				table.insert(arg_3_0.summonMonsters_, var_3_7)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.halo_ then
		local var_4_0 = arg_4_0:getEnergySkillID()
		local var_4_1 = {
			fighter = arg_4_0,
			effect_area = function()
				return true
			end,
			target_type = var_0_2.HaloEffect.sideTeam,
			buffs = var_0_7,
			level = arg_4_0:getSkillLevelByID(var_4_0),
			skillID = var_4_0,
			manualHarm = function(arg_6_0)
				return 300
			end
		}

		arg_4_0:addBuffHalo(var_4_1)

		arg_4_0.halo_ = var_4_1
	end

	if next(arg_4_0.summonMonsters_) then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("attack_info")) do
			local var_4_2 = iter_4_1.fighter_

			if iter_4_1.rootID_ == var_4_2:getEnergySkillID() then
				for iter_4_2, iter_4_3 in ipairs(arg_4_0.summonMonsters_) do
					if iter_4_3.target == var_4_2 then
						iter_4_3.monster:updateHp(0)
						iter_4_3.monster:die()
						var_4_2:updateHp(var_4_2:getHp() - var_4_2:getHpLimit() * var_0_9)

						if var_4_2:getHp() <= 0 then
							var_4_2:die()
						end

						break
					end
				end
			end
		end
	end
end

function var_0_3.die(arg_7_0)
	var_0_3.super.die(arg_7_0)

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.summonMonsters_) do
		if not iter_7_1.monster:isDeath() then
			iter_7_1.monster:updateHp(0)
			iter_7_1.monster:die()
		end
	end

	arg_7_0.summonMonsters_ = {}
end

function var_0_3.deathFeedback(arg_8_0, arg_8_1)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.summonMonsters_) do
		if iter_8_1.monster == arg_8_1 then
			table.remove(arg_8_0.summonMonsters_, iter_8_0)

			break
		end
	end
end

function var_0_3.setSummonMonsters(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_9_1 = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0 = var_0_1.ctx.battle.summonMonsters[var_9_1]
	else
		local var_9_2 = var_0_5.new()

		var_9_2:populateWithTableID(arg_9_1)

		var_9_2.level_ = arg_9_2 or var_9_2.level_
		var_9_2.color_ = arg_9_3 or var_9_2.color_

		for iter_9_0, iter_9_1 in pairs(var_9_2.skillLev_) do
			var_9_2.skillLev_[iter_9_0] = arg_9_0.hero_.skillLev_[iter_9_0]
		end

		local var_9_3 = var_9_2:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_3).new({
			is_arena = arg_9_0.isInArena_
		})

		var_9_0:populateWithHero(var_9_2)
		var_9_0:initModels()
		var_9_0.fighterModel:initHeaderView(arg_9_0:getTeamType() - 1)

		var_9_0.fighterIndex = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0:setFormationDelay(0, 100)
	end

	var_9_0:setTeamType(arg_9_0:getTeamType())

	var_9_0.summoner = arg_9_0

	var_9_0.fighterModel:pos(arg_9_4.x, arg_9_4.y - #arg_9_0.summonMonsters_)
	var_9_0:updateHp(var_9_0:getHpLimit())
	var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
	var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_9_0:born()
	var_9_0:setGlobalBuffs()

	local var_9_4 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_9_4, var_9_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()

	return var_9_0
end

return var_0_3
