local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dog", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0.3
local var_0_6 = 0.06
local var_0_7 = 40011758
local var_0_8 = 0.04
local var_0_9 = 40011760
local var_0_10 = 40011755
local var_0_11 = 60
local var_0_12 = 40011753
local var_0_13 = 0.25
local var_0_14 = 40011754

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")

	arg_1_0.rank = 1
end

function var_0_3.forceDie(arg_2_0)
	if arg_2_0.summoner and not arg_2_0.summoner:isDeath() and arg_2_0:canReborn() then
		arg_2_0:forceReborn()

		return
	end

	arg_2_0.super.forceDie(arg_2_0)
end

function var_0_3.canReborn(arg_3_0)
	if not arg_3_0.summoner or arg_3_0.summoner:isDeath() then
		return false
	else
		return true
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_1.basicHarm > 0 and arg_4_0.summoner then
		arg_4_0.summoner:updateEnergyBy(var_0_11)
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.getAttrByType(arg_5_0, arg_5_1)
	if arg_5_0.summoner and (arg_5_1 == var_0_2.AttributeType.HP or arg_5_1 == var_0_2.AttributeType.AD or arg_5_1 == var_0_2.AttributeType.AP or arg_5_1 == var_0_2.AttributeType.HUJIA or arg_5_1 == var_0_2.AttributeType.MOKANG) then
		local var_5_0 = arg_5_0.summoner.hero_:getBattleAttr(arg_5_1) * (var_0_5 + var_0_6 * arg_5_0.rank)
		local var_5_1, var_5_2 = arg_5_0:getBuffAttrChange(arg_5_1)
		local var_5_3 = math.max(1 + var_5_2, 0) * var_5_0 + var_5_1

		arg_5_0.___attrCache[arg_5_1] = math.max(var_5_3, 0)

		return arg_5_0.___attrCache[arg_5_1]
	else
		return arg_5_0.super.getAttrByType(arg_5_0, arg_5_1)
	end
end

function var_0_3.forceReborn(arg_6_0)
	arg_6_0:updateHp(1)

	local var_6_0 = var_0_4.new({
		tableID = var_0_7,
		start = var_0_1.ctx.battle.count,
		level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
		skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
		fighter = arg_6_0,
		target = arg_6_0
	})

	var_6_0.manualHarmRevise = arg_6_0:getHpLimit()

	arg_6_0:addBuffs({
		var_6_0
	})
end

function var_0_3.isReborning(arg_7_0)
	return arg_7_0:isHasBuffByID(var_0_7)
end

function var_0_3.isApUnable(arg_8_0)
	if arg_8_0:isHasBuffByID(var_0_7) then
		return true
	else
		return var_0_3.super.isApUnable(arg_8_0)
	end
end

function var_0_3.isAdUnable(arg_9_0)
	if arg_9_0:isHasBuffByID(var_0_7) then
		return true
	else
		return var_0_3.super.isAdUnable(arg_9_0)
	end
end

function var_0_3.isMoveUnable(arg_10_0)
	if arg_10_0:isHasBuffByID(var_0_7) then
		return true
	else
		return var_0_3.super.isMoveUnable(arg_10_0)
	end
end

function var_0_3.getFrontSkill(arg_11_0)
	local var_11_0 = arg_11_0.super.getFrontSkill(arg_11_0)

	if arg_11_0.rank < 5 and var_11_0 == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		return arg_11_0:getPugongID()
	end

	return var_11_0
end

function var_0_3.updateUnitInfoBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
	if arg_12_1.fighter:getTeamType() ~= arg_12_0:getTeamType() and arg_12_4 > 0 then
		if arg_12_1.fighter:isHasBuffByID(var_0_12) and arg_12_1.attackType == var_0_2.AttackType.AD then
			arg_12_4 = arg_12_4 - arg_12_4 * var_0_13
		elseif arg_12_1.fighter:isHasBuffByID(var_0_14) and arg_12_1.attackType == var_0_2.AttackType.AP then
			arg_12_4 = arg_12_4 - arg_12_4 * var_0_13
		end
	end

	return var_0_3.super.updateUnitInfoBySpecialHero(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5, arg_12_6, arg_12_7)
end

function var_0_3.updateUnitInfoBySpecialHero(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	if arg_13_0.rank >= 3 and arg_13_1.target:getTeamType() ~= arg_13_0:getTeamType() and arg_13_4 > 0 and arg_13_0.summoner then
		local var_13_0 = var_0_4.new({
			tableID = var_0_9,
			start = var_0_1.ctx.battle.count,
			level = arg_13_0.summoner:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
			skillID = arg_13_0.summoner:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
			fighter = arg_13_0,
			target = arg_13_0
		})

		var_13_0.manualRevise = var_0_8 * arg_13_4

		arg_13_0:addBuffs({
			var_13_0
		})
	end

	return var_0_3.super.updateUnitInfoBySpecialHero(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
end

function var_0_3.toDoPerFrames(arg_14_0)
	if arg_14_0.rank >= 5 then
		for iter_14_0, iter_14_1 in ipairs(arg_14_0:getInfoByKey("buff_info")) do
			if iter_14_1.fighter:getTeamType() ~= arg_14_0:getTeamType() and iter_14_1.target:getTeamType() == arg_14_0:getTeamType() and iter_14_1:Ychange() > 0 and iter_14_1.target:isHasBuffByID(var_0_10) then
				iter_14_1.resetXchange_ = iter_14_1:Xchange() / 2
				iter_14_1.resetYchange_ = iter_14_1:Ychange() / 2
				iter_14_1.target.buffMovePath_ = iter_14_1:getPath()
			end
		end
	end
end

return var_0_3
