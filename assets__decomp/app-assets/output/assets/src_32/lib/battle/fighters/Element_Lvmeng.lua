local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("ElementLvmeng", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.Lesstime = 0
	arg_1_0.unit = nil
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if arg_2_0:acttionInBlack() and arg_2_0.isSummon then
		arg_2_0.Lesstime = arg_2_0.Lesstime - 1

		if arg_2_0.Lesstime == 0 then
			local var_2_0 = arg_2_0:getEnergySkillID()
			local var_2_1 = var_0_4:summonMonster(var_2_0)

			if next(var_2_1) == nil or #var_2_1 == 1 then
				return
			end

			arg_2_0.isSummon = false

			local var_2_2

			for iter_2_0 = 1, 2 do
				local var_2_3 = math.random(var_2_1[1], var_2_1[2])

				if not var_2_2 then
					local var_2_4 = arg_2_0:getSkillLevelByID(var_2_0)
					local var_2_5 = arg_2_0.hero_:getColor()
					local var_2_6 = {}

					if arg_2_0.unit then
						var_2_6 = {
							x = arg_2_0.unit.desX_,
							y = arg_2_0.unit.desY_ - 50
						}
					else
						var_2_6 = {
							x = arg_2_0:getX() - 50,
							y = arg_2_0:getY() - 50
						}
					end

					arg_2_0:setSummonMonsters(var_2_3, var_2_4, var_2_5, var_2_6)

					var_2_2 = var_2_3
				else
					while var_2_3 == var_2_2 do
						var_2_3 = math.random(var_2_1[1], var_2_1[2])
					end

					local var_2_7 = arg_2_0:getSkillLevelByID(var_2_0)
					local var_2_8 = arg_2_0.hero_:getColor()
					local var_2_9 = {}

					if arg_2_0.unit then
						var_2_9 = {
							x = arg_2_0.unit.desX_,
							y = arg_2_0.unit.desY_ + 50
						}
					else
						var_2_9 = {
							x = arg_2_0:getX() - 50,
							y = arg_2_0:getY() + 50
						}
					end

					arg_2_0:setSummonMonsters(var_2_3, var_2_7, var_2_8, var_2_9)
				end
			end

			arg_2_0.unit = nil
		end
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_0.isGetPos then
		arg_3_0.unit = var_0_0.clone(arg_3_1)
		arg_3_0.isGetPos = false
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.isSummon = true
		arg_4_0.isGetPos = true
		arg_4_0.Lesstime = var_0_0.clone(var_0_6)
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0
	local var_5_1 = var_0_5.new()

	var_5_1:populateWithTableID(arg_5_1)

	var_5_1.level_ = arg_5_2 or var_5_1.level_
	var_5_1.color_ = arg_5_3 or var_5_1.color_

	for iter_5_0, iter_5_1 in ipairs(var_5_1.skillLev_) do
		local var_5_2 = arg_5_0.hero_:getSkillLevel(iter_5_0)

		if var_5_2 and var_5_2 > 0 then
			var_5_1.skillLev_[iter_5_0] = var_0_0.clone(var_5_2)
		end
	end

	local var_5_3 = var_5_1:className()
	local var_5_4 = var_0_1.ctx.battle.requireFighter(var_5_3).new({
		is_arena = arg_5_0.isInArena_
	})

	var_5_4:populateWithHero(var_5_1)
	var_5_4:setTeamType(arg_5_0:getTeamType())
	var_5_4:initModels()
	var_5_4.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

	var_5_4.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

	var_5_4:setFormationDelay(0, 100)

	var_5_4.summoner = arg_5_0

	var_5_4.fighterModel:pos(arg_5_4.x, arg_5_4.y)
	var_5_4:updateHp(var_5_4:getHpLimit())
	var_5_4:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_4.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_4:born()
	var_5_4:setGlobalBuffs()

	local var_5_5 = var_5_4:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_5, var_5_4)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_4)
	var_0_1.ctx.battle.updateZorder()
end

return var_0_3
