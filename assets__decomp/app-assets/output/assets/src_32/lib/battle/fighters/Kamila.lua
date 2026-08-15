local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Kamila", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.objectBook
local var_0_10 = math.abs
local var_0_11 = math.min
local var_0_12 = 40011134
local var_0_13 = 10001030
local var_0_14 = 0.35
local var_0_15 = 10001034
local var_0_16 = 10001033
local var_0_17 = 20070006
local var_0_18 = 8
local var_0_19 = 40011135
local var_0_20 = 40011136
local var_0_21 = 40012066
local var_0_22 = 80010184
local var_0_23 = 50010184
local var_0_24 = 20010184
local var_0_25 = 30010184
local var_0_26 = 40010184
local var_0_27 = 10001936
local var_0_28 = 10001933
local var_0_29 = 10001934
local var_0_30 = 10001935
local var_0_31 = var_0_2.tables.elementEquip
local var_0_32 = 20001439
local var_0_33 = 10002092
local var_0_34 = 40012235
local var_0_35 = 40012236

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.summonMonsters_ = {}
	arg_2_0.batNum = 0
	arg_2_0.extraSkillJudge = false
	arg_2_0.extraSkillLevel = 0
	arg_2_0.addBaojiLimitRate = 0
	arg_2_0.addBaojiCount = 0
	arg_2_0.cureBuffLev = 0
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.isSkinSkillOn_ then
		arg_3_0.EnergySkillID = var_0_27
		arg_3_0.GreenSkillID = var_0_28
		arg_3_0.BlueSkillID = var_0_29
		arg_3_0.PurpleSkillID = var_0_30
	else
		arg_3_0.EnergySkillID = var_0_23
		arg_3_0.GreenSkillID = var_0_24
		arg_3_0.BlueSkillID = var_0_25
		arg_3_0.PurpleSkillID = var_0_26
	end
end

function var_0_3.die(arg_4_0)
	if next(arg_4_0.summonMonsters_) then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.summonMonsters_) do
			if not iter_4_1:isDeath() then
				iter_4_1:updateHp(0)
				iter_4_1:die()
			end
		end
	end

	var_0_3.super.die(arg_4_0)
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	var_0_3.super.deathFeedback(arg_5_0, arg_5_1)

	if arg_5_1.hero_:getTableID() == var_0_8:summonMonster(arg_5_0.PurpleSkillID)[1] and arg_5_1:getTeamType() == arg_5_0:getTeamType() then
		arg_5_0.batNum = arg_5_0.batNum - 1
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_0.extraSkillLevel > 0 and arg_6_1:getTableID() == var_0_19 or arg_6_1:getTableID() == var_0_20 then
		arg_6_0.addBaojiCount = arg_6_0.addBaojiCount + 1
	end
end

function var_0_3.getAPBaoJi(arg_7_0)
	local var_7_0 = var_0_3.super.getAPBaoJi(arg_7_0)

	if arg_7_0.extraSkillLevel > 0 then
		var_7_0 = var_7_0 + math.min(arg_7_0.addBaojiCount, var_7_0 * arg_7_0.addBaojiLimitRate)
	end

	return var_7_0
end

function var_0_3.getADBaoJi(arg_8_0)
	local var_8_0 = var_0_3.super.getADBaoJi(arg_8_0)

	if arg_8_0.extraSkillLevel > 0 then
		var_8_0 = var_8_0 + math.min(arg_8_0.addBaojiCount, var_8_0 * arg_8_0.addBaojiLimitRate)
	end

	return var_8_0
end

