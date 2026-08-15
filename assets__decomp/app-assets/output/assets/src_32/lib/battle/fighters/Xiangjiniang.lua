local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xiangjiniang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = 10000466
local var_0_8 = 300
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
local var_0_16 = 600
local var_0_17 = 400
local var_0_18 = 50030111
local var_0_19 = var_0_2.tables.elementEquip
local var_0_20 = 20001500
local var_0_21 = 20

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyMonster_ = nil
	arg_1_0.purpleMonsterOne_ = nil
	arg_1_0.purpleMonsterTwo_ = nil
	arg_1_0.energyCount_ = nil
	arg_1_0.energySummonCount_ = nil
	arg_1_0.blueSkillRegion_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
	arg_1_0.addSkinEnergy = false
	arg_1_0.summonMonsters_ = {}
end

function var_0_3.checkEnergySkill(arg_2_0)
	if arg_2_0:getSummonType() == var_0_2.summonMonsterType.Copy then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_2_0)
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_1.skillID

	if var_0_4:father(var_3_0) == arg_3_0:getEnergySkillID() then
		arg_3_0.energySummonCount_ = var_0_13
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_3_1 = var_0_4:summonMonster(var_3_0)
		local var_3_2 = 0
		local var_3_3 = arg_3_0:getSkillLevelByID(var_3_0)
		local var_3_4 = arg_3_0.hero_:getColor()
		local var_3_5 = arg_3_0:getFlipX() == true and -1 or 1

		for iter_3_0, iter_3_1 in ipairs(var_3_1) do
			local var_3_6 = {
				x = arg_3_0:getX() + var_3_5 * 100,
				y = arg_3_0:getY() - var_3_2 * 40
			}

			var_3_2 = var_3_2 + 1

			if iter_3_0 == 1 then
				if arg_3_0.purpleMonsterOne_ then
					arg_3_0.purpleMonsterOne_:updateHp(0)
					arg_3_0.purpleMonsterOne_:die()

					arg_3_0.purpleMonsterOne_ = nil
				end

				arg_3_0.purpleMonsterOne_ = arg_3_0:setSummonMonsters(iter_3_1, var_3_3, var_3_4, var_3_6, false)
			elseif iter_3_0 == 2 then
				if arg_3_0.purpleMonsterTwo_ then
					arg_3_0.purpleMonsterTwo_:updateHp(0)
					arg_3_0.purpleMonsterTwo_:die()

					arg_3_0.purpleMonsterTwo_ = nil
				end

				arg_3_0.purpleMonsterTwo_ = arg_3_0:setSummonMonsters(iter_3_1, var_3_3, var_3_4, var_3_6, false)
			end
		end
	elseif var_3_0 == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_3_7 = {
			x = arg_3_1.target:getX(),
			y = arg_3_1.target:getY()
		}
		local var_3_8 = var_0_12
		local var_3_9 = var_0_1.ctx.battle.getSpine(var_3_0, "area", 1)

		var_3_9:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_3_9:pos(var_3_7.x, var_3_7.y)
		var_3_9:playRepeat()

		local var_3_10 = {
			posX = var_3_7.x,
			posY = var_3_7.y,
			time = var_3_8,
			effect = var_3_9
		}

		table.insert(arg_3_0.blueSkillRegion_, var_3_10)
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	for iter_4_0 = #arg_4_0.blueSkillRegion_, 1, -1 do
		local var_4_0 = arg_4_0.blueSkillRegion_[iter_4_0]

		var_4_0.time = var_4_0.time - 1

		if var_4_0.time <= 0 then
			for iter_4_1, iter_4_2 in ipairs(arg_4_0.selfTeam_) do
				if not iter_4_2:isDeath() and not iter_4_2:isAffected() and iter_4_2:isHasBuffByID(var_0_11[1]) and arg_4_0:isInBlueCircle(iter_4_2, var_4_0) then
					for iter_4_3, iter_4_4 in ipairs(var_0_11) do
						iter_4_2:removeBuffByID(iter_4_4)
					end
				end
			end

			var_4_0.effect:removeSelf()
			table.remove(arg_4_0.blueSkillRegion_, iter_4_0)
		end
	end

	if next(arg_4_0.blueSkillRegion_) and var_0_1.ctx.battle.count % 10 == 0 then
		for iter_4_5, iter_4_6 in ipairs(arg_4_0.blueSkillRegion_) do
			arg_4_0:removeBlueBuff(iter_4_6)
			arg_4_0:addBlueBuff(iter_4_6)
		end
	end

	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0.energySummonCount_ then
		arg_4_0.energySummonCount_ = arg_4_0.energySummonCount_ - 1

		if arg_4_0.energySummonCount_ <= 0 then
			local var_4_1 = var_0_4:summonMonster(arg_4_0:getEnergySkillID())

			if arg_4_0.isSkinSkillOn_ then
				var_4_1 = var_0_4:summonMonster(var_0_18)
			end

			local var_4_2 = 0
			local var_4_3 = arg_4_0:getFlipX() == true and -1 or 1
			local var_4_4 = arg_4_0:getSkillLevelByID(arg_4_0:getEnergySkillID())
			local var_4_5 = arg_4_0.hero_:getColor()

			for iter_4_7, iter_4_8 in ipairs(var_4_1) do
				local var_4_6 = {
					x = arg_4_0:getX() + var_4_3 * 100,
					y = arg_4_0:getY() - var_4_2 * 40
				}

				var_4_2 = var_4_2 + 1

				if arg_4_0.energyMonster_ then
					arg_4_0.energyMonster_:updateHp(0)
					arg_4_0.energyMonster_:die()

					arg_4_0.energyMonster_ = nil
				end

				arg_4_0.energyMonster_ = arg_4_0:setSummonMonsters(iter_4_8, var_4_4, var_4_5, var_4_6, true)

				if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
					arg_4_0.energyMonster_:getFighterModel():setMaskColor(cc.c4f(1, 0.88, 0.46, 1))
					arg_4_0.energyMonster_:setDefaultMaskColor(cc.c4f(1, 0.88, 0.46, 1))
				end

				arg_4_0.energyCount_ = math.ceil(var_0_8 + var_0_9 * arg_4_0:getSkillLevelByID(arg_4_0:getEnergySkillID()))
			end

			arg_4_0.energySummonCount_ = nil
		end
	end

	if arg_4_0.energyCount_ then
		if not arg_4_0.energyMonster_ then
			arg_4_0.energyCount_ = nil
		else
			arg_4_0.energyCount_ = arg_4_0.energyCount_ - 1

			if arg_4_0.energyCount_ <= 0 then
				arg_4_0.energyCount_ = nil

				if arg_4_0.energyMonster_ and not arg_4_0.energyMonster_:isDeath() then
					arg_4_0.energyMonster_:updateHp(0)
					arg_4_0.energyMonster_:die()
				end
			end
		end
	end

	if not arg_4_0.extraSkillJudge then
		arg_4_0.extraSkillJudge = true
		arg_4_0.extraSkillLevel = arg_4_0.hero_:skillBook()[tostring(var_0_14)] or 0
	end

	if arg_4_0.isSkinSkillOn_ and not arg_4_0.addSkinEnergy then
		arg_4_0.addSkinEnergy = true

		if arg_4_0:getSummonType() == var_0_2.summonMonsterType.None then
			arg_4_0:updateEnergyBy(var_0_16)
		else
			arg_4_0:updateEnergyBy(var_0_17)
		end
	end
