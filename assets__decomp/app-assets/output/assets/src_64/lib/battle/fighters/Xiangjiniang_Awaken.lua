local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiangjiniang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = 10000466
local var_0_8 = 1050
local var_0_9 = 3
local var_0_10 = {
	40010252
}
local var_0_11 = {
	40010253,
	40010254,
	40010255
}
local var_0_12 = 300
local var_0_13 = 64
local var_0_14 = 10420003
local var_0_15 = 40010857
local var_0_16 = 5
local var_0_17 = 600
local var_0_18 = 400
local var_0_19 = 50040111
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001500
local var_0_22 = 20

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyMonsters_ = {}
	arg_1_0.purpleMonsterOne_ = nil
	arg_1_0.purpleMonsterTwo_ = nil
	arg_1_0.energyCount_ = nil
	arg_1_0.energySummonCount_ = nil
	arg_1_0.blueSkillRegion_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	local var_2_0 = arg_2_1.skillID

	if var_0_4:father(var_2_0) == arg_2_0:getEnergySkillID() then
		arg_2_0.energySummonCount_ = var_0_13
	elseif var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_2_1 = var_0_4:summonMonster(var_2_0)
		local var_2_2 = 0
		local var_2_3 = arg_2_0:getSkillLevelByID(var_2_0)
		local var_2_4 = arg_2_0.hero_:getColor()
		local var_2_5 = arg_2_0:getFlipX() == true and -1 or 1

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			local var_2_6 = {
				x = arg_2_0:getX() + var_2_5 * 100,
				y = arg_2_0:getY() - var_2_2 * 40
			}

			var_2_2 = var_2_2 + 1

			if iter_2_0 == 1 then
				if arg_2_0.purpleMonsterOne_ then
					arg_2_0.purpleMonsterOne_:updateHp(0)
					arg_2_0.purpleMonsterOne_:die()

					arg_2_0.purpleMonsterOne_ = nil
				end

				arg_2_0.purpleMonsterOne_ = arg_2_0:setSummonMonsters(iter_2_1, var_2_3, var_2_4, var_2_6, false)
			elseif iter_2_0 == 2 then
				if arg_2_0.purpleMonsterTwo_ then
					arg_2_0.purpleMonsterTwo_:updateHp(0)
					arg_2_0.purpleMonsterTwo_:die()

					arg_2_0.purpleMonsterTwo_ = nil
				end

				arg_2_0.purpleMonsterTwo_ = arg_2_0:setSummonMonsters(iter_2_1, var_2_3, var_2_4, var_2_6, false)
			end
		end
	elseif var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_2_7 = {
			x = arg_2_1.target:getX(),
			y = arg_2_1.target:getY()
		}
		local var_2_8 = var_0_12
		local var_2_9 = var_0_1.ctx.battle.getSpine(var_2_0, "area", 1)

		var_2_9:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_2_9:pos(var_2_7.x, var_2_7.y)
		var_2_9:playRepeat()

		local var_2_10 = {
			posX = var_2_7.x,
			posY = var_2_7.y,
			time = var_2_8,
			effect = var_2_9
		}

		table.insert(arg_2_0.blueSkillRegion_, var_2_10)
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	for iter_3_0 = #arg_3_0.blueSkillRegion_, 1, -1 do
		local var_3_0 = arg_3_0.blueSkillRegion_[iter_3_0]

		var_3_0.time = var_3_0.time - 1

		if var_3_0.time <= 0 then
			for iter_3_1, iter_3_2 in ipairs(arg_3_0.selfTeam_) do
				if not iter_3_2:isDeath() and not iter_3_2:isAffected() and iter_3_2:isHasBuffByID(var_0_11[1]) and arg_3_0:isInBlueCircle(iter_3_2, var_3_0) then
					for iter_3_3, iter_3_4 in ipairs(var_0_11) do
						iter_3_2:removeBuffByID(iter_3_4)
					end
				end
			end

			var_3_0.effect:removeSelf()
			table.remove(arg_3_0.blueSkillRegion_, iter_3_0)
		end
	end

	if next(arg_3_0.blueSkillRegion_) and var_0_1.ctx.battle.count % 10 == 0 then
		for iter_3_5, iter_3_6 in ipairs(arg_3_0.blueSkillRegion_) do
			arg_3_0:removeBlueBuff(iter_3_6)
			arg_3_0:addBlueBuff(iter_3_6)
		end
	end

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.energySummonCount_ then
		arg_3_0.energySummonCount_ = arg_3_0.energySummonCount_ - 1

		if arg_3_0.energySummonCount_ <= 0 then
			local var_3_1 = var_0_4:summonMonster(arg_3_0:getEnergySkillID())

			if arg_3_0.isSkinSkillOn_ then
				var_3_1 = var_0_4:summonMonster(var_0_19)
			end

			local var_3_2 = 0
			local var_3_3 = arg_3_0:getFlipX() == true and -1 or 1
			local var_3_4 = arg_3_0:getSkillLevelByID(arg_3_0:getEnergySkillID())
			local var_3_5 = arg_3_0.hero_:getColor()

			for iter_3_7, iter_3_8 in ipairs(var_3_1) do
				local var_3_6 = {
					x = arg_3_0:getX() + var_3_3 * 100,
					y = arg_3_0:getY() - var_3_2 * 40
				}

				var_3_2 = var_3_2 + 1

				local var_3_7 = arg_3_0:setSummonMonsters(iter_3_8, var_3_4, var_3_5, var_3_6, true)

				var_3_7:setSummonAutoFight(true)

				var_3_7.skillLevelByID_[arg_3_0:getEnergySkillID()] = arg_3_0.skillLevelByColor_[var_0_2.SKILL_INDEX.Awake]
				var_3_7.skillLevelByColor_[var_0_2.SKILL_INDEX.Energy] = arg_3_0.skillLevelByColor_[var_0_2.SKILL_INDEX.Awake]

				if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
					var_3_7:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
					var_3_7:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
				end

				local var_3_8 = math.ceil(var_0_8 + var_0_9 * arg_3_0:getSkillLevelByID(arg_3_0:getEnergySkillID()))

				table.insert(arg_3_0.energyMonsters_, {
					fighter = var_3_7,
					count = var_3_8
				})
			end

			arg_3_0.energySummonCount_ = nil
		end
	end

	if next(arg_3_0.energyMonsters_) then
		for iter_3_9 = #arg_3_0.energyMonsters_, 1, -1 do
			local var_3_9 = arg_3_0.energyMonsters_[iter_3_9].fighter

			arg_3_0.energyMonsters_[iter_3_9].count = arg_3_0.energyMonsters_[iter_3_9].count - 1

			if var_3_9:isDeath() or arg_3_0.energyMonsters_[iter_3_9].count <= 0 then
				table.remove(arg_3_0.energyMonsters_, iter_3_9)

				if not var_3_9:isDeath() then
					var_3_9:updateHp(0)
					var_3_9:die()
				end
			end
		end
	end

	if not arg_3_0.extraSkillJudge then
		arg_3_0.extraSkillJudge = true
		arg_3_0.extraSkillLevel = arg_3_0.hero_:skillBook()[tostring(var_0_14)] or 0
	end

	if arg_3_0.isSkinSkillOn_ and not arg_3_0.addSkinEnergy then
		arg_3_0.addSkinEnergy = true

		if arg_3_0:getSummonType() == var_0_2.summonMonsterType.None then
			arg_3_0:updateEnergyBy(var_0_17)
		else
			arg_3_0:updateEnergyBy(var_0_18)
		end
	end
