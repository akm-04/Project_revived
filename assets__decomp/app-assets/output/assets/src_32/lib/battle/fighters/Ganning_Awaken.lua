local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Ganning_Awaken", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = 6
local var_0_7 = 60

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.summonMonsters_ = {}
	arg_1_0.summonMonster_ = nil
	arg_1_0.canMake = true
	arg_1_0.shanbiTime = 0
	arg_1_0.isEnergyReady_ = false
end

function var_0_3.die(arg_2_0)
	if next(arg_2_0.summonMonsters_) ~= true then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
			if not iter_2_1:isDeath() then
				iter_2_1:updateHp(0)
				iter_2_1:die()
			end
		end
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)

	if arg_3_0.shanbiTime > 0 then
		arg_3_0.shanbiTime = arg_3_0.shanbiTime - 1
	end

	if arg_3_0:acttionInBlack() and not arg_3_0:isDeath() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0.summonMonsters_) do
			if iter_3_1:isDeath() then
				table.remove(arg_3_0.summonMonsters_, iter_3_0)
			end
		end
	end
end

function var_0_3.playShanbi(arg_4_0, arg_4_1)
	var_0_3.super.playShanbi(arg_4_0, arg_4_1)

	if arg_4_0.shanbiTime == 0 and arg_4_0.canMake == false then
		arg_4_0.canMake = true
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 and arg_4_0.canMake == true then
		local var_4_0 = var_0_4:summonMonster(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

		if next(var_4_0) == nil then
			return
		end

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			local var_4_1 = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
			local var_4_2 = arg_4_0.hero_:getColor()
			local var_4_3 = arg_4_0:getFlipX() and arg_4_0:getX() - 15 * math.random() or arg_4_0:getX() + 15 * math.random()
			local var_4_4 = var_0_1.ctx.battle.adjustX(var_4_3, arg_4_0)
			local var_4_5 = {
				x = var_4_4,
				y = arg_4_0:getY()
			}

			arg_4_0:setSummonMonsters(iter_4_1, var_4_1, var_4_2, var_4_5)
		end

		arg_4_0.canMake = false
		arg_4_0.shanbiTime = var_0_7
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	if #arg_5_0.summonMonsters_ >= var_0_6 then
		return
	end

	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_0 = arg_5_0:getSummonMonster()
	else
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

		var_5_0 = var_0_1.ctx.battle.requireFighter(var_5_3).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_0:populateWithHero(var_5_1)
		var_5_0:initModels()
		var_5_0.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_0.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0:setFormationDelay(0, 100)
	end

	var_5_0:setTeamType(arg_5_0:getTeamType())

	var_5_0.summoner = arg_5_0

	local var_5_4 = {}

	for iter_5_2 = 1, var_0_6 do
		var_5_4[iter_5_2] = iter_5_2
	end

	for iter_5_3, iter_5_4 in ipairs(arg_5_0.summonMonsters_) do
		var_5_4[iter_5_4.SummonIndex] = 0
	end

	for iter_5_5, iter_5_6 in ipairs(var_5_4) do
		if iter_5_6 ~= 0 then
			var_5_0.SummonIndex = iter_5_6

			break
		end

		if iter_5_6 == var_0_6 then
			var_5_0.SummonIndex = 1
		end
	end

	local var_5_5 = 0

	if var_5_0.SummonIndex % 2 == 1 then
		var_5_5 = math.floor((var_5_0.SummonIndex + 1) / 2) * -50
	else
		var_5_5 = math.floor((var_5_0.SummonIndex + 1) / 2) * 30
	end

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y + var_5_5)
	var_5_0:updateHp(var_5_0:getHpLimit())
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()

	local var_5_6 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_6, var_5_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_5_0.summonMonsters_, var_5_0)

	if var_5_0.summonType_ == var_0_2.summonMonsterType.Monster then
		if arg_5_0.summonMonster_ then
			arg_5_0.summonMonster_:updateHp(0)
			arg_5_0.summonMonster_:die()
			var_0_0.table.removebyvalue(arg_5_0.summonMonsters_, arg_5_0.summonMonster_)
		end

		arg_5_0.summonMonster_ = var_5_0
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)

	if arg_6_1.rootID_ == arg_6_0:getEnergySkillID() and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		arg_6_0.isEnergyReady_ = true
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() and arg_7_0.isEnergyReady_ then
		arg_7_0.isEnergyReady_ = false

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_0 = {}

			for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
				if not iter_7_1:isDeath() and not iter_7_1:isAffected() then
					table.insert(var_7_0, iter_7_1)
				end
			end

			local var_7_1 = arg_7_0:createAttackUnits(var_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_7_2, iter_7_3 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end
end

return var_0_3
