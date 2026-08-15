local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangwan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = {
	80000258,
	80000259
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyMonsterYin_ = nil
	arg_1_0.energyMonsterYang_ = nil
	arg_1_0.isEnergyBuff_ = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if var_0_1.ctx.battle.count == 1 then
		arg_2_0.fighterModel:setVisible(true)
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if arg_3_1.skillID == arg_3_0:getEnergySkillID() then
		local var_3_0 = 0
		local var_3_1 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_3_2 = arg_3_0.hero_:getColor()
		local var_3_3 = arg_3_0:getFlipX() == true and 1 or -1

		for iter_3_0, iter_3_1 in ipairs(var_0_8) do
			local var_3_4 = iter_3_0 == 1 and var_3_3 or var_3_3 * -1
			local var_3_5 = {
				x = arg_3_0:getX() + 100 * var_3_4,
				y = arg_3_0:getY() - var_3_0 * 40
			}

			var_3_0 = var_3_0 + 1

			if iter_3_0 == 1 then
				arg_3_0.energyMonsterYin_ = arg_3_0:setSummonMonsters(iter_3_1, var_3_1, var_3_2, var_3_5, true)
			else
				arg_3_0.energyMonsterYang_ = arg_3_0:setSummonMonsters(iter_3_1, var_3_1, var_3_2, var_3_5, true)
			end
		end

		arg_3_0.isEnergyBuff_ = true

		arg_3_0.fighterModel:setVisible(false)
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		if arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() then
			arg_3_0:purpleRemoveBuff(arg_3_1.target, true)
		else
			arg_3_0:purpleRemoveBuff(arg_3_1.target, false)
		end
	end
end

function var_0_3.checkEnergySkill(arg_4_0)
	if arg_4_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_4_0)
	end
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	if arg_5_0.isEnergyBuff_ then
		if arg_5_1 == arg_5_0.energyMonsterYin_ then
			if not arg_5_0.energyMonsterYang_ then
				arg_5_0:energyOut()
			end

			arg_5_0.energyMonsterYin_ = nil
		elseif arg_5_1 == arg_5_0.energyMonsterYang_ then
			if not arg_5_0.energyMonsterYin_ then
				arg_5_0:energyOut()
			end

			arg_5_0.energyMonsterYang_ = nil
		end
	end
end

function var_0_3.energyOut(arg_6_0)
	arg_6_0.isEnergyBuff_ = false

	arg_6_0.fighterModel:setVisible(true)
	arg_6_0:playAttack(7)
end

function var_0_3.isAffected(arg_7_0)
	if arg_7_0.isEnergyBuff_ then
		return true
	else
		return var_0_3.super.isAffected(arg_7_0)
	end
end

function var_0_3.canAttack(arg_8_0)
	if arg_8_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.canAttack(arg_8_0)
	end
end

function var_0_3.purpleRemoveBuff(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1:getBuffs()
	local var_9_1

	if arg_9_2 then
		var_9_1 = var_0_2.BuffForm.GAIN
	else
		var_9_1 = var_0_2.BuffForm.DEBUFF
	end

	for iter_9_0, iter_9_1 in ipairs(var_9_0) do
		local var_9_2 = iter_9_1:getTableID()

		if var_0_5:buffForm(var_9_2) == var_9_1 then
			arg_9_1:removeBuffByID(var_9_2)
		end
	end
end

function var_0_3.setSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	local var_10_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_10_0 = arg_10_0:getSummonMonster()
	else
		local var_10_1 = var_0_7.new()

		var_10_1:populateWithTableID(arg_10_1)

		var_10_1.level_ = arg_10_2 or var_10_1.level_
		var_10_1.color_ = arg_10_3 or var_10_1.color_

		if arg_10_5 then
			var_10_1.star_ = arg_10_0.hero_.star_ or 3
			var_10_1.equips_ = arg_10_0.hero_.equips_ or {
				0,
				1,
				1,
				1,
				1,
				1
			}
			var_10_1.fumo_ = arg_10_0.hero_.fumo_ or {
				0,
				0,
				0,
				0,
				0,
				0
			}
			var_10_1.practice_attr_ = arg_10_0.hero_.practice_attr_ or {}
			var_10_1.skill_book_ = arg_10_0.hero_.skill_book_ or {}
		end

		for iter_10_0, iter_10_1 in pairs(var_10_1.skillLev_) do
			var_10_1.skillLev_[iter_10_0] = arg_10_0.hero_.skillLev_[iter_10_0] or 1
		end

		local var_10_2 = var_10_1:className()

		var_10_0 = var_0_1.ctx.battle.requireFighter(var_10_2).new({
			is_arena = arg_10_0.isInArena_
		})

		var_10_0:populateWithHero(var_10_1)
		var_10_0:initModels()
		var_10_0.fighterModel:initHeaderView(arg_10_0:getTeamType() - 1)

		var_10_0.fighterIndex = arg_10_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_10_0:setFormationDelay(0, 100)
	end

	var_10_0:setTeamType(arg_10_0:getTeamType())

	var_10_0.summoner = arg_10_0

	var_10_0.fighterModel:pos(arg_10_4.x, arg_10_4.y)
	var_10_0:updateHp(arg_10_0:getHp() * 0.5)
	var_10_0:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
	var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_10_0:born()
	var_10_0:setGlobalBuffs()
	var_10_0:playAttack(5)

	local var_10_3 = var_10_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_10_3, var_10_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_10_0)
	var_0_1.ctx.battle.updateZorder()

	return var_10_0
end

function var_0_3.selectTargetByTypeD1(arg_11_0, arg_11_1, arg_11_2)
	return arg_11_0:choseTarget(false)
end

function var_0_3.selectTargetByTypeD2(arg_12_0, arg_12_1, arg_12_2)
	return arg_12_0:choseTarget(true)
end

function var_0_3.choseTarget(arg_13_0, arg_13_1)
	local var_13_0

	if arg_13_1 then
		var_13_0 = arg_13_0.selfTeam_
	else
		var_13_0 = arg_13_0.targetTeam_
	end

	local var_13_1
	local var_13_2

	for iter_13_0, iter_13_1 in ipairs(var_13_0) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and (not var_13_2 or var_13_2 < iter_13_1.harms) then
			var_13_1 = iter_13_1
			var_13_2 = iter_13_1.harms
		end
	end

	return {
		var_13_1
	}
end

return var_0_3