end

function var_0_3.removeBlueBuff(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1:isHasBuffByID(var_0_11[1]) and not arg_5_0:isInBlueCircle(iter_5_1, arg_5_1) then
			for iter_5_2, iter_5_3 in ipairs(var_0_11) do
				iter_5_1:removeBuffByID(iter_5_3)
			end
		end
	end
end

function var_0_3.addBlueBuff(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and not iter_6_1:isHasBuffByID(var_0_11[1]) and arg_6_0:isInBlueCircle(iter_6_1, arg_6_1) then
			iter_6_1:addBuffs(arg_6_0:newBuff(var_0_11, iter_6_1, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))
		end
	end
end

function var_0_3.newBuff(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		local var_7_1 = var_0_5.new({
			tableID = iter_7_1,
			start = var_0_1.ctx.battle.count,
			level = arg_7_4 or arg_7_0:getSkillLevelByID(arg_7_3),
			skillID = arg_7_3,
			fighter = arg_7_0,
			target = arg_7_2
		})

		var_7_1:setYongJiu()
		var_7_1:setIsHit(true)
		var_7_1:setDirection(arg_7_0:getFighterModel():getFlipX())
		table.insert(var_7_0, var_7_1)
	end

	return var_7_0
end

function var_0_3.isInBlueCircle(arg_8_0, arg_8_1, arg_8_2)
	if var_0_4:scope(arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) * 0.5 >= math.abs(arg_8_1:getX() - arg_8_2.posX) then
		return true
	else
		return false
	end
end

function var_0_3.selectTargetByTypeD1(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = {}

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_9_0, iter_9_1)
		end
	end

	local var_9_1

	if next(var_9_0) then
		table.sort(var_9_0, function(arg_10_0, arg_10_1)
			return arg_10_0:getHp() / arg_10_0:getHpLimit() < arg_10_1:getHp() / arg_10_1:getHpLimit()
		end)

		for iter_9_2, iter_9_3 in ipairs(var_9_0) do
			if not iter_9_3:isHasBuffByID(unpack(var_0_10)) then
				var_9_1 = iter_9_3

				break
			end
		end
	end

	return {
		var_9_1
	}
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4, arg_11_5)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0 = arg_11_0:getSummonMonster()
	else
		local var_11_1 = var_0_6.new()

		var_11_1:populateWithTableID(arg_11_1)

		var_11_1.level_ = arg_11_2 or var_11_1.level_
		var_11_1.color_ = arg_11_3 or var_11_1.color_

		if arg_11_5 then
			var_11_1.star_ = arg_11_0.hero_.star_
			var_11_1.equips_ = arg_11_0.hero_.equips_
			var_11_1.fumo_ = arg_11_0.hero_.fumo_
			var_11_1.practice_attr_ = arg_11_0.hero_.practice_attr_
			var_11_1.skill_book_ = arg_11_0.hero_.skill_book_
		end

		for iter_11_0, iter_11_1 in pairs(var_11_1.skillLev_) do
			var_11_1.skillLev_[iter_11_0] = arg_11_0.hero_.skillLev_[iter_11_0]
		end

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

	if arg_11_0.extraSkillLevel > 0 then
		local var_11_3 = arg_11_0:newBuff({
			var_0_15
		}, var_11_0, arg_11_0:getEnergySkillID(), arg_11_0.extraSkillLevel)

		var_11_0:addBuffs(var_11_3)
	end

	local var_11_4 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_4, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_11_0.summonMonsters_, var_11_0)

	return var_11_0
end

function var_0_3.deathFeedback(arg_12_0, arg_12_1)
	if arg_12_0.energyMonster_ and arg_12_0.energyMonster_ == arg_12_1 then
		arg_12_0.energyMonster_ = nil
	elseif arg_12_0.purpleMonsterOne_ and arg_12_0.purpleMonsterOne_ == arg_12_1 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_12_0 = {
				arg_12_0.purpleMonsterOne_:getNearestTarget()
			}
			local var_12_1 = arg_12_0.purpleMonsterOne_:createAttackUnits(var_12_0, var_0_7)

			for iter_12_0, iter_12_1 in ipairs(var_12_1) do
				table.insert(arg_12_0.purpleMonsterOne_.moveAttackUnits_, iter_12_1)
				table.insert(arg_12_0.purpleMonsterOne_.records_.special_units, iter_12_1)
			end
		end

		arg_12_0.purpleMonsterOne_ = nil
	elseif arg_12_0.purpleMonsterTwo_ and arg_12_0.purpleMonsterTwo_ == arg_12_1 then
		arg_12_0.purpleMonsterTwo_ = nil
	end
end

function var_0_3.die(arg_13_0)
	var_0_3.super.die(arg_13_0)

	if arg_13_0.energyMonster_ and not arg_13_0.energyMonster_:isDeath() then
		arg_13_0.energyMonster_:updateHp(0)
		arg_13_0.energyMonster_:die()

		arg_13_0.energyMonster_ = nil
	end

	if arg_13_0.purpleMonsterOne_ and not arg_13_0.purpleMonsterOne_:isDeath() then
		arg_13_0.purpleMonsterOne_:updateHp(0)
		arg_13_0.purpleMonsterOne_:die()

		arg_13_0.purpleMonsterOne_ = nil
	end

	if arg_13_0.purpleMonsterTwo_ and not arg_13_0.purpleMonsterTwo_:isDeath() then
		arg_13_0.purpleMonsterTwo_:updateHp(0)
		arg_13_0.purpleMonsterTwo_:die()

		arg_13_0.purpleMonsterTwo_ = nil
	end
end

function var_0_3.getShanBi(arg_14_0)
	local var_14_0 = 0

	if arg_14_0:hasElementEquipByID(var_0_20) then
		var_14_0 = arg_14_0:getSummonCount() * var_0_21
	end

	return arg_14_0:getAttrByType(var_0_2.AttributeType.SHANBI) + var_14_0
end

function var_0_3.getHurtMP(arg_15_0)
	local var_15_0 = 1

	if arg_15_0:hasElementEquipByID(var_0_20) then
		local var_15_1 = var_0_20
		local var_15_2 = var_0_19:battleAttr(var_15_1, arg_15_0:getElementEquipLevelByID(var_15_1))
		local var_15_3 = arg_15_0.hero_:getElementEquipActiveRate(var_15_1)
		local var_15_4 = arg_15_0:getSummonCount()

		var_15_0 = 1 + var_15_2 * var_15_3 * var_15_4
	end

	return arg_15_0:getAttrByType(var_0_2.AttributeType.GETMP) * var_15_0
end

function var_0_3.getEnergyRate(arg_16_0)
	local var_16_0 = 1

	if arg_16_0:hasElementEquipByID(var_0_20) then
		local var_16_1 = var_0_20
		local var_16_2 = var_0_19:battleAttr(var_16_1, arg_16_0:getElementEquipLevelByID(var_16_1))
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
