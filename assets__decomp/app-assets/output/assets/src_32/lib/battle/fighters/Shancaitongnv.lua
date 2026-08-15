local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shancaitongnv", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = 0.13
local var_0_5 = 300
local var_0_6 = 10001632
local var_0_7 = 10001633
local var_0_8 = 0.005
local var_0_9 = 40012470
local var_0_10 = 0.1
local var_0_11 = 0.25
local var_0_12 = var_0_2.tables.elementEquip
local var_0_13 = 20001503
local var_0_14 = 10002483
local var_0_15 = 40012673
local var_0_16 = 40012674
local var_0_17 = 40012675
local var_0_18 = 40012676
local var_0_19 = 10
local var_0_20 = 10
local var_0_21 = 1.5

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.BlueSkillID = 10002282
	else
		arg_1_0.BlueSkillID = 30010229
	end
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.beforeHp = 0
	arg_2_0.blueHarm = 0
	arg_2_0.hpDifference = 0

	arg_2_0:listenInfo("harm_info")
end

function var_0_3.selectTargetByTypeD3(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.targetTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and (not var_3_0 or math.abs(arg_3_0:getX() - var_3_0:getX()) < math.abs(arg_3_0:getX() - iter_3_1:getX())) then
			var_3_0 = iter_3_1
		end
	end

	return {
		var_3_0
	}
end

function var_0_3.toDoPerFrames(arg_4_0)
	if var_0_1.ctx.battle.count % var_0_5 == 1 and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if var_0_1.ctx.battle.count < var_0_5 then
			arg_4_0.beforeHp = arg_4_0:getHp()
		else
			local var_4_0 = arg_4_0:getHp()

			if var_4_0 < arg_4_0.beforeHp then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_1 = arg_4_0:createAttackUnits({
						arg_4_0
					}, var_0_6)

					for iter_4_0, iter_4_1 in ipairs(var_4_1) do
						iter_4_1:setExtraHarm(var_0_8 * (arg_4_0.beforeHp - var_4_0) * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
						table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
						table.insert(arg_4_0.records_.special_units, iter_4_1)
					end
				end
			else
				local var_4_2

				for iter_4_2, iter_4_3 in ipairs(arg_4_0.selfTeam_) do
					if not iter_4_3:isDeath() and not iter_4_3:isAffected() and iter_4_3 ~= arg_4_0 and (not var_4_2 or math.abs(iter_4_3:getX() - arg_4_0:getX()) < math.abs(var_4_2:getX() - arg_4_0:getX())) then
						var_4_2 = iter_4_3
					end
				end

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_4_3 = arg_4_0:createAttackUnits({
						arg_4_0,
						var_4_2
					}, var_0_7)

					for iter_4_4, iter_4_5 in ipairs(var_4_3) do
						table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
						table.insert(arg_4_0.records_.special_units, iter_4_5)
					end
				end
			end

			arg_4_0.hpDifference = math.abs(var_4_0 - arg_4_0.beforeHp)
			arg_4_0.beforeHp = var_4_0
		end
	end

	if not arg_4_0:isDeath() and arg_4_0.skinSkillIndex_ == 1 then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0:getInfoByKey("harm_info")) do
			if iter_4_7.fighter == arg_4_0 then
				local var_4_4 = iter_4_7.harm
				local var_4_5 = arg_4_0:createNewBuffs({
					var_0_9
				}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				var_4_5[1].manualHarmRevise = var_0_10 * var_4_4

				arg_4_0:addBuffs(var_4_5)
			end
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	arg_5_0.blueHarm = arg_5_0.blueHarm + arg_5_4

	return var_0_3.super.updateUnitDataByTarget(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataByFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	if arg_6_0.hpDifference > 0 and arg_6_4 > 0 then
		arg_6_4 = arg_6_4 + var_0_11 * arg_6_0.hpDifference
		arg_6_0.hpDifference = 0
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	if arg_7_1.skillID == arg_7_0.BlueSkillID then
		arg_7_1:setExtraHarm(arg_7_0.blueHarm * var_0_4)

		arg_7_0.blueHarm = 0
	end

	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)
end

function var_0_3.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5 = var_0_3.super.applyHurtFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)

	if arg_8_0:hasElementEquipByID(var_0_13) and not arg_8_0:isDeath() and not arg_8_0:isHasBuffByID(var_0_17) then
		if #arg_8_0:getBuffsByID(var_0_15) + 1 >= var_0_20 then
			arg_8_0:removeBuffByID(var_0_15)
			arg_8_0:removeBuffByID(var_0_16)

			local var_8_0 = var_0_13
			local var_8_1 = var_0_12:battleAttr(var_8_0, arg_8_0:getElementEquipLevelByID(var_8_0))
			local var_8_2 = var_0_12:skillIDs(var_8_0)
			local var_8_3 = var_0_12:buffIDs(var_8_0)
			local var_8_4 = arg_8_0.hero_:getElementEquipActiveRate(var_8_0)
			local var_8_5 = arg_8_0:createNewBuffs({
				var_0_17,
				var_0_18
			}, arg_8_0, var_0_14)

			for iter_8_0, iter_8_1 in ipairs(var_8_5) do
				if iter_8_1:getAttrType() == var_0_2.AttributeType.AP then
					iter_8_1.manualRevise = var_8_1 * var_8_4 * var_0_20 * var_0_21
				elseif iter_8_1:getAttrType() == var_0_2.AttributeType.D_MOKANG then
					iter_8_1.manualRevise = var_0_19 * var_0_20 * var_0_21
				end
			end

			arg_8_0:addBuffs(var_8_5)
		else
			local var_8_6 = var_0_13
			local var_8_7 = var_0_12:battleAttr(var_8_6, arg_8_0:getElementEquipLevelByID(var_8_6))
			local var_8_8 = var_0_12:skillIDs(var_8_6)
			local var_8_9 = var_0_12:buffIDs(var_8_6)
			local var_8_10 = arg_8_0.hero_:getElementEquipActiveRate(var_8_6)
			local var_8_11 = arg_8_0:createNewBuffs({
				var_0_15,
				var_0_16
			}, arg_8_0, var_0_14)

			for iter_8_2, iter_8_3 in ipairs(var_8_11) do
				if iter_8_3:getAttrType() == var_0_2.AttributeType.AP then
					iter_8_3.manualRevise = var_8_7 * var_8_10
				elseif iter_8_3:getAttrType() == var_0_2.AttributeType.D_MOKANG then
					iter_8_3.manualRevise = var_0_19
				end
			end

			arg_8_0:addBuffs(var_8_11)
		end
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5
end

function var_0_3.buffRemoveAction(arg_9_0, arg_9_1)
	if arg_9_1:getTableID() == var_0_17 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_14)

		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
			table.insert(arg_9_0.records_.special_units, iter_9_1)
		end
	end
end

return var_0_3
