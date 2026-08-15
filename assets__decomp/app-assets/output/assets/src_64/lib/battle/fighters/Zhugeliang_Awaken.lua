local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhugeliang", var_0_1.ctx.battle.requireFighter("Zhugeliang"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	wind = 50010144,
	water = 50030144,
	thunder = 50050144,
	fire = 50040144,
	dark = 50020144
}
local var_0_7 = {
	wind = 60010144,
	water = 60030144,
	thunder = 60050144,
	fire = 60040144,
	dark = 60020144
}
local var_0_8 = {
	wind = 345,
	fire = 205,
	thunder = 120,
	water = 121,
	dark = 112
}
local var_0_9 = 0
local var_0_10 = 0.003
local var_0_11 = 4
local var_0_12 = 18
local var_0_13 = 4
local var_0_14 = 180
local var_0_15 = 0
local var_0_16 = 0.006
local var_0_17 = 40011232
local var_0_18 = 10001121
local var_0_19 = 0
local var_0_20 = 0.001
local var_0_21 = 300
local var_0_22 = 15
local var_0_23 = 40011443
local var_0_24 = 0.15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeDarkDieHero_ = 0
	arg_1_0.awakeDarkDieMonster_ = 0
	arg_1_0.awakeWindCount_ = 0
	arg_1_0.records_.skill_immortal = {}
	arg_1_0.records_.hit_buff = {}
	arg_1_0.awakeFireBuffCDCount = 0
	arg_1_0.awakeFireCureCDCount = 0
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ ~= arg_2_0:getPugongID() and arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) == var_0_7.wind then
		local var_2_0

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_2_0 = arg_2_0.skillImmortal_[tostring(var_0_1.ctx.battle.count)]
		else
			local var_2_1 = var_0_9 + var_0_10 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

			var_2_0 = var_0_2.weightedChoise({
				var_2_1,
				1 - var_2_1
			}) == 1
			arg_2_0.records_.skill_immortal[tostring(var_0_1.ctx.battle.count)] = var_2_0
		end

		if var_2_0 then
			arg_2_0:setImmuneControl(true)

			arg_2_0.awakeWindCount_ = var_0_14
		end
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	arg_3_0.super.toDoPerFrames(arg_3_0)

	if arg_3_0.awakeWindCount_ > 0 then
		arg_3_0.awakeWindCount_ = arg_3_0.awakeWindCount_ - 1

		if arg_3_0.awakeWindCount_ == 0 then
			arg_3_0:setImmuneControl(false)
		end
	end

	if arg_3_0.awakeFireBuffCDCount > 0 then
		arg_3_0.awakeFireBuffCDCount = arg_3_0.awakeFireBuffCDCount - 1
	end

	if arg_3_0.awakeFireCureCDCount > 0 then
		arg_3_0.awakeFireCureCDCount = arg_3_0.awakeFireCureCDCount - 1
	end
end

function var_0_3.fliterBuffs(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:getSkillLevelByID(var_0_7.thunder) * 0.003
	local var_4_1

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_4_1 = arg_4_0.hitBuff_[tostring(var_0_1.ctx.battle.count)] or false
	else
		var_4_1 = var_0_2.weightedChoise({
			var_4_0,
			1 - var_4_0
		}) == 1
		arg_4_0.records_.hit_buff[tostring(var_0_1.ctx.battle.count)] = var_4_1
	end

	if var_4_1 then
		for iter_4_0 = #arg_4_1, 1, -1 do
			local var_4_2 = arg_4_1[iter_4_0]

			if var_4_2:isFear() or var_4_2:isApUnable() or var_4_2:isAdUnable() or var_4_2:isExcuteAdCircle() or var_4_2:isAttackFriend() or var_4_2:isPugongOnly() then
				table.remove(arg_4_1, iter_4_0)
			end
		end
	end

	var_0_3.super.fliterBuffs(arg_4_0, arg_4_1)
end

function var_0_3.energyAction(arg_5_0, arg_5_1)
	arg_5_0.super.energyAction(arg_5_0, arg_5_1)

	if var_0_5:father(arg_5_1) == arg_5_0:getEnergySkillID() and arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) == var_0_7.fire and arg_5_0.awakeFireBuffCDCount <= 0 then
		local var_5_0 = var_0_4.new({
			tableID = var_0_17,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
			skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
			fighter = arg_5_0,
			target = arg_5_0
		})

		for iter_5_0, iter_5_1 in pairs(var_0_6) do
			if iter_5_1 == arg_5_0:getEnergySkillID() then
				local var_5_1 = var_0_8[iter_5_0]

				if (arg_5_0.extraSkillBookLevel.fire or 0) > 0 then
					var_5_1 = var_5_1 + arg_5_0.extraSkillBookLevel.fire * var_0_24
				end

				var_5_0:setExtraTime(var_5_1)

				arg_5_0.awakeFireBuffCDCount = var_0_21 + var_0_8[iter_5_0]
			end
		end

		arg_5_0:addBuffs({
			var_5_0
		})
	end