end

function var_0_3.removeBlueBuff(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1:isHasBuffByID(var_0_11[1]) and not arg_4_0:isInBlueCircle(iter_4_1, arg_4_1) then
			for iter_4_2, iter_4_3 in ipairs(var_0_11) do
				iter_4_1:removeBuffByID(iter_4_3)
			end
		end
	end
end

function var_0_3.addBlueBuff(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and not iter_5_1:isHasBuffByID(var_0_11[1]) and arg_5_0:isInBlueCircle(iter_5_1, arg_5_1) then
			iter_5_1:addBuffs(arg_5_0:newBuff(var_0_11, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))
		end
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_5.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_4 or arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setYongJiu()
		var_6_1:setIsHit(true)
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.isInBlueCircle(arg_7_0, arg_7_1, arg_7_2)
	if var_0_4:scope(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) * 0.5 >= math.abs(arg_7_1:getX() - arg_7_2.posX) then
		return true
	else
		return false
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and iter_8_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_8_0, iter_8_1)
		end
	end

	local var_8_1

	if next(var_8_0) then
		table.sort(var_8_0, function(arg_9_0, arg_9_1)
			return arg_9_0:getHp() / arg_9_0:getHpLimit() < arg_9_1:getHp() / arg_9_1:getHpLimit()
		end)

		for iter_8_2, iter_8_3 in ipairs(var_8_0) do
			if not iter_8_3:isHasBuffByID(unpack(var_0_10)) then
				var_8_1 = iter_8_3

				break
			end
		end
	end

	return {
		var_8_1
	}
end

function var_0_3.setSummonMonsters(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5)
	local var_10_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_10_0 = arg_10_0:getSummonMonster()
	else
		local var_10_1 = var_0_6.new()

		var_10_1:populateWithTableID(arg_10_1)

		var_10_1.level_ = arg_10_2 or var_10_1.level_
		var_10_1.color_ = arg_10_3 or var_10_1.color_

		if arg_10_5 then
			var_10_1.star_ = arg_10_0.hero_.star_
			var_10_1.equips_ = arg_10_0.hero_.equips_
			var_10_1.fumo_ = arg_10_0.hero_.fumo_
			var_10_1.practice_attr_ = arg_10_0.hero_.practice_attr_
			var_10_1.skill_book_ = arg_10_0.hero_.skill_book_
		end

		for iter_10_0, iter_10_1 in pairs(var_10_1.skillLev_) do
			var_10_1.skillLev_[iter_10_0] = arg_10_0.hero_.skillLev_[iter_10_0]
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
	var_10_0:updateHp(var_10_0:getHpLimit())
	var_10_0:getFighterModel():flipX(arg_10_0:getTeamType() == var_0_2.TeamType.B)
	var_10_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_10_0:born()
	var_10_0:setGlobalBuffs()

	if arg_10_0.extraSkillLevel > 0 then
		local var_10_3 = arg_10_0:newBuff({
			var_0_15
		}, var_10_0, arg_10_0:getEnergySkillID(), arg_10_0.extraSkillLevel)

		var_10_0:addBuffs(var_10_3)
	end

	local var_10_4 = var_10_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_10_4, var_10_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_10_0)
	table.insert(arg_10_0.summonMonsters_, var_10_0)
	var_0_1.ctx.battle.updateZorder()

	return var_10_0
