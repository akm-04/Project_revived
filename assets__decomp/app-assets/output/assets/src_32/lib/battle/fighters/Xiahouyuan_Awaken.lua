local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiahouyuan", var_0_1.ctx.battle.requireFighter("Xiahouyuan"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.skill

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeMonster_ = nil
	arg_1_0.isCreateGun_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		if arg_2_0.awakeMonster_ and not arg_2_0.awakeMonster_:isDeath() then
			arg_2_0.awakeMonster_:updateHp(0)
			arg_2_0.awakeMonster_:die()
		end

		return
	end

	if not arg_2_0.isCreateGun_ then
		arg_2_0.isCreateGun_ = true

		arg_2_0:summonMonster()
	end

	if arg_2_0.awakeMonster_ and next(arg_2_0.awakeMonster_) then
		arg_2_0:checkMonsterPos()
	end
end

function var_0_3.checkMonsterPos(arg_3_0)
	local var_3_0 = arg_3_0:getFlipX() == true and -1 or 1
	local var_3_1 = arg_3_0:getX() + var_3_0 * 100
	local var_3_2 = arg_3_0:getY()

	if arg_3_0.awakeMonster_:getX() ~= var_3_1 or arg_3_0.awakeMonster_:getY() ~= var_3_2 then
		arg_3_0.awakeMonster_:pos(var_3_1, var_3_2)
	end
end

function var_0_3.summonMonster(arg_4_0)
	local var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake)
	local var_4_1 = var_0_5:summonMonster(var_4_0)

	if next(var_4_1) == nil then
		return
	end

	for iter_4_0, iter_4_1 in ipairs(var_4_1) do
		local var_4_2 = arg_4_0:getSkillLevelByID(var_4_0)
		local var_4_3 = arg_4_0.hero_:getColor()
		local var_4_4 = arg_4_0:getFlipX() == true and -1 or 1
		local var_4_5 = arg_4_0:getX() + var_4_4 * 100
		local var_4_6 = {
			x = var_4_5,
			y = arg_4_0:getY()
		}

		arg_4_0.awakeMonster_ = arg_4_0:setSummonMonsters(iter_4_1, var_4_2, var_4_3, var_4_6)
	end
end

function var_0_3.setSummonMonsters(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_5_0 = arg_5_0:getSummonMonster()
	else
		local var_5_1 = var_0_4.new()

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

	var_5_0.fighterModel:pos(arg_5_4.x, arg_5_4.y)
	var_5_0:getFighterModel():flipX(arg_5_0:getTeamType() == var_0_2.TeamType.B)
	var_5_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_5_0:born()
	var_5_0:setGlobalBuffs()
	var_5_0:updateHp(var_5_0:getHpLimit())

	local var_5_4 = var_5_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_5_4, var_5_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_5_0)
	var_0_1.ctx.battle.updateZorder()

	return var_5_0
end

function var_0_3.checkHeroNum(arg_6_0)
	var_0_3.super.checkHeroNum(arg_6_0)

	if arg_6_0.awakeMonster_ then
		arg_6_0.awakeMonster_:setSkinType(arg_6_0.skinStrengthNum_, arg_6_0.skinWiseNum_, arg_6_0.skinAgileNum_)
	end
end

return var_0_3