function var_0_3.toDoPerFrames(arg_9_0)
	if arg_9_0:isDeath() then
		return
	end

	if not arg_9_0.extraSkillJudge then
		arg_9_0.extraSkillJudge = true
		arg_9_0.extraSkillLevel = arg_9_0.hero_:skillBook()[tostring(var_0_17)] or 0
		arg_9_0.addBaojiLimitRate = arg_9_0.extraSkillLevel * 0.08
	end

	if arg_9_0:isHasBuffByID(var_0_12) then
		local var_9_0 = true

		if arg_9_0.summonMonsters_ and next(arg_9_0.summonMonsters_) then
			for iter_9_0, iter_9_1 in ipairs(arg_9_0.summonMonsters_) do
				if not iter_9_1:isDeath() then
					var_9_0 = false

					break
				end
			end
		end

		if var_9_0 then
			arg_9_0:removeBuffByID(var_0_12)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_9_1 = arg_9_0:createAttackUnits({
					arg_9_0
				}, var_0_13)

				for iter_9_2, iter_9_3 in ipairs(var_9_1) do
					table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
					table.insert(arg_9_0.records_.special_units, iter_9_3)
				end
			end
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_9_4, iter_9_5 in ipairs(arg_9_0:getInfoByKey("harm_info")) do
			local var_9_2 = iter_9_5.harm
			local var_9_3 = iter_9_5.target

			if iter_9_5.isBaoji and var_9_2 > 0 and not var_9_3:isDeath() and var_9_3:getTeamType() == arg_9_0:getTeamType() and var_9_3:getSummonType() == arg_9_0:getSummonType() then
				local var_9_4 = arg_9_0:createAttackUnits({
					var_9_3
				}, arg_9_0.BlueSkillID)

				for iter_9_6, iter_9_7 in ipairs(var_9_4) do
					table.insert(arg_9_0.moveAttackUnits_, iter_9_7)
					table.insert(arg_9_0.records_.special_units, iter_9_7)
				end
			end
		end
	end

	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_22 and var_0_1.ctx.battle.count % 30 == 1 then
		local var_9_5 = 0

		if arg_9_0.summonMonsters_ and next(arg_9_0.summonMonsters_) then
			for iter_9_8, iter_9_9 in ipairs(arg_9_0.summonMonsters_) do
				if not iter_9_9:isDeath() then
					var_9_5 = var_9_5 + 1
				end
			end
		end

		if var_9_5 ~= arg_9_0.cureBuffLev then
			arg_9_0:removeBuffByID(var_0_21)

			local var_9_6 = arg_9_0:createNewBuffs({
				var_0_21
			}, arg_9_0, var_0_22, var_9_5)

			arg_9_0:addBuffs(var_9_6)
		end

		arg_9_0.cureBuffLev = var_9_5
	end
end

function var_0_3.applySingleUnit(arg_10_0, arg_10_1)
	var_0_3.super.applySingleUnit(arg_10_0, arg_10_1)

	local var_10_0 = arg_10_1.skillID

	if var_10_0 == arg_10_0.EnergySkillID then
		local var_10_1 = var_0_8:summonMonster(var_10_0)

		if next(var_10_1) == nil then
			return
		end

		for iter_10_0, iter_10_1 in ipairs(var_10_1) do
			local var_10_2 = arg_10_0:getSkillLevelByID(var_10_0)
			local var_10_3 = arg_10_0.hero_:getColor()
			local var_10_4 = arg_10_0:getFlipX() and arg_10_0:getX() - 75 or arg_10_0:getX() + 75
			local var_10_5 = var_0_1.ctx.battle.adjustX(var_10_4, arg_10_0)
			local var_10_6 = {
				x = var_10_5,
				y = arg_10_0:getY() - 150 + 60 * iter_10_0
			}

			arg_10_0:setSummonMonsters(iter_10_1, var_10_2, var_10_3, var_10_6)
		end
	elseif var_10_0 == arg_10_0.PurpleSkillID then
		local var_10_7 = var_0_8:summonMonster(arg_10_0.PurpleSkillID)

		if next(var_10_7) == nil then
			return
		end

		if arg_10_0.batNum < var_0_18 then
			for iter_10_2, iter_10_3 in ipairs(var_10_7) do
				local var_10_8 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
				local var_10_9 = arg_10_0.hero_:getColor()
				local var_10_10 = arg_10_0:getFlipX() and arg_10_0:getX() - 75 or arg_10_0:getX() + 75
				local var_10_11 = var_0_1.ctx.battle.adjustX(var_10_10, arg_10_0)
				local var_10_12 = {
					x = var_10_11,
					y = arg_10_0:getY() - 150 + 120 * iter_10_2
				}

				arg_10_0:setSummonMonsters(iter_10_3, var_10_8, var_10_9, var_10_12)
			end

			arg_10_0.batNum = arg_10_0.batNum + 1
		end
	elseif var_10_0 == arg_10_0.GreenSkillID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_10_1.target:getTeamType() == arg_10_0:getTeamType() then
			local var_10_13 = arg_10_0:createAttackUnits({
				arg_10_1.target
			}, var_0_15)

			for iter_10_4, iter_10_5 in ipairs(var_10_13) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_5)
				table.insert(arg_10_0.records_.special_units, iter_10_5)
			end
		else
			local var_10_14 = arg_10_0:createAttackUnits({
				arg_10_1.target
			}, var_0_16)

			for iter_10_6, iter_10_7 in ipairs(var_10_14) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_7)
				table.insert(arg_10_0.records_.special_units, iter_10_7)
			end
		end
	end
