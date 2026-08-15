local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhaoyun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 20010076
local var_0_10 = 10010062
local var_0_11 = 10000127
local var_0_12 = 10000139
local var_0_13 = 0.2
local var_0_14 = 15
local var_0_15 = 80010045
local var_0_16 = 0.3
local var_0_17 = 3
local var_0_18 = 80030045
local var_0_19 = 0.6
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001493

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.elementAddEnergy = false
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.baoji_ = false
	arg_2_0.summonMonsters_ = {}
	arg_2_0.elementNotBaojiCount = 0
end

function var_0_3.updateBaseInfo(arg_3_0)
	var_0_3.super.updateBaseInfo(arg_3_0)

	arg_3_0.isEnergyBuff_ = arg_3_0:isHasBuffByID(var_0_10)
end

function var_0_3.checkEnergySkill(arg_4_0)
	if arg_4_0.isEnergyBuff_ then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_4_0)
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = arg_5_0:getFrontSkill()
	local var_5_1 = var_0_6:buffOrb(var_5_0)

	if var_5_1 > 0 and arg_5_0:getSkillLevelByID(var_5_1) > 0 and arg_5_0.isEnergyBuff_ then
		if arg_5_0.baoji_ then
			return var_0_12
		else
			return var_5_1
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_5_0)
end

function var_0_3.popSkillByType(arg_6_0)
	if arg_6_0.isEnergyBuff_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_6_0:baojiPredict()
	end

	return var_0_3.super.popSkillByType(arg_6_0)
end

