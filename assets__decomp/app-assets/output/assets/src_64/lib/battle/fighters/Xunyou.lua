local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xunyou", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.skinSkill
local var_0_7 = var_0_2.tables.dbuff
local var_0_8 = 120
local var_0_9 = 10
local var_0_10 = 300
local var_0_11 = 20010147
local var_0_12 = 20010148
local var_0_13 = "skeletons/xunyou/xunyougongji03"
local var_0_14 = 20010149
local var_0_15 = 10010063
local var_0_16 = 20010151
local var_0_17 = {
	40010667,
	40010669
}
local var_0_18 = {
	40010666,
	40010668
}
local var_0_19 = 40010670
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001461
local var_0_22 = 1

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.frozenTargets = {}
	arg_1_0.blueSkillRegion = {}
	arg_1_0.debuffTargets = {}
	arg_1_0.cout = false
	arg_1_0.records_.is_hit = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)

	if not arg_2_0.cout then
		if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_2_0.purpleSkillExsist = true
		end

		arg_2_0.cout = true
	end

	if arg_2_0:acttionInBlack() and next(arg_2_0.frozenTargets) ~= nil then
		for iter_2_0 = #arg_2_0.frozenTargets, 1, -1 do
			local var_2_0 = arg_2_0.frozenTargets[iter_2_0]

			var_2_0.greenCount = var_2_0.greenCount - 1

			if var_2_0.greenCount == 0 then
				arg_2_0:frozenHero(var_2_0)
				table.remove(arg_2_0.frozenTargets, iter_2_0)
			elseif var_2_0.greenCount % var_0_9 == 0 then
				if not var_2_0.target:isHasBuffByID(var_0_11) then
					table.remove(arg_2_0.frozenTargets, iter_2_0)
				elseif arg_2_0:isTargetMoved(var_2_0) then
					var_2_0.target:removeBuffByID(var_0_11)
					table.remove(arg_2_0.frozenTargets, iter_2_0)
				end
			end
		end
	end

	arg_2_0:updateIceEffect()
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_3_1 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)

	if arg_3_1.skillID == var_3_0 then
		local var_3_2 = arg_3_1.target
		local var_3_3 = var_0_8
		local var_3_4 = {
			target = var_3_2,
			targetPos = var_3_2:getX(),
			greenCount = var_3_3
		}

		table.insert(arg_3_0.frozenTargets, var_3_4)
	end

	if arg_3_1.skillID == var_3_1 then
		local var_3_5 = {
			x = arg_3_1.target:getX(),
			y = arg_3_1.target:getY()
		}
		local var_3_6 = var_0_10
		local var_3_7 = var_0_1.ctx.battle.getSpine(var_3_1, "area", 1)

		var_3_7:addTo(var_0_1.ctx.battle.unitBottomLayer)
		var_3_7:pos(var_3_5.x, var_3_5.y)
		var_3_7:playRepeat()

		local var_3_8 = {
			pos = var_3_5,
			time = var_3_6,
			effect = var_3_7
		}

		table.insert(arg_3_0.blueSkillRegion, var_3_8)
	end

	if arg_3_0.purpleSkillExsist and arg_3_1.skillID == var_0_15 then
		arg_3_0:enemyTeamDecreaseAttack()
	end
end

function var_0_3.isTargetMoved(arg_4_0, arg_4_1)
	if not arg_4_1.target or arg_4_1.target:isDeath() then
		return true
	end

	local var_4_0 = var_0_5:scope(arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) / 2

	if arg_4_1.targetPos and var_4_0 < math.abs(arg_4_1.target:getX() - arg_4_1.targetPos) then
		return true
	end

	return false
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0 = var_0_4.new({
		tableID = arg_5_1,
		start = var_0_1.ctx.battle.count,
		level = arg_5_3,
		skillID = arg_5_2,
		fighter = arg_5_0,
		target = arg_5_4
	})

	return {
		var_5_0
	}
end