end

function var_0_3.setSummonMonsters(arg_11_0, arg_11_1, arg_11_2, arg_11_3, arg_11_4)
	local var_11_0

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_0 = arg_11_0:getSummonMonster()
	else
		local var_11_1 = var_0_6.new()

		var_11_1:populateWithTableID(arg_11_1)

		var_11_1.level_ = arg_11_2 or var_11_1.level_
		var_11_1.color_ = arg_11_3 or var_11_1.color_

		for iter_11_0, iter_11_1 in ipairs(var_11_1.skillLev_) do
			local var_11_2 = var_11_1:getSkillId(iter_11_0)
			local var_11_3 = arg_11_0.hero_:getSkillLevelByID(var_11_2)

			if var_11_3 and var_11_3 > 0 then
				var_11_1.skillLev_[iter_11_0] = var_11_3
			end
		end

		local var_11_4 = var_11_1:className()

		var_11_0 = var_0_1.ctx.battle.requireFighter(var_11_4).new({
			is_arena = arg_11_0.isInArena_
		})

		var_11_0:populateWithHero(var_11_1)
		var_11_0:initModels()
		var_11_0.fighterModel:initHeaderView(arg_11_0:getTeamType() - 1)

		var_11_0.fighterIndex = arg_11_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(#var_0_1.ctx.battle.teamA + 1) or "B|" .. tostring(#var_0_1.ctx.battle.teamB + 1)

		var_11_0:setFormationDelay(0, 100)
	end

	if not var_11_0 then
		arg_11_0:summonMonstersErrorLog()
	end

	var_11_0.summonType_ = var_0_2.summonMonsterType.Monster

	var_11_0:setTeamType(arg_11_0:getTeamType())

	var_11_0.summoner = arg_11_0

	var_11_0.fighterModel:pos(arg_11_4.x, arg_11_4.y)
	var_11_0:updateHp(var_11_0:getHpLimit())
	var_11_0:getFighterModel():flipX(arg_11_0:getTeamType() == var_0_2.TeamType.B)
	var_11_0.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_11_0:born()
	var_11_0:setGlobalBuffs()

	local var_11_5 = var_11_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

	table.insert(var_11_5, var_11_0)
	table.insert(var_0_1.ctx.battle.yOrder, var_11_0)
	var_0_1.ctx.battle.updateZorder()
	table.insert(arg_11_0.summonMonsters_, var_11_0)
end

function var_0_3.applyHurtFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
	if arg_12_2 > 0 and arg_12_4 and arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_12_2 = var_0_11(arg_12_2, arg_12_0:getHpLimit() * var_0_14)

		local var_12_0 = arg_12_0:createAttackUnits({
			arg_12_0
		}, arg_12_0.PurpleSkillID)

		for iter_12_0, iter_12_1 in ipairs(var_12_0) do
			table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
			table.insert(arg_12_0.records_.special_units, iter_12_1)
		end
	end

	return var_0_3.super.applyHurtFighter(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
end

function var_0_3.selectTargetByTypeD1(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_2 then
		return var_0_4.B1(arg_13_0, arg_13_1, arg_13_2)
	end

	if not arg_13_2.targets_ or not next(arg_13_2.targets_) then
		return
	end

	local var_13_0 = arg_13_2.targets_
	local var_13_1, var_13_2 = var_0_4.getTeam(arg_13_0)
	local var_13_3, var_13_4 = var_13_0[#var_13_0]:getPos()
	local var_13_5
	local var_13_6

	for iter_13_0, iter_13_1 in ipairs(var_13_2) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None then
			local var_13_7, var_13_8 = iter_13_1:getPos()
			local var_13_9 = math.abs(var_13_3 - var_13_7)

			if (not var_13_5 or var_13_9 < var_13_5) and not arg_13_2.recordTargets_[iter_13_1.fighterIndex] then
				var_13_5 = var_13_9
				var_13_6 = iter_13_1
			end
		end
	end

	local var_13_10 = {}

	if var_13_6 then
		var_13_10 = {
			var_13_6
		}
	else
		arg_13_2:clearCollisionNum()

		local var_13_11
		local var_13_12

		for iter_13_2, iter_13_3 in pairs(arg_13_0.selfTeam_) do
			if not iter_13_3:isDeath() and not iter_13_3:isAffected() and iter_13_3:getSummonType() == var_0_2.summonMonsterType.None and (not var_13_11 or var_13_12 > iter_13_3:getHp() / iter_13_3:getHpLimit() or var_13_12 == iter_13_3:getHp() / iter_13_3:getHpLimit() and var_13_11:getHp() > iter_13_3:getHp()) then
				var_13_11 = iter_13_3
				var_13_12 = var_13_11:getHp() / var_13_11:getHpLimit()
			end
		end

		if var_13_11 then
			return {
				var_13_11
			}
		else
			return {}
		end
	end

	return var_13_10
end

function var_0_3.addBuffBySpecialHero(arg_14_0, arg_14_1)
	if arg_14_0:hasElementEquipByID(var_0_32) then
		for iter_14_0, iter_14_1 in ipairs(arg_14_1) do
			if iter_14_1.target:getTeamType() ~= arg_14_0:getTeamType() then
				if iter_14_1:getAttrType() == var_0_2.AttributeType.AD_BAOJI and iter_14_1:getAttr() < 0 then
					local var_14_0 = arg_14_0:createNewBuffs({
						var_0_34
					}, arg_14_0, var_0_33)
					local var_14_1, var_14_2 = iter_14_1:getAttr()

					if var_14_2 then
						var_14_0[1].manualRevise = -iter_14_1.target:getAttrByType(var_0_2.AttributeType.AD_BAOJI) * var_14_1
					else
						var_14_0[1].manualRevise = -var_14_1
					end

					arg_14_0:addBuffs(var_14_0)
				elseif iter_14_1:getAttrType() == var_0_2.AttributeType.AP_BAOJI and iter_14_1:getAttr() < 0 then
					local var_14_3 = arg_14_0:createNewBuffs({
						var_0_35
					}, arg_14_0, var_0_33)
					local var_14_4, var_14_5 = iter_14_1:getAttr()

					if var_14_5 then
						var_14_3[1].manualRevise = -iter_14_1.target:getAttrByType(var_0_2.AttributeType.AP_BAOJI) * var_14_4
					else
						var_14_3[1].manualRevise = -var_14_4
					end

					arg_14_0:addBuffs(var_14_3)
				end
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_15_0, arg_15_1)
	if arg_15_1:getTableID() == var_0_34 or arg_15_1:getTableID() == var_0_35 then
		local var_15_0 = var_0_32
		local var_15_1 = var_0_31:battleAttr(var_15_0, arg_15_0:getElementEquipLevelByID(var_15_0))
		local var_15_2 = arg_15_0.hero_:getElementEquipActiveRate(var_15_0)

		arg_15_0:updateHp(arg_15_0:getHp() + var_15_1 * var_15_2)
	end
end

return var_0_3
