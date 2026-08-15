local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Diaochan", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 3
local var_0_10 = 80010043
local var_0_11 = 80110043
local var_0_12 = 40012091
local var_0_13 = 120
local var_0_14 = var_0_2.tables.elementEquip
local var_0_15 = 20001458
local var_0_16 = 0.3
local var_0_17 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("buff_harm")

	arg_1_0.cureRate = 0
	arg_1_0.cureHpCount = 0
	arg_1_0.addBuffCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.maxHp then
		arg_2_0.maxHp = arg_2_0:getHpLimit()
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_10 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
			if iter_2_1:getType() == var_0_2.BuffType.CONTINUE_HARM and iter_2_1.target:getTeamType() ~= arg_2_0:getTeamType() and iter_2_1.fighter:getTeamType() == arg_2_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits({
					arg_2_0
				}, var_0_10)

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_11 then
		for iter_2_4, iter_2_5 in ipairs(arg_2_0:getInfoByKey("buff_harm")) do
			local var_2_1 = iter_2_5.buff
			local var_2_2 = iter_2_5.target
			local var_2_3 = iter_2_5.harm

			if not arg_2_0.addBuffCount[var_0_1.ctx.battle.count] then
				arg_2_0.addBuffCount[var_0_1.ctx.battle.count] = {}
			end

			if var_2_1:getTableID() ~= var_0_12 and var_2_2:getTeamType() ~= arg_2_0:getTeamType() and var_2_1:getType() == var_0_2.BuffType.CONTINUE_HARM and not arg_2_0.addBuffCount[var_0_1.ctx.battle.count][var_2_1:getTableID()] then
				arg_2_0.addBuffCount[var_0_1.ctx.battle.count][var_2_1:getTableID()] = true

				local var_2_4 = arg_2_0:getSkinSkillTarget(var_2_2)

				for iter_2_6 = 1, #var_2_4 do
					local var_2_5 = var_0_4.new({
						level = 1,
						tableID = var_0_12,
						start = var_0_1.ctx.battle.count,
						skillID = var_0_11,
						fighter = arg_2_0,
						target = var_2_4[iter_2_6],
						manualHarmRevise = var_2_3
					})

					var_2_4[iter_2_6]:addBuffs({
						var_2_5
					})
				end
			end
		end
	end
end

function var_0_3.getSkinSkillTarget(arg_3_0, arg_3_1)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.sideTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_1 and math.abs(iter_3_1:getX() - arg_3_1:getX()) <= var_0_13 then
			table.insert(var_3_0, iter_3_1)
		end
	end

	return var_3_0
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)

	if arg_4_1.skillID == var_0_11 then
		arg_4_4 = arg_4_1.skinHarm
	end

	return arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7
end

function var_0_3.checkUnitBuffs(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1.target

	if var_5_0:isDeath() then
		return
	end

	local var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = arg_5_1:getBuffs(arg_5_2)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		for iter_5_0, iter_5_1 in ipairs(var_5_1) do
			local var_5_6 = var_5_0:getBuffsByID(iter_5_1:getTableID())

			for iter_5_2, iter_5_3 in ipairs(var_5_6) do
				iter_5_3.leftCount_ = iter_5_3:getTime()
			end

			if #var_5_6 == var_0_9 then
				var_5_0:removeBuffs(var_5_6[1])
			end
		end
	end

	return var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = var_0_5.B1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_1

	if var_6_0 and next(var_6_0) then
		var_6_1 = var_6_0[1]
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1 ~= var_6_1 then
			local var_6_2 = false

			for iter_6_2, iter_6_3 in ipairs(iter_6_1:getBuffs()) do
				if iter_6_3:getType() == var_0_2.BuffType.CONTINUE_HARM then
					var_6_2 = true

					break
				end
			end

			if var_6_2 then
				table.insert(var_6_0, iter_6_1)
			end
		end
	end

	return var_6_0
end

function var_0_3.updateBuffDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	if arg_7_1 and next(arg_7_1) then
		for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
			local var_7_0 = iter_7_1.target
			local var_7_1 = iter_7_1.fighter

			if arg_7_0:hasElementEquipByID(var_0_15) and var_7_0:getTeamType() ~= arg_7_0:getTeamType() and var_7_1 == arg_7_0 and iter_7_1:getType() == var_0_2.BuffType.CONTINUE_HARM then
				local var_7_2 = var_0_15
				local var_7_3 = var_0_14:battleAttr(var_7_2, arg_7_0:getElementEquipLevelByID(var_7_2))
				local var_7_4 = arg_7_0.hero_:getElementEquipActiveRate(var_7_2)
				local var_7_5 = arg_7_2 * var_7_3 * var_7_4 * arg_7_0:getDCureRate()
				local var_7_6 = math.min(arg_7_0:getHpLimit(), arg_7_0:getHp() + var_7_5)

				arg_7_0:updateHp(var_7_6)

				arg_7_0.cureHpCount = arg_7_0.cureHpCount + var_7_5

				if arg_7_0.cureHpCount >= arg_7_0.maxHp * var_0_16 then
					local var_7_7 = arg_7_0:getEnergy()

					arg_7_0:updateEnergyBy(var_7_7 + var_0_17)

					arg_7_0.cureHpCount = 0
				end
			end
		end
	end

	return arg_7_2, arg_7_3, arg_7_4
end

return var_0_3
