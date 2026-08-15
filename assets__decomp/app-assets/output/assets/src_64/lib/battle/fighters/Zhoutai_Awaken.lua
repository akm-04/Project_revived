local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhoutai", var_0_1.ctx.battle.requireFighter("Zhoutai"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0.1
local var_0_7 = 10000954
local var_0_8 = 10001305
local var_0_9 = 80010057
local var_0_10 = math.floor
local var_0_11 = 1.25
local var_0_12 = 0.8
local var_0_13 = 10

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeCollectHp_ = 0
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.die(arg_2_0)
	if next(arg_2_0.summonMonsters_) then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.summonMonsters_) do
			if not iter_2_1:isDeath() then
				iter_2_1:updateHp(0)
				iter_2_1:die()
			end
		end
	end

	var_0_3.super.die(arg_2_0)
end

function var_0_3.updateHp(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0:getHp()

	var_0_3.super.updateHp(arg_3_0, arg_3_1, arg_3_2)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_3_0:isDeath() then
		local var_3_1 = arg_3_0:getHp()

		if var_3_1 < var_3_0 then
			arg_3_0.awakeCollectHp_ = arg_3_0.awakeCollectHp_ + var_3_0 - var_3_1

			if arg_3_0.awakeCollectHp_ >= arg_3_0:getHpLimit() * var_0_6 then
				for iter_3_0 = 1, var_0_10(arg_3_0.awakeCollectHp_ / (arg_3_0:getHpLimit() * var_0_6)) do
					local var_3_2 = arg_3_0:createAttackUnits({
						arg_3_0
					}, var_0_7)

					for iter_3_1, iter_3_2 in ipairs(var_3_2) do
						table.insert(arg_3_0.moveAttackUnits_, iter_3_2)
						table.insert(arg_3_0.records_.special_units, iter_3_2)
					end
				end

				arg_3_0.awakeCollectHp_ = arg_3_0.awakeCollectHp_ % (arg_3_0:getHpLimit() * var_0_6)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_7 then
		local var_4_0 = {}

		if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_9 then
			var_4_0 = var_0_5:summonMonster(var_0_8)
		else
			var_4_0 = var_0_5:summonMonster(var_0_7)
		end

		if next(var_4_0) == nil then
			return
		end

		for iter_4_0, iter_4_1 in ipairs(var_4_0) do
			local var_4_1 = arg_4_0:getSkillLevelByID(arg_4_1.skillID)
			local var_4_2 = arg_4_0.hero_:getColor()
			local var_4_3 = arg_4_0:getFlipX() and arg_4_0:getX() - 75 or arg_4_0:getX() + 75
			local var_4_4 = var_0_1.ctx.battle.adjustX(var_4_3, arg_4_0)
			local var_4_5 = {
				x = var_4_4,
				y = arg_4_0:getY() - 150 + 100 * iter_4_0
			}

			arg_4_0:setSummonMonsters(iter_4_1, var_4_1, var_4_2, var_4_5)
		end
	elseif arg_4_1.skillID == 10000953 then
		-- block empty
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	if arg_5_0:getSummonCount() >= var_0_13 then
		return
	end

	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_0 = arg_5_0:getSummonMonster()
	else
		local var_5_1 = var_0_4.new()

		var_5_1:populateWithTableID(arg_5_1)

		var_5_1.level_ = arg_5_2 or var_5_1.level_
		var_5_1.color_ = arg_5_3 or var_5_1.color_

		for iter_5_0, iter_5_1 in ipairs(var_5_1.skillLev_) do
			local var_5_2 = var_5_1:getSkillId(iter_5_0)
			local var_5_3 = arg_5_0.hero_:getSkillLevelByID(var_5_2)

			if var_5_3 and var_5_3 > 0 then
				var_5_1.skillLev_[iter_5_0] = var_5_3
			end
		end

		local var_5_4 = var_5_1:className()

		var_5_0 = var_0_1.ctx.battle.requireFighter(var_5_4).new({
			is_arena = arg_5_0.isInArena_
		})

		var_5_0:populateWithHero(var_5_1)
		var_5_0:initModels()
		var_5_0.fighterModel:initHeaderView(arg_5_0:getTeamType() - 1)

		var_5_0.fighterIndex = arg_5_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_5_0:setFormationDelay(0, 100)
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_5_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_5_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_5_0:setTeamType(arg_5_0:getTeamType())

	var_5_0.summoner = arg_5_0

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y)
	var_5_0:updateHp(var_5_0:getHpLimit())
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()

	local var_5_5 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_5, var_5_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_5_0.summonMonsters_, var_5_0)
end

function var_0_3.getHujia(arg_6_0)
	local var_6_0 = var_0_3.super.getHuJia(arg_6_0)
	local var_6_1 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_6_2 = arg_6_0:getSummonCount()

	return var_6_0 + var_6_1 * var_0_11 * var_6_2
end

function var_0_3.getMoKang(arg_7_0)
	local var_7_0 = var_0_3.super.getMoKang(arg_7_0)
	local var_7_1 = arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)
	local var_7_2 = arg_7_0:getSummonCount()

	return var_7_0 + var_7_1 * var_0_12 * var_7_2
end

function var_0_3.getSummonCount(arg_8_0)
	local var_8_0 = 0

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.summonMonsters_) do
		if not iter_8_1:isDeath() then
			var_8_0 = var_8_0 + 1
		end
	end

	return var_8_0
end

return var_0_3
