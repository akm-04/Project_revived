local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Alice", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = {
	{
		40010595,
		40010596
	},
	{
		40010597,
		40010598
	},
	{
		40010599,
		40010600
	},
	{
		40010601,
		40010602
	},
	{
		40010603,
		40010604
	}
}
local var_0_8 = 75
local var_0_9 = 40010592
local var_0_10 = {
	40010593,
	40010594
}
local var_0_11 = 500000

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonsters_ = {}
	arg_2_0.purpleHarmFighter_ = {}
	arg_2_0.purpleCollectHp_ = 0
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_3_4 > 0 and arg_3_1.attackType == var_0_2.AttackType.AD or arg_3_1.attackType == var_0_2.AttackType.AP then
		local var_3_0 = arg_3_1.target:getBuffs()
		local var_3_1 = 1

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			if iter_3_1:getTableID() == var_0_7[1][1] then
				var_3_1 = 1.2

				break
			elseif iter_3_1:getTableID() == var_0_7[2][1] then
				var_3_1 = 1.5

				break
			elseif iter_3_1:getTableID() == var_0_7[3][1] then
				var_3_1 = 2

				break
			elseif iter_3_1:getTableID() == var_0_7[4][1] then
				var_3_1 = 2.5

				break
			elseif iter_3_1:getTableID() == var_0_7[5][1] then
				var_3_1 = 3

				break
			end
		end

		arg_3_4 = arg_3_4 * var_3_1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if not arg_4_0:isDeath() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			local var_4_0 = iter_4_1.harm
			local var_4_1 = iter_4_1.fighter

			if iter_4_1.type == var_0_2.AttackType.AP and not var_4_1:isDeath() and var_4_1:getTeamType() ~= arg_4_0:getTeamType() and not var_4_1:isHasBuffByID(var_0_7[5][1]) and var_4_1:getSummonType() == var_0_2.summonMonsterType.None then
				if not arg_4_0.purpleHarmFighter_[var_4_1] then
					arg_4_0.purpleHarmFighter_[var_4_1] = 0
				end

				arg_4_0.purpleHarmFighter_[var_4_1] = arg_4_0.purpleHarmFighter_[var_4_1] + var_4_0
				arg_4_0.purpleCollectHp_ = arg_4_0.purpleCollectHp_ + var_4_0

				if arg_4_0.purpleCollectHp_ >= var_0_11 and next(arg_4_0.purpleHarmFighter_) then
					local var_4_2
					local var_4_3

					for iter_4_2, iter_4_3 in pairs(arg_4_0.purpleHarmFighter_) do
						if not var_4_2 or var_4_2 < iter_4_3 then
							var_4_3 = iter_4_2
							var_4_2 = iter_4_3
						end
					end

					local var_4_4 = arg_4_0:purpleBuffNum(var_4_3)

					if var_4_4 < 5 then
						if var_4_4 > 0 then
							for iter_4_4, iter_4_5 in ipairs(var_0_7[var_4_4]) do
								var_4_3:removeBuffByID(iter_4_5)
							end
						end

						local var_4_5 = arg_4_0:newBuff(var_0_7[var_4_4 + 1], var_4_3, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						var_4_3:addBuffs(var_4_5)
					end

					arg_4_0.purpleHarmFighter_ = {}
					arg_4_0.purpleCollectHp_ = 0
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	local var_5_0 = arg_5_1.skillID
	local var_5_1 = arg_5_1.target

	if var_5_0 == arg_5_0:getEnergySkillID() then
		if arg_5_0:purpleBuffNum(var_5_1) > 0 then
			local var_5_2 = arg_5_0:newBuff({
				var_0_9
			}, var_5_1, var_5_0)

			var_5_1:addBuffs(var_5_2)
		end
	elseif var_5_0 == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_5_0:purpleBuffNum(var_5_1) > 0 then
		local var_5_3 = arg_5_0:newBuff(var_0_10, var_5_1, var_5_0)

		var_5_1:addBuffs(var_5_3)
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	var_0_3.super.buffAddAction(arg_6_0, arg_6_1)

	if arg_6_1:getSkillID() == arg_6_0:getEnergySkillID() then
		local var_6_0 = var_0_8 * arg_6_0:purpleBuffNum(arg_6_1.target)

		arg_6_1:setExtraTime(var_6_0)
	end
end

function var_0_3.purpleBuffNum(arg_7_0, arg_7_1)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 0 then
		return 0
	else
		for iter_7_0, iter_7_1 in ipairs(var_0_7) do
			if arg_7_1:isHasBuffByID(iter_7_1[1]) then
				return iter_7_0
			end
		end

		return 0
	end
end

function var_0_3.die(arg_8_0)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.summonMonsters_) do
		if not iter_8_1:isDeath() then
			iter_8_1:updateHp(0)
			iter_8_1:die()
		end
	end

	var_0_3.super.die(arg_8_0)
end

function var_0_3.moveUnitArrive(arg_9_0, arg_9_1)
	var_0_3.super.moveUnitArrive(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.skillID
	local var_9_1 = var_0_6:summonMonster(var_9_0)

	if next(var_9_1) == nil then
		return
	end

	for iter_9_0, iter_9_1 in ipairs(var_9_1) do
		local var_9_2 = arg_9_0:getSkillLevelByID(var_9_0)
		local var_9_3 = arg_9_0.hero_:getColor()
		local var_9_4 = {
			x = arg_9_1.desX_,
			y = arg_9_1.desY_
		}

		arg_9_0:setSummonMonsters(iter_9_1, var_9_2, var_9_3, var_9_4)
	end
end

function var_0_3.setSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_10_1 = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_0 = var_0_1.ctx.battle.summonMonsters[var_10_1]
	else
		local var_10_2 = var_0_4.new()

		var_10_2:populateWithTableID(arg_10_1)

		var_10_2.level_ = arg_10_2 or var_10_2.level_
		var_10_2.color_ = arg_10_3 or var_10_2.color_
		var_10_2.skillLev_[var_0_2.SKILL_INDEX.Blue] = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		local var_10_3 = var_10_2:className()

		var_10_0 = var_0_1.ctx.battle.requireFighter(var_10_3).new({
			is_arena = arg_10_0.isInArena_
		})

		var_10_0:populateWithHero(var_10_2)
		var_10_0:initModels()
		var_10_0.fighterModel:initHeaderView(arg_10_0:getTeamType() - 1)

		var_10_0.fighterIndex = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_0:setFormationDelay(0, 100)
	end

	var_10_0:setTeamType(arg_10_0:getTeamType())

	var_10_0.summoner = arg_10_0

	var_10_0.fighterModel:pos(arg_10_4.x, arg_10_4.y)
	var_10_0:updateHp(var_10_0:getHpLimit())
	var_10_0:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
	var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_10_0:born()
	var_10_0:setGlobalBuffs()

	local var_10_4 = var_10_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_10_4, var_10_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_10_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_10_0.summonMonsters_, var_10_0)
end

function var_0_3.newBuff(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_1) do
		local var_11_1 = var_0_5.new({
			tableID = iter_11_1,
			start = var_0_1.ctx.battle.count,
			level = arg_11_0:getSkillLevelByID(arg_11_3),
			skillID = arg_11_3,
			fighter = arg_11_0,
			target = arg_11_2
		})

		var_11_1:setIsHit(true)
		var_11_1:setDirection(arg_11_0:getFighterModel():getFlipX())
		table.insert(var_11_0, var_11_1)
	end

	return var_11_0
end

return var_0_3
