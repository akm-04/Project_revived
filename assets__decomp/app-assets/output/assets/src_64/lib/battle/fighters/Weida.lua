local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Weida", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = 10001659
local var_0_8 = 40011759
local var_0_9 = 40011757
local var_0_10 = 10001661
local var_0_11 = 10001654
local var_0_12 = 10001657
local var_0_13 = 40011761

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.dog = nil
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == var_0_7 then
		arg_3_4 = arg_3_1.basicHarm
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	if arg_4_0.dog and not arg_4_0.dog:isDeath() and not arg_4_0.dog:isReborning() then
		arg_4_4 = arg_4_4 / 2

		local var_4_0 = arg_4_0:createAttackUnits({
			arg_4_0.dog
		}, var_0_7)

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			iter_4_1.basicHarm = arg_4_4

			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	return var_0_3.super.updateUnitDataByTarget(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and not arg_5_0.dog then
		local var_5_0 = arg_5_1.rootID_

		arg_5_0:summonDog(var_0_4:summonMonster(var_5_0)[1], arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), arg_5_0.hero_:getColor(), {
			x = arg_5_0:getFlipX() and var_0_2.STAGE_WIDTH + 100 or -100,
			y = var_0_2.STAGE_HEIGHT / 2
		}, var_5_0)
	elseif arg_5_1.rootID_ == arg_5_0:getEnergySkillID() and arg_5_0.dog and not arg_5_0.dog:isDeath() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_1 = arg_5_0:createAttackUnits({
			arg_5_0.dog
		}, var_0_12)

		for iter_5_0, iter_5_1 in ipairs(var_5_1) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	if arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and arg_6_1.target == arg_6_0.dog then
		arg_6_0.dog.rank = math.min(arg_6_0.dog.rank + 1, 5)

		local var_6_0 = arg_6_0.dog:getHp()

		arg_6_0.dog:initHp()

		local var_6_1 = arg_6_0.dog.rank - 2

		if var_6_1 > 0 then
			local var_6_2 = var_0_5.new({
				tableID = var_0_8,
				start = var_0_1.ctx.battle.count,
				level = arg_6_0:getSkillLevelByID(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)),
				skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
				fighter = arg_6_0,
				target = arg_6_0.dog
			})

			var_6_2:setActNum(var_6_1)
			arg_6_0.dog:addBuffs({
				var_6_2
			})
		end
	elseif arg_6_1.skillID == var_0_10 and arg_6_1.target:isHasBuffByID(var_0_9) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_3 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_11)

			for iter_6_0, iter_6_1 in ipairs(var_6_3) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	elseif arg_6_1.skillID == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_6_0.dog and not arg_6_0.dog:isDeath() then
		arg_6_0.dog:addBuffs({
			var_0_5.new({
				tableID = var_0_13,
				start = var_0_1.ctx.battle.count,
				level = arg_6_0:getSkillLevelByID(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
				skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
				fighter = arg_6_0,
				target = arg_6_0.dog
			})
		})
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.dog then
		return {
			arg_7_0.dog
		}
	else
		return {}
	end
end

function var_0_3.forceDie(arg_8_0)
	if arg_8_0.dog and not arg_8_0.dog:isDeath() then
		arg_8_0.dog:forceDie()
	end

	var_0_3.super.forceDie(arg_8_0)
end

function var_0_3.summonDog(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_9_0 = arg_9_0:getSummonMonster()
	else
		local var_9_1 = var_0_6.new()

		var_9_1:populateWithTableID(arg_9_1)

		var_9_1.level_ = arg_9_2 or var_9_1.level_
		var_9_1.color_ = arg_9_3 or var_9_1.color_

		for iter_9_0, iter_9_1 in ipairs(var_9_1.skillLev_) do
			local var_9_2 = arg_9_0.hero_:getSkillLevel(iter_9_0)

			if var_9_2 and var_9_2 > 0 then
				var_9_1.skillLev_[iter_9_0] = var_0_0.clone(var_9_2)
			end
		end

		local var_9_3 = var_9_1:className()

		var_9_0 = var_0_1.ctx.battle.requireFighter(var_9_3).new({
			is_arena = arg_9_0.isInArena_
		})

		var_9_0:populateWithHero(var_9_1)
		var_9_0:initModels()
		var_9_0.fighterModel:initHeaderView(arg_9_0:getTeamType() - 1)

		var_9_0.fighterIndex = arg_9_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_9_0:setFormationDelay(0, 50)
	end

	var_9_0:setTeamType(arg_9_0:getTeamType())

	var_9_0.summoner = arg_9_0

	var_9_0.fighterModel:pos(arg_9_4.x, arg_9_4.y)

	var_9_0.isImmuneControl = true

	var_9_0:updateHp(var_9_0:getHpLimit())
	var_9_0:getFighterModel():flipX(arg_9_0:getTeamType() == var_0_2.TeamType.B)
	var_9_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_9_0:born()
	var_9_0:setGlobalBuffs()
	var_9_0:initHp()

	local var_9_4 = var_9_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_9_4, var_9_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_9_0)
	var_0_1.ctx.battle.updateZorder()

	arg_9_0.dog = var_9_0
end

return var_0_3
