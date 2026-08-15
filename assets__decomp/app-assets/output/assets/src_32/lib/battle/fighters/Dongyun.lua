local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dongyun", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_7 = var_0_2.tables.battleConfig
local var_0_8 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_9 = var_0_2.tables.skill
local var_0_10 = var_0_2.tables.hero
local var_0_11 = var_0_2.tables.model
local var_0_12 = 10001168
local var_0_13 = 40011276
local var_0_14 = 90
local var_0_15 = 10001165
local var_0_16 = 40011279
local var_0_17 = 0.2
local var_0_18 = 10001169
local var_0_19 = 10001170
local var_0_20 = 5
local var_0_21 = 40011278
local var_0_22 = 20
local var_0_23 = 6
local var_0_24 = 80010196
local var_0_25 = 20011196
local var_0_26 = 30011196
local var_0_27 = 50011196
local var_0_28 = 10001602
local var_0_29 = 40011706
local var_0_30 = 10001603
local var_0_31 = 40011707
local var_0_32 = 0.15
local var_0_33 = 0.1
local var_0_34 = var_0_2.tables.elementEquip
local var_0_35 = 20001501
local var_0_36 = 10002480
local var_0_37 = 90

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("move_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueCount = 0
	arg_2_0.greenEffects_ = {}
	arg_2_0.greenEffectTargets = {}
	arg_2_0.ElementSkillCD = 0
	arg_2_0.records_.buff_count = {}
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillID_ == var_0_24 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_0 = arg_3_0:createAttackUnits({
			arg_3_0
		}, var_0_24)

		for iter_3_0, iter_3_1 in ipairs(var_3_0) do
			if var_0_2.weightedChoise({
				0.5,
				0.5
			}) == 1 then
				iter_3_1:setExtraHarm((arg_3_0:getHpLimit() - arg_3_0:getHp()) * var_0_32)
			else
				iter_3_1.basicHarm = 0
			end

			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		arg_4_0.blueCount = arg_4_0.blueCount - 1

		if arg_4_0.blueCount <= 0 then
			for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("move_info")) do
				local var_4_0 = iter_4_1.fighter

				if var_4_0:getTeamType() == arg_4_0:getTeamType() and var_4_0:isHasBuffByID(arg_4_0.skinSkillID_ == var_0_24 and var_0_29 or var_0_13) then
					arg_4_0.blueCount = var_0_14

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_4_1 = arg_4_0:createAttackUnits({
							var_4_0
						}, var_0_15)

						for iter_4_2, iter_4_3 in ipairs(var_4_1) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
							table.insert(arg_4_0.records_.special_units, iter_4_3)
						end
					end
				end
			end
		end
	end

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_4, iter_4_5 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_5.target:getTeamType() == arg_4_0:getTeamType() and iter_4_5.target ~= arg_4_0 and iter_4_5:getType() == var_0_2.BuffType.REVIVIE then
				local var_4_2 = var_0_5.new({
					tableID = var_0_16,
					start = var_0_1.ctx.battle.count,
					level = arg_4_0:getSkillLevelByID(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
					skillID = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
					fighter = arg_4_0,
					target = arg_4_0,
					manualDharm = iter_4_5:getHarm() * var_0_17
				})

				arg_4_0:addBuffs({
					var_4_2
				})
			end
		end
	end

	if var_0_1.ctx.battle.count % var_0_23 == 0 then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_7.target:isHasBuffByID(arg_4_0.skinSkillID_ == var_0_24 and var_0_31 or var_0_21) and iter_4_7:getType() == var_0_2.BuffType.ATTR_CHANGE and iter_4_7:getAttrType() > 0 and iter_4_7:getAttr() > 0 then
				local var_4_3 = iter_4_7.target.hero_:getBattleAttr(iter_4_7:getAttrType())

				if not var_4_3 or var_4_3 == 0 then
					var_4_3 = 1
				end

				local var_4_4 = arg_4_0:getAP() * var_0_20 * (iter_4_7:getAttr() / var_4_3)

				if not iter_4_7.target:isBoss() then
					iter_4_7.target:removeBuffByID(iter_4_7:getTableID())
				end

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_5 = arg_4_0:createAttackUnits({
						iter_4_7.target
					}, arg_4_0.skinSkillID_ == var_0_24 and var_0_30 or var_0_19)

					for iter_4_8, iter_4_9 in ipairs(var_4_5) do
						iter_4_9.harmTotal = var_4_4

						table.insert(arg_4_0.moveAttackUnits_, iter_4_9)
						table.insert(arg_4_0.records_.special_units, iter_4_9)
					end
				end
			end
		end
	end

	if arg_4_0.greenEffects_ and next(arg_4_0.greenEffects_) then
		for iter_4_10, iter_4_11 in ipairs(arg_4_0.greenEffects_) do
			local var_4_6 = iter_4_11.posX
			local var_4_7 = iter_4_11.posY
			local var_4_8 = arg_4_0:getX()
			local var_4_9 = var_0_22 * iter_4_11.dir
			local var_4_10 = var_0_1.ctx.battle.count - iter_4_11.count

			for iter_4_12, iter_4_13 in ipairs(arg_4_0.sideTeam_) do
				if not iter_4_13:isDeath() and not iter_4_13:isAffected() and math.abs(iter_4_13:getX() - iter_4_11.effect:getX()) <= 15 and not arg_4_0.greenEffectTargets[iter_4_13] then
					arg_4_0.greenEffectTargets[iter_4_13] = true

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_4_11 = arg_4_0:createAttackUnits({
							iter_4_13
						}, arg_4_0.skinSkillID_ == var_0_24 and var_0_28 or var_0_12)

						for iter_4_14, iter_4_15 in ipairs(var_4_11) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_15)
							table.insert(arg_4_0.records_.special_units, iter_4_15)
						end
					end
				end
			end

			iter_4_11.effect:pos(var_4_6 + var_4_9 * var_4_10, var_4_7)

			if math.abs(var_4_6 + var_4_9 * var_4_10 - var_4_8) <= 10 or var_4_10 > math.abs((var_4_8 - var_4_6) / var_4_9) then
				iter_4_11.effect:removeSelf()

				iter_4_11.effect = nil

				table.remove(arg_4_0.greenEffects_, iter_4_10)

				arg_4_0.greenEffectTargets = {}
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_5_1.attackType == var_0_2.AttackType.CURE and arg_5_5 > 0 and arg_5_1.target:getTeamType() == arg_5_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_0 = arg_5_0:createAttackUnits({
			arg_5_0
		}, var_0_18)

		for iter_5_0, iter_5_1 in ipairs(var_5_0) do
			iter_5_1.dHarm = arg_5_5 * var_0_17

			table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
			table.insert(arg_5_0.records_.special_units, iter_5_1)
		end
	end

	return arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_18 then
		local var_6_0 = var_0_5.new({
			tableID = var_0_16,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)),
			skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_6_0,
			target = arg_6_0,
			manualDharm = (arg_6_1.dHarm or 0) * var_0_17
		})

		arg_6_0:addBuffs({
			var_6_0
		})
	elseif arg_6_1.skillID == (arg_6_0.skinSkillID_ == var_0_24 and var_0_27 or arg_6_0:getEnergySkillID()) then
		local var_6_1 = 0
		local var_6_2 = arg_6_1.target:getBuffs()
		local var_6_3 = {}

		for iter_6_0, iter_6_1 in ipairs(var_6_2) do
			if iter_6_1:getType() == var_0_2.BuffType.ATTR_CHANGE and iter_6_1:getAttrType() > 0 and iter_6_1:getAttr() > 0 then
				local var_6_4 = arg_6_1.target.hero_:getBattleAttr(iter_6_1:getAttrType())

				if not var_6_4 or var_6_4 == 0 then
					var_6_4 = 1
				end

				var_6_1 = var_6_1 + arg_6_0:getAP() * var_0_20 * (iter_6_1:getAttr() / var_6_4)

				table.insert(var_6_3, iter_6_1)
			end
		end

		if not arg_6_1.target:isBoss() then
			for iter_6_2, iter_6_3 in ipairs(var_6_3) do
				arg_6_1.target:removeBuffByID(iter_6_3:getTableID())
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_5 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, arg_6_0.skinSkillID_ == var_0_24 and var_0_30 or var_0_19)

			for iter_6_4, iter_6_5 in ipairs(var_6_5) do
				iter_6_5.harmTotal = var_6_1

				table.insert(arg_6_0.moveAttackUnits_, iter_6_5)
				table.insert(arg_6_0.records_.special_units, iter_6_5)
			end
		end
	elseif arg_6_1.skillID == (arg_6_0.skinSkillID_ == var_0_24 and var_0_25 or arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) then
		local var_6_6 = {
			x = arg_6_1.target:getX(),
			y = arg_6_1.target:getY()
		}
		local var_6_7 = var_0_1.ctx.battle.getSpine(arg_6_0.skinSkillID_ == var_0_24 and var_0_28 or var_0_12, "unit", 0.5)

		var_6_7:addTo(var_0_1.ctx.battle.unitLayer)
		var_6_7:pos(var_6_6.x, var_6_6.y)
		var_6_7:playRepeat()

		local var_6_8 = {
			posX = var_6_6.x,
			posY = var_6_6.y,
			effect = var_6_7,
			count = var_0_1.ctx.battle.count,
			dir = var_6_6.x > arg_6_0:getX() and -1 or 1
		}

		table.insert(arg_6_0.greenEffects_, var_6_8)
	end

	if arg_6_1.skillID == var_0_36 and arg_6_0:hasElementEquipByID(var_0_35) then
		arg_6_0:removeEnermyGoodBuff(arg_6_1.target)
	end
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == (arg_7_0.skinSkillID_ == var_0_24 and var_0_30 or var_0_19) and arg_7_1.harmTotal then
		var_7_2 = var_7_2 + arg_7_1.harmTotal
	end

	if arg_7_1.skillID == var_0_24 and var_7_3 < 1 then
		var_7_5 = var_7_5 + var_0_33 * (1000 - arg_7_0:getEnergy())
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.selectTargetByTypeD1(arg_8_0)
	local var_8_0 = {}
	local var_8_1
	local var_8_2

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and not iter_8_1:isHasBuffByID(var_0_13) and (not var_8_2 or var_8_1 > var_8_2.hero_:getDistance()) then
			var_8_2 = iter_8_1
			var_8_1 = iter_8_1.hero_:getDistance()
		end
	end

	if var_8_2 then
		return {
			var_8_2
		}
	end

	return var_8_0