function var_0_3.frozenHero(arg_6_0, arg_6_1)
	if not arg_6_1.target then
		return
	end

	local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)
	local var_6_1 = arg_6_0:getSkillLevelByID(var_6_0)

	arg_6_1.target:addBuffs(arg_6_0:newBuff(var_0_12, var_6_0, var_6_1, arg_6_1.target))
end

function var_0_3.removeAllIceBuff(arg_7_0)
	for iter_7_0 = #arg_7_0.debuffTargets, 1, -1 do
		local var_7_0 = arg_7_0.debuffTargets[iter_7_0]

		var_7_0:removeBuffByID(var_0_14)
		table.remove(arg_7_0.debuffTargets, iter_7_0)
		arg_7_0:removeSkinSkill(var_7_0)
	end
end

function var_0_3.addIceDebuff(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
	local var_8_1 = arg_8_0:getSkillLevelByID(var_8_0)
	local var_8_2 = arg_8_0:newBuff(var_0_14, var_8_0, var_8_1, arg_8_1)

	arg_8_1:addBuffs(var_8_2)
	arg_8_0:addSkinSkill(arg_8_1)
end

function var_0_3.addSkinSkill(arg_9_0, arg_9_1)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_0.isSkinSkillOn_ then
		local var_9_0 = {
			arg_9_1
		}
		local var_9_1 = arg_9_0:createAttackUnits(var_9_0, 10000672)

		for iter_9_0, iter_9_1 in ipairs(var_9_1) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end

		local var_9_2 = {
			arg_9_0
		}
		local var_9_3 = arg_9_0:createAttackUnits(var_9_2, 10000671)

		for iter_9_2, iter_9_3 in ipairs(var_9_3) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
			table.insert(arg_9_0.records_.special_units, iter_9_3)
		end
	end
end

function var_0_3.removeSkinSkill(arg_10_0, arg_10_1)
	if arg_10_0.isSkinSkillOn_ then
		for iter_10_0 = 1, #var_0_18 do
			arg_10_0:removeBuffByID(var_0_18[iter_10_0])
		end

		for iter_10_1 = 1, #var_0_17 do
			arg_10_1:removeBuffByID(var_0_17[iter_10_1])
		end
	end
end

function var_0_3.die(arg_11_0)
	if arg_11_0.isSkinSkillOn_ then
		local var_11_0 = arg_11_0.killer_

		if var_11_0 and not var_11_0:isDeath() and not var_11_0:isAffected() then
			local var_11_1 = arg_11_0:getLevel()

			var_11_0:addBuffs(arg_11_0:newBuff(var_0_19, arg_11_0.skinSkillID_, var_11_1, var_11_0))
		end
	end

	return var_0_3.super.die(arg_11_0)
end

function var_0_3.isInCircle(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_2:getX()
	local var_12_1 = arg_12_1.pos.x

	if var_0_5:scope(arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)) / 2 >= math.abs(var_12_0 - var_12_1) then
		return true
	end

	return false
end

function var_0_3.enemyTeamDecreaseAttack(arg_13_0)
	local var_13_0 = arg_13_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA

	for iter_13_0, iter_13_1 in ipairs(var_13_0) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() then
			local var_13_1 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
			local var_13_2 = arg_13_0:getSkillLevelByID(var_13_1)

			iter_13_1:addBuffs(arg_13_0:newBuff(var_0_16, var_13_1, var_13_2, iter_13_1))
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.teamB or var_0_1.ctx.battle.teamA
	local var_14_1 = {}
	local var_14_2 = var_0_5:scope(arg_14_0:getEnergySkillID()) / 2
	local var_14_3
	local var_14_4
	local var_14_5 = {}

	for iter_14_0, iter_14_1 in ipairs(var_14_0) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() then
			table.insert(var_14_1, iter_14_1)
		end
	end

	for iter_14_2, iter_14_3 in ipairs(var_14_1) do
		local var_14_6 = iter_14_3:getHp() / iter_14_3:getHpLimit()

		if not var_14_3 or var_14_4 < var_14_6 or var_14_4 == var_14_6 and iter_14_3:getHp() < var_14_3:getHp() then
			var_14_3 = iter_14_3
			var_14_4 = var_14_6
		end
	end

	if not var_14_3 then
		return {}
	end

	local var_14_7 = var_14_3:getX()

	for iter_14_4, iter_14_5 in ipairs(var_14_1) do
		if var_14_2 >= math.abs(iter_14_5:getX() - var_14_7) then
			table.insert(var_14_5, iter_14_5)
		end
	end

	return var_14_5
end

function var_0_3.updateIceEffect(arg_15_0)
	if not arg_15_0:acttionInBlack() then
		return
	end

	if next(arg_15_0.blueSkillRegion) ~= nil then
		for iter_15_0 = #arg_15_0.blueSkillRegion, 1, -1 do
			local var_15_0 = arg_15_0.blueSkillRegion[iter_15_0]
			local var_15_1 = arg_15_0.sideTeam_

			var_15_0.time = var_15_0.time - 1

			if var_15_0.time == 0 then
				arg_15_0:removeAllIceBuff()
				var_15_0.effect:removeSelf()

				var_15_0.effect = nil

				table.remove(arg_15_0.blueSkillRegion, iter_15_0)
			elseif var_15_0.time % var_0_9 == 0 then
				for iter_15_1, iter_15_2 in ipairs(var_15_1) do
					if not iter_15_2:isDeath() and not iter_15_2:isAffected() and not var_0_0.table.indexof(arg_15_0.debuffTargets, iter_15_2) and arg_15_0:isInCircle(var_15_0, iter_15_2) then
						table.insert(arg_15_0.debuffTargets, iter_15_2)
						arg_15_0:addIceDebuff(iter_15_2)
					end
				end

				if next(arg_15_0.debuffTargets) ~= nil then
					for iter_15_3 = #arg_15_0.debuffTargets, 1, -1 do
						local var_15_2 = arg_15_0.debuffTargets[iter_15_3]

						if not arg_15_0:isInCircle(var_15_0, var_15_2) then
							var_15_2:removeBuffByID(var_0_14)
							table.remove(arg_15_0.debuffTargets, iter_15_3)
						end
					end
				end
			end
		end
	end
end

function var_0_3.buffAddAction(arg_16_0, arg_16_1)
	var_0_3.super.buffAddAction(arg_16_0, arg_16_1)

	if arg_16_0:hasElementEquipByID(var_0_21) and arg_16_1.target:getTeamType() ~= arg_16_0:getTeamType() and (arg_16_1:getType() == var_0_2.BuffType.CONTINUE_HARM or arg_16_1:dBuffType() > 0 or arg_16_1:getBuffForm() == var_0_2.BuffForm.DEBUFF) then
		local var_16_0 = var_0_21
		local var_16_1 = var_0_20:battleAttr(var_16_0, arg_16_0:getElementEquipLevelByID(var_16_0)) * arg_16_0.hero_:getElementEquipActiveRate(var_16_0)
		local var_16_2 = var_0_7:time(arg_16_1:getTableID()) + arg_16_1.level_ * arg_16_1:getTimeStep()
		local var_16_3 = true

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_16_3 = arg_16_0.isHit_[tostring(var_0_1.ctx.battle.count)] or true
		else
			var_16_3 = var_0_2.weightedChoise({
				var_16_1,
				1 - var_16_1
			}) == 1
			arg_16_0.records_.is_hit[tostring(var_0_1.ctx.battle.count)] = var_16_3
		end

		if var_16_3 then
			arg_16_1:setExtraTime(var_0_22 * var_16_2)
		end
	end
end

function var_0_3.setupReport(arg_17_0, arg_17_1)
	var_0_3.super.setupReport(arg_17_0, arg_17_1)

	arg_17_0.isHit_ = arg_17_1.is_hit or {}
end

function var_0_3.writeReport(arg_18_0)
	local var_18_0 = var_0_3.super.writeReport(arg_18_0)

	var_18_0.is_hit = arg_18_0.records_.is_hit

	return var_18_0
end

return var_0_3
