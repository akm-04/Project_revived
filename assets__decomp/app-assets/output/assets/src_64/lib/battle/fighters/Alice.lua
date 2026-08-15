local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Alice", var_0_1.ctx.battle.getRequire("BaseFighter"))
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
local var_0_9 = 0.1
local var_0_10 = -0.0003
local var_0_11 = 40010592
local var_0_12 = {
	40010593,
	40010594
}

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonsters_ = {}
	arg_2_0.purpleHarmFighter_ = {}
	arg_2_0.purpleCollectHp_ = 0
	arg_2_0.purpleBuffCount_ = 0
end

function var_0_3.updateHp(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0:getHp()

	var_0_3.super.updateHp(arg_3_0, arg_3_1, arg_3_2)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_3_0:isDeath() then
		local var_3_1 = arg_3_0:getHp()

		if var_3_1 < var_3_0 then
			arg_3_0.purpleCollectHp_ = arg_3_0.purpleCollectHp_ + var_3_0 - var_3_1

			if arg_3_0.purpleCollectHp_ >= arg_3_0:getHpLimit() * (var_0_9 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) then
				arg_3_0.purpleBuffCount_ = arg_3_0.purpleBuffCount_ + 1
				arg_3_0.purpleCollectHp_ = 0

				if next(arg_3_0.purpleHarmFighter_) then
					local var_3_2
					local var_3_3

					for iter_3_0, iter_3_1 in pairs(arg_3_0.purpleHarmFighter_) do
						if not var_3_2 or var_3_2 < iter_3_1 then
							var_3_3 = iter_3_0
							var_3_2 = iter_3_1
						end
					end

					local var_3_4 = arg_3_0:purpleBuffNum(var_3_3)

					if var_3_4 < 5 then
						if var_3_4 > 0 then
							for iter_3_2, iter_3_3 in ipairs(var_0_7[var_3_4]) do
								var_3_3:removeBuffByID(iter_3_3)
							end
						end

						local var_3_5 = arg_3_0:newBuff(var_0_7[var_3_4 + 1], var_3_3, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						var_3_3:addBuffs(var_3_5)
					end

					arg_3_0.purpleHarmFighter_ = {}
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_4_4 > 0 and arg_4_1.attackType == var_0_2.AttackType.AD or arg_4_1.attackType == var_0_2.AttackType.AP then
		local var_4_0 = arg_4_1.target:getBuffs()
		local var_4_1 = 1

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			if iter_4_1:getTableID() == var_0_7[1][1] then
				var_4_1 = 1.2

				break
			elseif iter_4_1:getTableID() == var_0_7[2][1] then
				var_4_1 = 1.5

				break
			elseif iter_4_1:getTableID() == var_0_7[3][1] then
				var_4_1 = 2

				break
			elseif iter_4_1:getTableID() == var_0_7[4][1] then
				var_4_1 = 2.5

				break
			elseif iter_4_1:getTableID() == var_0_7[5][1] then
				var_4_1 = 3

				break
			end
		end

		arg_4_4 = arg_4_4 * var_4_1
	end

	return var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.toDoPerFrames(arg_5_0)
	if not arg_5_0:isDeath() and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
			local var_5_0 = iter_5_1.harm
			local var_5_1 = iter_5_1.fighter

			if not var_5_1:isDeath() and var_5_1:getTeamType() ~= arg_5_0:getTeamType() and not var_5_1:isHasBuffByID(var_0_7[5][1]) and var_5_1:getSummonType() == var_0_2.summonMonsterType.None then
				if not arg_5_0.purpleHarmFighter_[var_5_1] then
					arg_5_0.purpleHarmFighter_[var_5_1] = 0
				end

				arg_5_0.purpleHarmFighter_[var_5_1] = arg_5_0.purpleHarmFighter_[var_5_1] + var_5_0
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID
	local var_6_1 = arg_6_1.target

	if var_6_0 == arg_6_0:getEnergySkillID() then
		if arg_6_0:purpleBuffNum(var_6_1) > 0 then
			local var_6_2 = arg_6_0:newBuff({
				var_0_11
			}, var_6_1, var_6_0)

			var_6_1:addBuffs(var_6_2)
		end
	elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_6_0:purpleBuffNum(var_6_1) > 0 then
		local var_6_3 = arg_6_0:newBuff(var_0_12, var_6_1, var_6_0)

		var_6_1:addBuffs(var_6_3)
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	var_0_3.super.buffAddAction(arg_7_0, arg_7_1)

	if arg_7_1:getSkillID() == arg_7_0:getEnergySkillID() then
		local var_7_0 = var_0_8 * arg_7_0:purpleBuffNum(arg_7_1.target)

		arg_7_1:setExtraTime(var_7_0)
	end
end

function var_0_3.purpleBuffNum(arg_8_0, arg_8_1)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 0 then
		return 0
	else
		for iter_8_0, iter_8_1 in ipairs(var_0_7) do
			if arg_8_1:isHasBuffByID(iter_8_1[1]) then
				return iter_8_0
			end
		end

		return 0
	end
end

function var_0_3.die(arg_9_0)
	for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonMonsters_) do
		if not iter_9_1:isDeath() then
			iter_9_1:updateHp(0)
			iter_9_1:die()
		end
	end

	var_0_3.super.die(arg_9_0)
end

function var_0_3.moveUnitArrive(arg_10_0, arg_10_1)
	var_0_3.super.moveUnitArrive(arg_10_0, arg_10_1)

	local var_10_0 = arg_10_1.skillID
	local var_10_1 = var_0_6:summonMonster(var_10_0)

	if next(var_10_1) == nil then
		return
	end

	for iter_10_0, iter_10_1 in ipairs(var_10_1) do
		local var_10_2 = arg_10_0:getSkillLevelByID(var_10_0)
		local var_10_3 = arg_10_0.hero_:getColor()
		local var_10_4 = {
			x = arg_10_1.desX_,
			y = arg_10_1.desY_
		}

		arg_10_0:setSummonMonsters(iter_10_1, var_10_2, var_10_3, var_10_4)
	end
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0 = arg_11_0:getSummonMonster()
	else
		local var_11_1 = var_0_4.new()

		var_11_1:populateWithTableID(arg_11_1)

		var_11_1.level_ = arg_11_2 or var_11_1.level_
		var_11_1.color_ = arg_11_3 or var_11_1.color_
		var_11_1.skillLev_[var_0_2.SKILL_INDEX.Blue] = arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		local var_11_2 = var_11_1:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_2).new({
			is_arena = arg_11_0.isInArena_
		})

		var_11_0:populateWithHero(var_11_1)
		var_11_0:initModels()
		var_11_0.fighterModel:initHeaderView(arg_11_0:getTeamType() - 1)

		var_11_0.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0:setFormationDelay(0, 100)
	end

	var_11_0:setTeamType(arg_11_0:getTeamType())

	var_11_0.summoner = arg_11_0

	var_11_0.fighterModel:pos(arg_11_4.x, arg_11_4.y)
	var_11_0:updateHp(var_11_0:getHpLimit())
	var_11_0:getFighterModel():flipX(arg_11_0:getTeamType() == var_0_2.TeamType.B)
	var_11_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_11_0:born()
	var_11_0:setGlobalBuffs()

	local var_11_3 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_3, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_11_0.summonMonsters_, var_11_0)
end

function var_0_3.newBuff(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		local var_12_1 = var_0_5.new({
			tableID = iter_12_1,
			start = var_0_1.ctx.battle.count,
			level = arg_12_0:getSkillLevelByID(arg_12_3),
			skillID = arg_12_3,
			fighter = arg_12_0,
			target = arg_12_2
		})

		var_12_1:setIsHit(true)
		var_12_1:setDirection(arg_12_0:getFighterModel():getFlipX())
		table.insert(var_12_0, var_12_1)
	end

	return var_12_0
end

return var_0_3
