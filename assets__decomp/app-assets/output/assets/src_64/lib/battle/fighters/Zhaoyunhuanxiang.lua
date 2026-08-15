local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhaoyunhuanxiang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.battleConfig
local var_0_6 = var_0_2.tables.skill
local var_0_7 = var_0_2.tables.hero
local var_0_8 = var_0_2.tables.model
local var_0_9 = 10010062
local var_0_10 = 0.7
local var_0_11 = 10001078
local var_0_12 = 10001079
local var_0_13 = math.max
local var_0_14 = 10001077

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.baoji_ = false
	arg_1_0.isAddBuff = false
end

function var_0_3.updateBaseInfo(arg_2_0)
	var_0_3.super.updateBaseInfo(arg_2_0)

	arg_2_0.isEnergyBuff_ = arg_2_0:isHasBuffByID(var_0_9)
end

function var_0_3.beginAttackEnd(arg_3_0, arg_3_1)
	var_0_3.super.beginAttackEnd(arg_3_0, arg_3_1)
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	local var_4_0 = true

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if iter_4_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_4_1:isDeath() then
			var_4_0 = false
		end
	end

	if var_4_0 then
		arg_4_0:updateHp(0)
		arg_4_0:die()
	end

	if not arg_4_0.isAddBuff and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_4_0.isAddBuff = true

		local var_4_1 = arg_4_0:createAttackUnits({
			arg_4_0
		}, var_0_14)

		for iter_4_2, iter_4_3 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end
end

function var_0_3.getAttrByType(arg_5_0, arg_5_1)
	if arg_5_0.summoner then
		if arg_5_1 == var_0_2.AttributeType.AD or arg_5_1 == var_0_2.AttributeType.HP then
			if not arg_5_0.___attrCache[arg_5_1] then
				local var_5_0 = arg_5_0.summoner.hero_:getBattleAttr(arg_5_1) * var_0_10
				local var_5_1, var_5_2 = arg_5_0:getBuffAttrChange(arg_5_1)
				local var_5_3 = var_0_13(1 + var_5_2, 0) * var_5_0 + var_5_1

				arg_5_0.___attrCache[arg_5_1] = var_0_13(var_5_3, 0)
			end

			return arg_5_0.___attrCache[arg_5_1]
		end

		if not arg_5_0.___attrCache[arg_5_1] then
			local var_5_4 = arg_5_0.summoner.hero_:getBattleAttr(arg_5_1)
			local var_5_5, var_5_6 = arg_5_0:getBuffAttrChange(arg_5_1)
			local var_5_7 = var_0_13(1 + var_5_6, 0) * var_5_4 + var_5_5

			arg_5_0.___attrCache[arg_5_1] = var_0_13(var_5_7, 0)
		end

		return arg_5_0.___attrCache[arg_5_1]
	else
		return var_0_3.super.getAttrByType(arg_5_0, arg_5_1)
	end
end

function var_0_3.getOrbOfFrontSkill(arg_6_0)
	if arg_6_0.isEnergyBuff_ then
		if arg_6_0.baoji_ then
			return var_0_12
		else
			return var_0_11
		end
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_6_0)
end

function var_0_3.popSkillByType(arg_7_0)
	if arg_7_0.isEnergyBuff_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_7_0:baojiPredict()
	end

	return var_0_3.super.popSkillByType(arg_7_0)
end

function var_0_3.baojiPredict(arg_8_0)
	local var_8_0 = arg_8_0:getNearestTarget()

	if not var_8_0 then
		return
	end

	local var_8_1 = arg_8_0:getADBaoJi() / (var_0_5.hujiaBaojiParam1 * math.max(var_8_0:getHuJia() - arg_8_0:getDHuJia(), 0) + var_0_5.hujiaBaojiParam2) + arg_8_0:getBothBaoji()
	local var_8_2 = math.min(1, var_8_1)

	if var_0_2.weightedChoise({
		var_8_2,
		1 - var_8_2
	}) == 1 then
		arg_8_0.baoji_ = true
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_1.skillID == var_0_12 and arg_9_3 ~= true then
		arg_9_4 = arg_9_4 * (arg_9_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_9_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_9_6 = arg_9_6 * (arg_9_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_9_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_9_3 = true
	elseif arg_9_1.skillID == var_0_11 and arg_9_3 == true then
		arg_9_4 = arg_9_4 / (arg_9_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_9_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_9_6 = arg_9_6 / (arg_9_0:getADBaoJiHarm() / var_0_2.DECIMAL_BASE + arg_9_0:getBothBaojiHarm() / var_0_2.DECIMAL_BASE)
		arg_9_3 = false
	end

	if arg_9_1.skillID == var_0_11 or arg_9_1.skillID == var_0_12 then
		arg_9_0.baoji_ = false
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.getTargets(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}
	local var_10_1 = var_0_6:selectType(arg_10_1)

	if arg_10_0.isEnergyBuff_ and arg_10_0.summoner.killer_ and not arg_10_0.summoner.killer_:isDeath() and not arg_10_0.summoner.killer_:isAffected() and arg_10_0.summoner.killer_:getSummonType() and arg_10_0.summoner.killer_:getSummonType() ~= arg_10_0:getSummonType() then
		return {
			arg_10_0.summoner.killer_
		}
	end

	if arg_10_0:isChaos() then
		arg_10_0:changeTeamCache()
	end

	if arg_10_0["selectTargetByType" .. var_10_1] then
		var_10_0 = arg_10_0["selectTargetByType" .. var_10_1](arg_10_0, arg_10_1, arg_10_2)
	else
		var_10_0 = var_0_4[var_10_1](arg_10_0, arg_10_1, arg_10_2)
	end

	return var_10_0
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	if arg_11_1:getTableID() == var_0_9 then
		arg_11_0:updateHp(0)
		arg_11_0:die()
	end
end

return var_0_3
