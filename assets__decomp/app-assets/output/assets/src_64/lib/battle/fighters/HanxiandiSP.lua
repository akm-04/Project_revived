local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("HanxiandiSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_8 = 40012508
local var_0_9 = 40012509
local var_0_10 = 60
local var_0_11 = 10
local var_0_12 = 5
local var_0_13 = 10002318
local var_0_14 = 10002319
local var_0_15 = 10002320
local var_0_16 = 10002321
local var_0_17 = 10002322
local var_0_18 = 0.3
local var_0_19 = 0.003
local var_0_20 = 0.2
local var_0_21 = 40012512
local var_0_22 = 10002330
local var_0_23 = 40012510
local var_0_24 = 0.3
local var_0_25 = 0.003
local var_0_26 = 150
local var_0_27 = 1.5
local var_0_28 = 400
local var_0_29 = math.abs

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleTargetCache_ = {}
	arg_1_0.blueEffect_ = nil
	arg_1_0.blueCount = 0
	arg_1_0.bluePosX_ = 0
	arg_1_0.bluePosY_ = 0
end

function var_0_3.ctor(arg_2_0, arg_2_1)
	var_0_3.super.ctor(arg_2_0, arg_2_1)
	arg_2_0:listenInfo("buff_info")
	arg_2_0:listenInfo("move_info")
end

function var_0_3.hasBlueBuff(arg_3_0, arg_3_1)
	if arg_3_1:getBuffByID(var_0_23) then
		return true
	end

	return false
end

function var_0_3.singleLoop(arg_4_0)
	var_0_3.super.singleLoop(arg_4_0)
	arg_4_0:purpleSkill()

	if arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
			if iter_4_1:getTableID() == var_0_8 then
				local var_4_0 = iter_4_1.target
				local var_4_1 = #var_4_0:getBuffsByID(var_0_8)

				if var_4_0 and not var_4_0:isDeath() and var_4_0:getTeamType() ~= arg_4_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					if var_4_1 == var_0_12 - 1 then
						local var_4_2 = var_0_16
						local var_4_3 = {
							var_4_0
						}
						local var_4_4 = arg_4_0:createAttackUnits(var_4_3, var_4_2)

						for iter_4_2, iter_4_3 in ipairs(var_4_4) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
							table.insert(arg_4_0.records_.special_units, iter_4_3)
						end
					elseif var_4_1 >= var_0_11 - 1 then
						local var_4_5 = var_0_17
						local var_4_6 = {
							var_4_0
						}
						local var_4_7 = arg_4_0:createAttackUnits(var_4_6, var_4_5)

						for iter_4_4, iter_4_5 in ipairs(var_4_7) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
							table.insert(arg_4_0.records_.special_units, iter_4_5)
						end
					end
				end

				if var_4_0:isHasBuffByID(var_0_23) then
					local var_4_8 = var_4_0:getBuffsByID(var_0_8)

					for iter_4_6, iter_4_7 in ipairs(var_4_8) do
						if iter_4_7.manualHarmRevise == 0 then
							local var_4_9 = var_0_24 + var_0_25 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

							iter_4_7.manualHarmRevise = iter_4_7:getHarm() * var_4_9
						end
					end

					local var_4_10 = var_4_0:getBuffsByID(var_0_9)

					for iter_4_8, iter_4_9 in ipairs(var_4_10) do
						if iter_4_9.manualRevise == 0 then
							local var_4_11 = var_0_24 + var_0_25 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

							iter_4_9.manualRevise = iter_4_9:getAttr() * var_4_11
						end
					end
				end
			elseif iter_4_1:getTableID() == var_0_23 then
				local var_4_12 = iter_4_1.target
				local var_4_13 = var_4_12:getBuffsByID(var_0_8)

				for iter_4_10, iter_4_11 in ipairs(var_4_13) do
					if iter_4_11.manualHarmRevise == 0 then
						local var_4_14 = var_0_24 + var_0_25 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

						iter_4_11.manualHarmRevise = iter_4_11:getHarm() * var_4_14
					end
				end

				local var_4_15 = var_4_12:getBuffsByID(var_0_9)

				for iter_4_12, iter_4_13 in ipairs(var_4_15) do
					if iter_4_13.manualRevise == 0 then
						local var_4_16 = var_0_24 + var_0_25 * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

						iter_4_13.manualRevise = iter_4_13:getAttr() * var_4_16
					end
				end
			end
		end
	end

	if arg_4_0.blueCount > 0 then
		arg_4_0.blueCount = arg_4_0.blueCount - 1

		if arg_4_0.blueCount <= 0 then
			arg_4_0.bluePosX_ = 0
			arg_4_0.bluePosY_ = 0
			arg_4_0.blueCount = 0

			arg_4_0:finishBlueEffect()
		else
			arg_4_0:addOrRemoveBlueBuff()
		end
	end
end

function var_0_3.purpleSkill(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or arg_5_0:getX() < 0 or arg_5_0:getX() > var_0_2.STAGE_WIDTH then
		return
	end

	local var_5_0 = arg_5_0:getInfoByKey("move_info")

	if not var_5_0 or not next(var_5_0) then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		if iter_5_1.fighter and not iter_5_1.fighter:isAffected() and iter_5_1.fighter:getTeamType() ~= arg_5_0:getTeamType() and iter_5_1.fighter:getX() > 0 and iter_5_1.fighter:getX() < var_0_2.STAGE_WIDTH then
			arg_5_0:updatePurpleSkill(iter_5_1.fighter)
		end
	end
end

function var_0_3.updatePurpleSkill(arg_6_0, arg_6_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_6_0.purpleTargetCache_[arg_6_1] or arg_6_0.purpleTargetCache_[arg_6_1] and var_0_1.ctx.battle.count - arg_6_0.purpleTargetCache_[arg_6_1] > var_0_10 then
		local var_6_0 = var_0_18 + var_0_19 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_0_2.weightedChoise({
			var_6_0,
			1 - var_6_0
		}) == 1 then
			arg_6_0.purpleTargetCache_[arg_6_1] = var_0_1.ctx.battle.count

			local var_6_1 = var_0_15
			local var_6_2 = {
				arg_6_1
			}
			local var_6_3 = arg_6_0:createAttackUnits(var_6_2, var_6_1)

			for iter_6_0, iter_6_1 in ipairs(var_6_3) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	end
end

function var_0_3.finishBlueEffect(arg_7_0)
	if arg_7_0.blueEffect_ and var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_7_0.blueEffect_:runActionOnce(cc.FadeOut:create(0.4 / (arg_7_0.timeScale_ or 1)), false, function()
			arg_7_0.blueEffect_:setVisible(false)
			arg_7_0.blueEffect_:setOpacity(255)

			arg_7_0.blueEffect_ = nil

			for iter_8_0, iter_8_1 in pairs(arg_7_0.sideTeam_) do
				if not iter_8_1:isDeath() and iter_8_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
					local var_8_0 = iter_8_1:getBuffByID(var_0_23)

					if var_8_0 and var_8_0.fighter == arg_7_0 then
						iter_8_1:removeBuffByID(var_0_23)
					end
				end
			end
		end, 1)
	end
end

function var_0_3.addOrRemoveBlueBuff(arg_9_0)
	for iter_9_0, iter_9_1 in pairs(arg_9_0.sideTeam_) do
		if not iter_9_1:isDeath() and iter_9_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
			if not arg_9_0:hasBlueBuff(iter_9_1) and arg_9_0:checkIsInBlueEffect(iter_9_1) then
				local var_9_0 = var_0_6.new({
					tableID = var_0_23,
					start = var_0_1.ctx.battle.count,
					level = arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
					skillID = arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
					fighter = arg_9_0,
					target = iter_9_1
				})

				iter_9_1:addBuffs({
					var_9_0
				})
			elseif not arg_9_0:checkIsInBlueEffect(iter_9_1) then
				local var_9_1 = iter_9_1:getBuffByID(var_0_23)

				if var_9_1 and var_9_1.fighter == arg_9_0 then
					iter_9_1:removeBuffByID(var_0_23)
				end
			end
		end
	end
end

function var_0_3.checkIsInBlueEffect(arg_10_0, arg_10_1)
	if arg_10_0.blueEffect_ and arg_10_0.bluePosX_ ~= 0 and not arg_10_1:isDeath() and not arg_10_1:isAffected() and arg_10_1:getSummonType() ~= var_0_2.summonMonsterType.Pet then
		if var_0_29(arg_10_1:getX() - arg_10_0.bluePosX_) < var_0_28 / 2 then
			return true
		else
			return false
		end
	end

	return false
end

function var_0_3.moveUnitArrive(arg_11_0, arg_11_1)
	if arg_11_1.resource then
		arg_11_1.resource:stop()
	end

	arg_11_1:arrive()

	if arg_11_1:getAreaResource() then
		local var_11_0 = arg_11_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_11_1.fighter:getY() or arg_11_1.desY_
		local var_11_1 = arg_11_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_11_1.fighter:getX() or arg_11_1.desX_

		arg_11_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)

		if arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
			arg_11_0.bluePosX_ = var_11_1
			var_11_0 = 420
			arg_11_0.bluePosY_ = var_11_0
			arg_11_0.blueEffect_ = arg_11_1:getAreaResource()

			arg_11_0.blueEffect_:setVisible(true)

			arg_11_0.blueCount = var_0_26 + var_0_27 * arg_11_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)
		end

		arg_11_1:getAreaResource():pos(var_11_1, var_11_0)
		arg_11_1:getAreaResource():playRepeat()
		arg_11_1:getAreaResource():flipX(arg_11_1.fighter:getX() > arg_11_1.desX_)
		arg_11_1:getAreaResource():setScale(0.4)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_11_2 = arg_11_1:getReportUnits()

		for iter_11_0, iter_11_1 in ipairs(var_11_2) do
			table.insert(arg_11_0.applyUnits_, iter_11_1)
		end
	else
		local var_11_3 = arg_11_0:getTargets(arg_11_1.skillID, arg_11_1)

		if next(var_11_3) then
			local var_11_4 = arg_11_1:createAttacks(var_11_3)

			for iter_11_2, iter_11_3 in ipairs(var_11_4) do
				table.insert(arg_11_0.applyUnits_, iter_11_3)
			end
		end
	end
end

function var_0_3.buffAddAction(arg_12_0, arg_12_1)
	var_0_3.super.buffAddAction(arg_12_0, arg_12_1)

	local var_12_0 = arg_12_1.target

	if arg_12_1:getTableID() == var_0_8 then
		if var_12_0:isHasBuffByID(var_0_23) then
			local var_12_1 = var_0_24 + var_0_25 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

			arg_12_1.manualHarmRevise = arg_12_1:getHarm() * var_12_1
		end
	elseif arg_12_1:getTableID() == var_0_9 then
		if var_12_0:isHasBuffByID(var_0_23) then
			local var_12_2 = var_0_24 + var_0_25 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

			arg_12_1.manualRevise = arg_12_1:getAttr() * var_12_2
		end
	elseif arg_12_1:getTableID() == var_0_23 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_12_3 = var_0_22
		local var_12_4 = {
			var_12_0
		}
		local var_12_5 = arg_12_0:createAttackUnits(var_12_4, var_12_3)

		for iter_12_0, iter_12_1 in ipairs(var_12_5) do
			table.insert(arg_12_0.moveAttackUnits_, iter_12_1)
			table.insert(arg_12_0.records_.special_units, iter_12_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_13_0, arg_13_1)
	var_0_3.super.buffRemoveAction(arg_13_0, arg_13_1)

	if arg_13_1:getTableID() == var_0_23 then
		local var_13_0 = arg_13_1.target
		local var_13_1 = var_13_0:getBuffsByID(var_0_8)

		for iter_13_0, iter_13_1 in ipairs(var_13_1) do
			iter_13_1.manualHarmRevise = 0
		end

		local var_13_2 = var_13_0:getBuffsByID(var_0_9)

		for iter_13_2, iter_13_3 in ipairs(var_13_2) do
			iter_13_3.manualRevise = 0
		end
	elseif arg_13_1:getTableID() == var_0_8 then
		local var_13_3 = arg_13_1.target

		if var_13_3:isHasBuffByID(var_0_21) then
			var_13_3:removeBuffByID(var_0_21)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)
	arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_14_0, arg_14_1, arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7)

	if arg_14_5 > 0 and arg_14_1.target:isHasBuffByID(var_0_21) then
		local var_14_0 = arg_14_5 * var_0_20
		local var_14_1 = arg_14_0:createAttackUnits({
			arg_14_0
		}, arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_14_0, iter_14_1 in ipairs(var_14_1) do
			iter_14_1.cure_num = var_14_0

			table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
			table.insert(arg_14_0.records_.special_units, iter_14_1)
		end

		arg_14_5 = arg_14_5 - var_14_0
	end

	return arg_14_2, arg_14_3, arg_14_4, arg_14_5, arg_14_6, arg_14_7
end

function var_0_3.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)
	arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7 = var_0_3.super.updateUnitDataByFighter(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7)

	if arg_15_1.skillID == arg_15_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) and arg_15_1.cure_num and arg_15_1.cure_num > 0 then
		arg_15_5 = arg_15_5 + arg_15_1.cure_num
	end

	return arg_15_2, arg_15_3, arg_15_4, arg_15_5, arg_15_6, arg_15_7
end

function var_0_3.unitAfterCreate(arg_16_0, arg_16_1, arg_16_2)
	var_0_3.super.unitAfterCreate(arg_16_0, arg_16_1, arg_16_2)

	if arg_16_1 and arg_16_1.skillID == var_0_13 then
		local var_16_0 = arg_16_0:getTargets(var_0_14)

		if next(var_16_0) then
			arg_16_1:setDesition(var_16_0[1]:getX())
		end
	end
end

return var_0_3
