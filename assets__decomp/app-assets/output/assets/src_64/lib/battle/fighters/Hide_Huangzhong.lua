local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangzhong", var_0_1.ctx.battle.requireFighter("HideBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 10000989
local var_0_8 = 40011094
local var_0_9 = 21
local var_0_10 = 10000995
local var_0_11 = 1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
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

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_10 and arg_5_0.blueSkillCount_ >= var_0_11 and arg_5_0.isSkinSkillOn_ and not arg_5_0.isAddSkinBuff and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) >= 1 then
		arg_5_0.isAddSkinBuff = true

		local var_5_0 = arg_5_0:newBuff({
			var_0_8
		}, arg_5_0, var_0_7)

		arg_5_0:addBuffs(var_5_0)
	end
end

function var_0_3.skinSkill(arg_6_0)
	if not arg_6_0.isSkinSkillOn_ or not arg_6_0.isAddSkinBuff then
		return
	end

	if arg_6_0:isDeath() or arg_6_0:isAffected() or arg_6_0:isBattleUnable() then
		return
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % var_0_9 == 0 then
		local var_6_0 = arg_6_0:getTargets(var_0_7)

		if var_6_0 and next(var_6_0) then
			local var_6_1 = var_0_6:attackIndex(var_0_7)

			arg_6_0:createSkillByID(var_0_7, arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_6_1)
		end
	end
end

function var_0_3.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0, var_7_1, var_7_2, var_7_3 = var_0_3.super.applyHurtFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)

	if arg_7_0:isHurtBreak(var_7_0, arg_7_1) and not arg_7_0:isAdBreakImmortal() and not arg_7_0:isBreakImmortal() and arg_7_0.isAddSkinBuff then
		arg_7_0:removeBuffByID(var_0_8)

		arg_7_0.blueSkillCount_ = 0
		arg_7_0.isAddSkinBuff = false
	end

	return var_7_0, var_7_1, var_7_2, var_7_3
end

function var_0_3.skillIsBreak(arg_8_0, arg_8_1)
	var_0_3.super.skillIsBreak(arg_8_0, arg_8_1)

	if arg_8_0.isAddSkinBuff then
		arg_8_0:removeBuffByID(var_0_8)

		arg_8_0.blueSkillCount_ = 0
		arg_8_0.isAddSkinBuff = false
	end
end

function var_0_3.checkSkillBreak(arg_9_0, arg_9_1, arg_9_2)
	var_0_3.super.checkSkillBreak(arg_9_0, arg_9_1, arg_9_2)

	if arg_9_0.isAddSkinBuff then
		arg_9_0:removeBuffByID(var_0_8)

		arg_9_0.blueSkillCount_ = 0
		arg_9_0.isAddSkinBuff = false
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

return var_0_3