end

function var_0_3.isBreakImmortal(arg_6_0)
	return arg_6_0.isImmuneControl or arg_6_0:getBuffByID(var_0_17)
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0, var_7_1, var_7_2, var_7_3 = arg_7_0.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if arg_7_1.skillID ~= var_0_18 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_0:getBuffByID(var_0_17) and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) > 0 and arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) == var_0_7.fire and arg_7_0.awakeFireCureCDCount <= 0 then
		local var_7_4 = arg_7_0:getTargets(var_0_7.water)
		local var_7_5 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_18)

		for iter_7_0, iter_7_1 in ipairs(var_7_5) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end

		arg_7_0.awakeFireCureCDCount = var_0_22
	end

	return var_7_0, var_7_1, var_7_2, var_7_3
end

function var_0_3.getUnitData(arg_8_0, arg_8_1)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = arg_8_0.super.getUnitData(arg_8_0, arg_8_1)

	if arg_8_1.skillID == var_0_18 then
		var_8_3 = (arg_8_0:getHpLimit() - arg_8_0:getHp()) * (var_0_19 + var_0_20 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.deathFeedback(arg_9_0, arg_9_1)
	var_0_3.super.deathFeedback(arg_9_0, arg_9_1)

	if arg_9_1:getSummonType() == var_0_2.summonMonsterType.None then
		arg_9_0.awakeDarkDieHero_ = arg_9_0.awakeDarkDieHero_ + 1
	else
		arg_9_0.awakeDarkDieMonster_ = arg_9_0.awakeDarkDieMonster_ + 1
	end
end

function var_0_3.getAP(arg_10_0)
	local var_10_0 = var_0_3.super.getAP(arg_10_0)
	local var_10_1 = 0

	if arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) == var_0_7.dark then
		var_10_1 = arg_10_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * (arg_10_0.awakeDarkDieMonster_ * var_0_11 + arg_10_0.awakeDarkDieHero_ * var_0_12)
		var_10_1 = math.min(var_10_0 * var_0_13, var_10_1)
	end

	return var_10_0 + var_10_1
end

function var_0_3.setupReport(arg_11_0, arg_11_1)
	var_0_3.super.setupReport(arg_11_0, arg_11_1)

	arg_11_0.skillImmortal_ = arg_11_1.skill_immortal or {}
	arg_11_0.hitBuff_ = arg_11_1.hit_buff or {}
end

function var_0_3.writeReport(arg_12_0)
	local var_12_0 = var_0_3.super.writeReport(arg_12_0)

	var_12_0.skill_immortal = arg_12_0.records_.skill_immortal
	var_12_0.hit_buff = arg_12_0.records_.hit_buff

	return var_12_0
end

function var_0_3.applySingleUnit(arg_13_0, arg_13_1)
	arg_13_0.super.applySingleUnit(arg_13_0, arg_13_1)

	if arg_13_1.skillID == var_0_7.water then
		arg_13_0:summonWaters(arg_13_1.target, nil, false)
	end
end

function var_0_3.playShanbi(arg_14_0, arg_14_1)
	var_0_3.super.playShanbi(arg_14_0, arg_14_1)

	if arg_14_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) == var_0_7.water and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_14_0 = var_0_15 + var_0_16 * arg_14_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake)

		if var_0_2.weightedChoise({
			var_14_0,
			1 - var_14_0
		}) == 1 then
			local var_14_1 = arg_14_0:getTargets(var_0_7.water)
			local var_14_2 = arg_14_0:createAttackUnits(var_14_1, var_0_7.water)

			for iter_14_0, iter_14_1 in ipairs(var_14_2) do
				table.insert(arg_14_0.moveAttackUnits_, iter_14_1)
				table.insert(arg_14_0.records_.special_units, iter_14_1)
			end
		end
	end
end

return var_0_3