end

function var_0_3.selectTargetByTypeD2(arg_9_0)
	local var_9_0 = {}
	local var_9_1
	local var_9_2

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1:getX() >= 0 and iter_9_1:getX() <= var_0_2.STAGE_WIDTH then
			if arg_9_0:getFlipX() then
				if not var_9_1 or var_9_1 < arg_9_0:getX() - iter_9_1:getX() then
					var_9_2 = iter_9_1
					var_9_1 = arg_9_0:getX() - iter_9_1:getX()
				end
			elseif not var_9_1 or var_9_1 < iter_9_1:getX() - arg_9_0:getX() then
				var_9_2 = iter_9_1
				var_9_1 = iter_9_1:getX() - arg_9_0:getX()
			end
		end
	end

	return {
		var_9_2
	}
end

function var_0_3.addBuffBySpecialHero(arg_10_0, arg_10_1)
	var_0_3.super.addBuffBySpecialHero(arg_10_0, arg_10_1)

	if arg_10_0:hasElementEquipByID(var_0_35) then
		for iter_10_0 = #arg_10_1, 1, -1 do
			local var_10_0 = arg_10_1[iter_10_0]
			local var_10_1 = var_10_0.target

			if var_10_1 and not var_10_1:isDeath() and var_10_1:getTeamType() == arg_10_0:getTeamType() and var_10_0:getBuffForm() == var_0_2.BuffForm.GAIN and var_10_0:getType() == var_0_2.BuffType.ATTR_CHANGE and (arg_10_0.ElementSkillCD == 0 or var_0_1.ctx.battle.count - arg_10_0.ElementSkillCD > var_0_37) then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_10_2 = var_0_4.B3(arg_10_0, var_0_36)
					local var_10_3 = arg_10_0:createAttackUnits(var_10_2, var_0_36)

					for iter_10_1, iter_10_2 in ipairs(var_10_3) do
						table.insert(arg_10_0.moveAttackUnits_, iter_10_2)
						table.insert(arg_10_0.records_.special_units, iter_10_2)
					end
				end

				local var_10_4 = var_0_35
				local var_10_5 = var_0_34:battleAttr(var_10_4, arg_10_0:getElementEquipLevelByID(var_10_4))
				local var_10_6 = arg_10_0.hero_:getElementEquipActiveRate(var_10_4)

				arg_10_0:updateEnergyBy(var_10_5 * var_10_6 * arg_10_0:getEnergyRate())

				arg_10_0.ElementSkillCD = var_0_1.ctx.battle.count
			end
		end
	end