end

function var_0_3.deathFeedback(arg_11_0, arg_11_1)
	if arg_11_0.purpleMonsterOne_ and arg_11_0.purpleMonsterOne_ == arg_11_1 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_11_0 = {
				arg_11_0.purpleMonsterOne_:getNearestTarget()
			}
			local var_11_1 = arg_11_0.purpleMonsterOne_:createAttackUnits(var_11_0, var_0_7)

			for iter_11_0, iter_11_1 in ipairs(var_11_1) do
				table.insert(arg_11_0.purpleMonsterOne_.moveAttackUnits_, iter_11_1)
				table.insert(arg_11_0.purpleMonsterOne_.records_.special_units, iter_11_1)
			end
		end

		arg_11_0.purpleMonsterOne_ = nil
	elseif arg_11_0.purpleMonsterTwo_ and arg_11_0.purpleMonsterTwo_ == arg_11_1 then
		arg_11_0.purpleMonsterTwo_ = nil
	end
end

function var_0_3.die(arg_12_0)
	var_0_3.super.die(arg_12_0)

	if next(arg_12_0.energyMonsters_) then
		for iter_12_0, iter_12_1 in ipairs(arg_12_0.energyMonsters_) do
			if not iter_12_1.fighter:isDeath() then
				iter_12_1.fighter:updateHp(0)
				iter_12_1.fighter:die()
			end
		end

		arg_12_0.energyMonsters_ = {}
	end

	if arg_12_0.purpleMonsterOne_ and not arg_12_0.purpleMonsterOne_:isDeath() then
		arg_12_0.purpleMonsterOne_:updateHp(0)
		arg_12_0.purpleMonsterOne_:die()

		arg_12_0.purpleMonsterOne_ = nil
	end

	if arg_12_0.purpleMonsterTwo_ and not arg_12_0.purpleMonsterTwo_:isDeath() then
		arg_12_0.purpleMonsterTwo_:updateHp(0)
		arg_12_0.purpleMonsterTwo_:die()

		arg_12_0.purpleMonsterTwo_ = nil
	end
end

function var_0_3.checkEnergySkill(arg_13_0)
	if #arg_13_0.energyMonsters_ >= var_0_16 then
		return false
	end

	return var_0_3.super.checkEnergySkill(arg_13_0)
end

function var_0_3.getShanBi(arg_14_0)
	local var_14_0 = 0

	if arg_14_0:hasElementEquipByID(var_0_21) then
		var_14_0 = arg_14_0:getSummonCount() * var_0_22
	end

	return arg_14_0:getAttrByType(var_0_2.AttributeType.SHANBI) + var_14_0
end

function var_0_3.getHurtMP(arg_15_0)
	local var_15_0 = 1

	if arg_15_0:hasElementEquipByID(var_0_21) then
		local var_15_1 = var_0_21
		local var_15_2 = var_0_20:battleAttr(var_15_1, arg_15_0:getElementEquipLevelByID(var_15_1))
		local var_15_3 = arg_15_0.hero_:getElementEquipActiveRate(var_15_1)
		local var_15_4 = arg_15_0:getSummonCount()

		var_15_0 = 1 + var_15_2 * var_15_3 * var_15_4
	end

	return arg_15_0:getAttrByType(var_0_2.AttributeType.GETMP) * var_15_0
end

function var_0_3.getEnergyRate(arg_16_0)
	local var_16_0 = 1

	if arg_16_0:hasElementEquipByID(var_0_21) then
		local var_16_1 = var_0_21
		local var_16_2 = var_0_20:battleAttr(var_16_1, arg_16_0:getElementEquipLevelByID(var_16_1))
		local var_16_3 = arg_16_0.hero_:getElementEquipActiveRate(var_16_1)
		local var_16_4 = arg_16_0:getSummonCount()

		var_16_0 = 1 + var_16_2 * var_16_3 * var_16_4
	end

	return arg_16_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE) * var_16_0
end

function var_0_3.getSummonCount(arg_17_0)
	local var_17_0 = 0

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.summonMonsters_) do
		if not iter_17_1:isDeath() then
			var_17_0 = var_17_0 + 1
		end
	end

	return var_17_0
end

return var_0_3
