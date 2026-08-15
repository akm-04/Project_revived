local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Jiangqin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = math.abs
local var_0_8 = math.min
local var_0_9 = 40011067
local var_0_10 = 0.015
local var_0_11 = 0.004
local var_0_12 = 10000972
local var_0_13 = 40011068
local var_0_14 = 10000974
local var_0_15 = 0.18
local var_0_16 = 20010178
local var_0_17 = 0.05
local var_0_18 = 0.3
local var_0_19 = 15
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001448
local var_0_22 = 10002146
local var_0_23 = 40012286
local var_0_24 = 40012288
local var_0_25 = 80010178
local var_0_26 = 0.6
local var_0_27 = 0.05
local var_0_28 = 40012289
local var_0_29 = 40012290
local var_0_30 = 10002148

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("attack_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energySkillRegion = {}
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 then
		arg_3_0.AwakeChildSkill = 10002154
		arg_3_0.EnergySkillAtlas = 10002155
	else
		arg_3_0.AwakeChildSkill = 10000975
		arg_3_0.EnergySkillAtlas = 10000977
	end
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)
	arg_4_0:updateEnergyEffect()
end

function var_0_3.updateEnergyEffect(arg_5_0)
	if not arg_5_0:acttionInBlack() then
		return
	end

	if next(arg_5_0.energySkillRegion) ~= nil then
		for iter_5_0 = #arg_5_0.energySkillRegion, 1, -1 do
			local var_5_0 = arg_5_0.energySkillRegion[iter_5_0]

			var_5_0.time = var_5_0.time - 1

			if var_5_0.time == 0 then
				var_5_0.effect:removeSelf()

				var_5_0.effect = nil

				table.remove(arg_5_0.energySkillRegion, iter_5_0)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count == 1 and arg_6_0:hasElementEquipByID(var_0_21) then
		local var_6_0 = var_0_21
		local var_6_1 = var_0_20:battleAttr(var_6_0, arg_6_0:getElementEquipLevelByID(var_6_0))
		local var_6_2 = arg_6_0.hero_:getElementEquipActiveRate(var_6_0)
		local var_6_3 = arg_6_0:createNewBuffs({
			var_0_24
		}, arg_6_0, var_0_22)

		for iter_6_0, iter_6_1 in ipairs(var_6_3) do
			iter_6_1.manualRevise = var_6_1 * var_6_2
		end

		arg_6_0:addBuffs(var_6_3)
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_6_2, iter_6_3 in ipairs(arg_6_0:getInfoByKey("attack_info")) do
			if iter_6_3.fighter_:getTeamType() == arg_6_0:getTeamType() and iter_6_3.fighter_:getSummonType() ~= var_0_2.summonMonsterType.Copy and iter_6_3.rootID_ ~= iter_6_3.fighter_:getPugongID() and iter_6_3.rootID_ ~= arg_6_0.AwakeChildSkill then
				local var_6_4 = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) * var_0_11

				if var_0_2.weightedChoise({
					var_6_4,
					1 - var_6_4
				}) == 1 then
					local var_6_5 = arg_6_0:createAttackUnits({
						arg_6_0
					}, var_0_12)

					for iter_6_4, iter_6_5 in ipairs(var_6_5) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
						table.insert(arg_6_0.records_.special_units, iter_6_5)
					end
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0:getEnergySkillID() then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_0 = arg_7_0:selectTargetByTypeD2(var_0_14, arg_7_1)
			local var_7_1 = arg_7_0:createAttackUnits(var_7_0, var_0_14)

			for iter_7_0, iter_7_1 in ipairs(var_7_1) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end

		arg_7_0:elementSkill(arg_7_1)

		local var_7_2 = {
			x = arg_7_1.target:getX(),
			y = arg_7_1.target:getY()
		}
		local var_7_3 = var_0_19
		local var_7_4 = var_0_1.ctx.battle.getSpine(arg_7_0.EnergySkillAtlas, "hurt", 1)

		var_7_4:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_7_4:pos(var_7_2.x, var_7_2.y)
		var_7_4:playRepeat()

		local var_7_5 = {
			pos = var_7_2,
			time = var_7_3,
			effect = var_7_4
		}

		table.insert(arg_7_0.energySkillRegion, var_7_5)
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_6 = arg_8_1.skillID

	if var_8_2 > 0 and var_8_6 == var_0_14 then
		var_8_2 = var_8_2 + arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) * var_0_15 * arg_8_0:getAttrByType(var_0_2.AttributeType.WISE)
	elseif var_8_2 > 0 and var_8_6 == var_0_16 then
		local var_8_7 = (#arg_8_0:getTargets(var_8_6) - 1) * var_0_17

		var_8_2 = var_8_2 * (1 + var_0_8(var_8_7, var_0_18))
	end

	if var_8_2 > 0 and arg_8_0.skinSkillID_ == var_0_25 then
		local var_8_8 = arg_8_1.target

		if arg_8_0:getAP() - var_8_8:getAP() > 0 then
			var_8_2 = var_8_2 + (arg_8_0:getAP() - var_8_8:getAP()) * var_0_26
		elseif var_8_8:getAP() - arg_8_0:getAP() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_8_9 = arg_8_0:createAttackUnits({
				var_8_8
			}, var_0_30)

			for iter_8_0, iter_8_1 in ipairs(var_8_9) do
				table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
				table.insert(arg_8_0.records_.special_units, iter_8_1)
			end
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.buffAddAction(arg_9_0, arg_9_1)
	var_0_3.super.buffAddAction(arg_9_0, arg_9_1)

	if arg_9_1:getTableID() == var_0_9 then
		local var_9_0 = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		local var_9_1 = arg_9_0:getAttrByType(var_0_2.AttributeType.WISE) * var_0_10 * var_9_0
		local var_9_2 = arg_9_1:getDHarm()

		arg_9_1.manualDharm = arg_9_1.manualDharm + var_9_1
		arg_9_1.dHarm_ = var_9_2 + var_9_1
	elseif arg_9_1:getTableID() == var_0_29 then
		local var_9_3 = (arg_9_1.target:getAP() - arg_9_0:getAP()) * var_0_27

		if var_9_3 > 0 then
			arg_9_1.manualRevise = -var_9_3

			local var_9_4 = arg_9_0:createNewBuffs({
				var_0_28
			}, arg_9_0, var_0_25)

			var_9_4[1].manualRevise = var_9_3

			arg_9_0:addBuffs(var_9_4)
		end
	end
end

function var_0_3.newBuff(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		local var_10_1 = var_0_5.new({
			tableID = iter_10_1,
			start = var_0_1.ctx.battle.count,
			level = arg_10_0:getSkillLevelByID(arg_10_3),
			skillID = arg_10_3,
			fighter = arg_10_0,
			target = arg_10_2
		})

		var_10_1:setIsHit(true)
		var_10_1:setDirection(arg_10_0:getFighterModel():getFlipX())
		table.insert(var_10_0, var_10_1)
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD1(arg_11_0)
	local var_11_0

	for iter_11_0, iter_11_1 in ipairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and (not var_11_0 or iter_11_1:getAttrByType(var_0_2.AttributeType.WISE) > var_11_0:getAttrByType(var_0_2.AttributeType.WISE)) then
			var_11_0 = iter_11_1
		end
	end

	if var_11_0 then
		return {
			var_11_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = {}

	table.insert(var_12_0, arg_12_2.target)

	local var_12_1 = var_0_6:scope(arg_12_1)
	local var_12_2 = arg_12_2.target:getX()

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		if iter_12_1 ~= arg_12_2.target and not iter_12_1:isDeath() and not iter_12_1:isAffected() and var_12_1 >= var_0_7(iter_12_1:getX() - var_12_2) then
			table.insert(var_12_0, iter_12_1)
		end
	end

	return var_12_0
end

function var_0_3.elementSkill(arg_13_0, arg_13_1)
	if arg_13_0:hasElementEquipByID(var_0_21) then
		local var_13_0 = var_0_21
		local var_13_1 = var_0_20:battleAttr(var_13_0, arg_13_0:getElementEquipLevelByID(var_13_0))
		local var_13_2 = arg_13_0.hero_:getElementEquipActiveRate(var_13_0)
		local var_13_3 = arg_13_0:createNewBuffs({
			var_0_23
		}, arg_13_1.target, var_0_22)

		arg_13_1.target:addBuffs(var_13_3)
	end
end

return var_0_3
