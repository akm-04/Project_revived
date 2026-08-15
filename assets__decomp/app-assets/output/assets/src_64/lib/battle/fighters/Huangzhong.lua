local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangzhong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000989
local var_0_8 = 40011094
local var_0_9 = 21
local var_0_10 = 10000995
local var_0_11 = 1
local var_0_12 = var_0_2.tables.elementEquip
local var_0_13 = 20001489
local var_0_14 = 10002362
local var_0_15 = 40012568
local var_0_16 = 40012569
local var_0_17 = 40012570
local var_0_18 = 40012571

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.blueSkillCount_ = 0
	arg_2_0.isAddSkinBuff = false
end

function var_0_3.singleLoop(arg_3_0)
	var_0_3.super.singleLoop(arg_3_0)
	arg_3_0:skinSkill()
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_0.isSkinSkillOn_ and not arg_4_0.isAddSkinBuff and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) >= 1 and arg_4_1.rootID_ == var_0_10 then
		arg_4_0.blueSkillCount_ = arg_4_0.blueSkillCount_ + 1
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("buff_info")) do
		if arg_5_0:hasElementEquipByID(var_0_13) and (iter_5_1:getTableID() == var_0_15 or iter_5_1:getTableID() == var_0_15) then
			local var_5_0 = arg_5_0:getBuffsByID(var_0_15)
			local var_5_1 = arg_5_0:getBuffsByID(var_0_16)

			if #var_5_0 >= 4 and #var_5_1 >= 4 then
				local var_5_2 = var_0_13
				local var_5_3 = var_0_12:battleAttr(var_5_2, arg_5_0:getElementEquipLevelByID(var_5_2))
				local var_5_4 = arg_5_0.hero_:getElementEquipActiveRate(var_5_2)
				local var_5_5 = arg_5_0:createNewBuffs({
					var_0_17
				}, arg_5_0, arg_5_0:getEnergySkillID())

				for iter_5_2, iter_5_3 in ipairs(var_5_5) do
					iter_5_3.manualRevise = var_5_3 * var_5_4 * 6
				end

				local var_5_6 = arg_5_0:createNewBuffs({
					var_0_18
				}, arg_5_0, arg_5_0:getEnergySkillID())

				arg_5_0:addBuffs(var_5_5)
				arg_5_0:addBuffs(var_5_6)
			end
		elseif iter_5_1:getTableID() == var_0_17 then
			arg_5_0:removeBuffByID(var_0_15)
		elseif iter_5_1:getTableID() == var_0_18 then
			arg_5_0:removeBuffByID(var_0_16)
		end
	end
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_1.skillID == var_0_10 and arg_6_0.blueSkillCount_ >= var_0_11 and arg_6_0.isSkinSkillOn_ and not arg_6_0.isAddSkinBuff and arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) >= 1 then
		arg_6_0.isAddSkinBuff = true

		local var_6_0 = arg_6_0:newBuff({
			var_0_8
		}, arg_6_0, var_0_7)

		arg_6_0:addBuffs(var_6_0)
	end

	if arg_6_1.skillID == var_0_14 then
		local var_6_1 = var_0_13
		local var_6_2 = var_0_12:battleAttr(var_6_1, arg_6_0:getElementEquipLevelByID(var_6_1))
		local var_6_3 = arg_6_0.hero_:getElementEquipActiveRate(var_6_1)
		local var_6_4 = arg_6_0:createNewBuffs({
			var_0_15
		}, arg_6_0, arg_6_0:getEnergySkillID())

		for iter_6_0, iter_6_1 in ipairs(var_6_4) do
			iter_6_1.manualRevise = var_6_2 * var_6_3
		end

		local var_6_5 = arg_6_0:createNewBuffs({
			var_0_16
		}, arg_6_0, arg_6_0:getEnergySkillID())

		arg_6_0:addBuffs(var_6_4)
		arg_6_0:addBuffs(var_6_5)
	end
end

function var_0_3.skinSkill(arg_7_0)
	if not arg_7_0.isSkinSkillOn_ or not arg_7_0.isAddSkinBuff then
		return
	end

	if arg_7_0:isDeath() or arg_7_0:isAffected() or arg_7_0:isBattleUnable() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % var_0_9 == 0 then
		local var_7_0 = arg_7_0:getTargets(var_0_7)

		if var_7_0 and next(var_7_0) then
			local var_7_1 = var_0_6:attackIndex(var_0_7)

			arg_7_0:createSkillByID(var_0_7, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_7_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0:hasElementEquipByID(var_0_13) and arg_8_0:isHasBuffByID(var_0_17) and var_8_2 > 0 then
		var_8_0 = false
	end

	if arg_8_0:hasElementEquipByID(var_0_13) and not arg_8_0:isHasBuffByID(var_0_17) and not var_8_0 and var_8_2 > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_8_6 = var_0_14
		local var_8_7 = arg_8_0:createAttackUnits({
			arg_8_0
		}, var_8_6)

		for iter_8_0, iter_8_1 in ipairs(var_8_7) do
			table.insert(arg_8_0.moveAttackUnits_, iter_8_1)
			table.insert(arg_8_0.records_.special_units, iter_8_1)
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)
	local var_9_0, var_9_1, var_9_2, var_9_3 = var_0_3.super.applyHurtFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5)

	if arg_9_0:isHurtBreak(var_9_0, arg_9_1) and not arg_9_0:isAdBreakImmortal() and not arg_9_0:isBreakImmortal() and arg_9_0.isAddSkinBuff then
		arg_9_0:removeBuffByID(var_0_8)

		arg_9_0.blueSkillCount_ = 0
		arg_9_0.isAddSkinBuff = false
	end

	return var_9_0, var_9_1, var_9_2, var_9_3
end

function var_0_3.skillIsBreak(arg_10_0, arg_10_1)
	var_0_3.super.skillIsBreak(arg_10_0, arg_10_1)

	if arg_10_0.isAddSkinBuff then
		arg_10_0:removeBuffByID(var_0_8)

		arg_10_0.blueSkillCount_ = 0
		arg_10_0.isAddSkinBuff = false
	end
end

function var_0_3.checkSkillBreak(arg_11_0, arg_11_1, arg_11_2)
	var_0_3.super.checkSkillBreak(arg_11_0, arg_11_1, arg_11_2)

	if arg_11_0.isAddSkinBuff then
		arg_11_0:removeBuffByID(var_0_8)

		arg_11_0.blueSkillCount_ = 0
		arg_11_0.isAddSkinBuff = false
	end
end

function var_0_3.newBuff(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		local var_12_1 = var_0_5.new({
			tableID = iter_12_1,
			start = var_0_1.ctx.battle.count,
			level = arg_12_0:getSkillLevelByID(arg_12_3),
			skillID = arg_12_3,
			fighter = arg_12_0,
			target = arg_12_2
		})

		var_12_1:setIsHit(true)
		var_12_1:setDirection(arg_12_0:getFighterModel():getFlipX())
		table.insert(var_12_0, var_12_1)
	end

	return var_12_0
end

return var_0_3