function var_0_3.baojiPredict(arg_7_0)
	local var_7_0 = arg_7_0:getNearestTarget()

	if not var_7_0 then
		return
	end

	local var_7_1 = arg_7_0:getADBaoJi() / (var_0_5.hujiaBaojiParam1 * math.max(var_7_0:getHuJia() - arg_7_0:getDHuJia(), 0) + var_0_5.hujiaBaojiParam2) + arg_7_0:getBothBaoji()
	local var_7_2 = math.min(1, var_7_1)

	if var_0_2.weightedChoise({
		var_7_2,
		1 - var_7_2
	}) == 1 then
		arg_7_0.baoji_ = true
	end

	if arg_7_0:hasElementEquipByID(var_0_21) then
		if arg_7_0.baoji_ == true then
			arg_7_0.elementNotBaojiCount = 0
		else
			arg_7_0.elementNotBaojiCount = arg_7_0.elementNotBaojiCount + 1
		end

		if arg_7_0.elementNotBaojiCount >= 2 then
			arg_7_0.baoji_ = true
			arg_7_0.elementNotBaojiCount = 0
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_1.skillID == var_0_12 and arg_8_3 ~= true then
		arg_8_4 = arg_8_4 * (arg_8_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_8_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_8_6 = arg_8_6 * (arg_8_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_8_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_8_3 = true
	elseif arg_8_1.skillID == var_0_11 and arg_8_3 == true then
		arg_8_4 = arg_8_4 / (arg_8_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_8_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_8_6 = arg_8_6 / (arg_8_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_8_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_8_3 = false
	end

	if arg_8_1.skillID == var_0_11 or arg_8_1.skillID == var_0_12 then
		arg_8_0.baoji_ = false
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.applySingleUnit(arg_9_0, arg_9_1)
	var_0_3.super.applySingleUnit(arg_9_0, arg_9_1)

	local var_9_0 = arg_9_1.target

	if var_9_0:isDeath() then
		return
	end

	if var_0_6:father(arg_9_1.skillID) ~= arg_9_0:getEnergySkillID() or var_9_0 == arg_9_0 then
		return
	end

	local var_9_1 = arg_9_0:getX()
	local var_9_2 = arg_9_0:getY()
	local var_9_3 = var_9_0:getX()
	local var_9_4 = var_9_0:getY()
	local var_9_5 = var_9_3 - var_9_1 > 0 and 120 or -120
	local var_9_6 = var_0_1.ctx.battle.adjustX(var_9_3 + var_9_5, arg_9_0)

	if var_9_0:avoidHeroMoveBehind() then
		local var_9_7 = var_9_0:getX() - var_9_5

		var_9_6 = var_0_1.ctx.battle.adjustX(var_9_7, arg_9_0)
		var_9_5 = 0
	end

	arg_9_0:pos(var_9_6, var_9_4 + 0.1)
	arg_9_0:flipX(var_9_5 > 0)

	arg_9_0.baoji_ = true
end

function var_0_3.playShanbi(arg_10_0, arg_10_1)
	var_0_3.super.playShanbi(arg_10_0, arg_10_1)

	if arg_10_0:isHasBuffByID(var_0_9) and not arg_10_0:isDeath() then
		local var_10_0 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) * var_0_13 + var_0_14

		arg_10_0:updateEnergyBy(var_10_0)
	end
end

function var_0_3.getShanBi(arg_11_0)
	local var_11_0 = var_0_3.super.getShanBi(arg_11_0)

	if arg_11_0.isSkinSkillOn_ and arg_11_0.skinSkillID_ == var_0_15 then
		var_11_0 = var_11_0 + arg_11_0:getAliveEnemyLevel() * var_0_16
	end

	return var_11_0
end

function var_0_3.getAD(arg_12_0)
	local var_12_0 = var_0_3.super.getAD(arg_12_0)

	if arg_12_0.isSkinSkillOn_ and arg_12_0.skinSkillID_ == var_0_15 then
		var_12_0 = var_12_0 + arg_12_0:getAliveEnemyLevel() * var_0_17
	end

	return var_12_0
end

function var_0_3.getAliveEnemyLevel(arg_13_0)
	local var_13_0 = 0

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			var_13_0 = iter_13_1:getLevel() + var_13_0
		end
	end

	return var_13_0
end

function var_0_3.toDoPerFrames(arg_14_0)
	if arg_14_0:isDeath() then
		return
	end

	if not arg_14_0.elementAddEnergy and var_0_1.ctx.battle.count % 10 == 1 and arg_14_0:hasElementEquipByID(var_0_21) then
		local var_14_0 = var_0_21
		local var_14_1 = var_0_20:battleAttr(var_14_0, arg_14_0:getElementEquipLevelByID(var_14_0))
		local var_14_2 = arg_14_0.hero_:getElementEquipActiveRate(var_14_0)

		arg_14_0:updateEnergyBy(var_14_1 * var_14_2)

		arg_14_0.elementAddEnergy = true
	end
end

function var_0_3.forceDie(arg_15_0)
	if arg_15_0.isSkinSkillOn_ and arg_15_0.skinSkillID_ == var_0_18 then
		local var_15_0 = var_0_6:summonMonster(var_0_18)

		if next(var_15_0) == nil then
			return
		end

		for iter_15_0, iter_15_1 in ipairs(var_15_0) do
			local var_15_1 = arg_15_0:getLevel()
			local var_15_2 = arg_15_0.hero_:getColor()
			local var_15_3 = arg_15_0:getX()
			local var_15_4 = var_0_1.ctx.battle.adjustX(var_15_3, arg_15_0)
			local var_15_5 = {
				x = var_15_4,
				y = arg_15_0:getY()
			}

			arg_15_0:setSummonMonsters(iter_15_1, var_15_1, var_15_2, var_15_5)
		end
	end

	var_0_3.super.forceDie(arg_15_0)
end

function var_0_3.setSummonMonsters(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_16_0 = arg_16_0:getSummonMonster()
	else
		local var_16_1 = var_0_4.new()

		var_16_1:populateWithTableID(arg_16_1)

		var_16_1.level_ = arg_16_2 or var_16_1.level_
		var_16_1.color_ = arg_16_3 or var_16_1.color_

		for iter_16_0, iter_16_1 in ipairs(var_16_1.skillLev_) do
			local var_16_2 = var_16_1:getSkillId(iter_16_0)
			local var_16_3 = arg_16_0.hero_:getSkillLevelByID(var_16_2)

			if var_16_3 and var_16_3 > 0 then
				var_16_1.skillLev_[iter_16_0] = var_16_3
			end
		end

		local var_16_4 = var_16_1:className()

		var_16_0 = var_0_1.ctx.battle.requireFighter(var_16_4).new({
			is_arena = arg_16_0.isInArena_
		})
		var_16_0.summoner = arg_16_0

		var_16_0:populateWithHero(var_16_1)
		var_16_0:initModels()
		var_16_0.fighterModel:initHeaderView(arg_16_0:getTeamType() - 1)

		var_16_0.fighterIndex = arg_16_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_16_0:setFormationDelay(0, 100)
	end

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		var_16_0:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
		var_16_0:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
	end

	var_16_0:setTeamType(arg_16_0:getTeamType())

	var_16_0.summoner = arg_16_0

	var_16_0.fighterModel:pos(arg_16_4.x, arg_16_4.y)
	var_16_0:updateHp(var_16_0:getHpLimit())
	var_16_0:resetHpLimit(arg_16_0:getHpLimit() * 0.7)
	var_16_0:getFighterModel():flipX(arg_16_0:getTeamType() == var_0_2.TeamType.B)
	var_16_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_16_0:born()
	var_16_0:setGlobalBuffs()

	local var_16_5 = var_16_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_16_5, var_16_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_16_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_16_0.summonMonsters_, var_16_0)
end

return var_0_3