end

function var_0_3.removeEnermyGoodBuff(arg_11_0, arg_11_1)
	local var_11_0 = {}
	local var_11_1 = arg_11_1:getBuffs()

	for iter_11_0, iter_11_1 in ipairs(var_11_1) do
		if iter_11_1:getBuffForm() == var_0_2.BuffForm.GAIN and iter_11_1:getType() == var_0_2.BuffType.ATTR_CHANGE and iter_11_1:canRemove() then
			table.insert(var_11_0, iter_11_1)
		end
	end

	if #var_11_0 == 0 then
		return
	end

	local var_11_2 = 1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_11_2 = arg_11_0.buffCount[tostring(var_0_1.ctx.battle.count)] or 1
	else
		var_11_2 = math.random(#var_11_0)
		arg_11_0.records_.buff_count[tostring(var_0_1.ctx.battle.count)] = var_11_2
	end

	if var_11_0[var_11_2] and arg_11_1:isHasBuffByID(var_11_0[var_11_2]:getTableID()) then
		arg_11_1:removeBuffs(var_11_0[var_11_2])
	end
end

function var_0_3.setupReport(arg_12_0, arg_12_1)
	var_0_3.super.setupReport(arg_12_0, arg_12_1)

	arg_12_0.buffCount = arg_12_1.buff_count or {}
end

function var_0_3.writeReport(arg_13_0)
	local var_13_0 = var_0_3.super.writeReport(arg_13_0)

	var_13_0.buff_count = arg_13_0.records_.buff_count

	return var_13_0
end

return var_0_3
