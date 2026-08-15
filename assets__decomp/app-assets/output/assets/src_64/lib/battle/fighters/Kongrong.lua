local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Kongrong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011118
local var_0_8 = 40011124
local var_0_9 = 10001009
local var_0_10 = 10001016
local var_0_11 = 40011125
local var_0_12 = 40011126
local var_0_13 = 0.5
local var_0_14 = 0.06
local var_0_15 = 0.6
local var_0_16 = 900
local var_0_17 = 300
local var_0_18 = 90
local var_0_19 = 40011113
local var_0_20 = 40011114
local var_0_21 = 40011129

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.PurpleSkillCD_ = var_0_16
	arg_1_0.PurpleSkillTime_ = var_0_17
	arg_1_0.PurpleSkillJumpCD_ = var_0_18
	arg_1_0.hasPurpleSkill_ = false
	arg_1_0.PurpleSkillTarget_ = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:purpleSkill()
end

function var_0_3.purpleSkill(arg_3_0)
	if arg_3_0:isDeath() or arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	local var_3_0 = arg_3_0:selectTargetByTypeB31()

	if not var_3_0 or not next(var_3_0) then
		arg_3_0.hasPurpleSkill_ = false
		arg_3_0.PurpleSkillTime_ = var_0_17
		arg_3_0.PurpleSkillJumpCD_ = var_0_18
		arg_3_0.PurpleSkillTarget_ = {}

		return
	end

	if arg_3_0.PurpleSkillCD_ > 0 and not arg_3_0.hasPurpleSkill_ then
		arg_3_0.PurpleSkillCD_ = arg_3_0.PurpleSkillCD_ - 1
	elseif arg_3_0.PurpleSkillTime_ > 0 then
		if not arg_3_0.hasPurpleSkill_ then
			local var_3_1 = arg_3_0:createNewBuffs({
				var_0_19,
				var_0_20
			}, var_3_0[1], arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_3_0[1]:addBuffs(var_3_1)

			arg_3_0.PurpleSkillTarget_ = var_3_0
			arg_3_0.hasPurpleSkill_ = true
			arg_3_0.PurpleSkillTime_ = var_0_17
			arg_3_0.PurpleSkillJumpCD_ = var_0_18
		else
			arg_3_0.PurpleSkillJumpCD_ = arg_3_0.PurpleSkillJumpCD_ - 1

			if arg_3_0.PurpleSkillTarget_[1] and arg_3_0.PurpleSkillTarget_[1]:isDeath() then
				local var_3_2 = arg_3_0:createNewBuffs({
					var_0_19,
					var_0_20
				}, var_3_0[1], arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				var_3_0[1]:addBuffs(var_3_2)

				arg_3_0.PurpleSkillTarget_ = var_3_0
				arg_3_0.PurpleSkillJumpCD_ = var_0_18
			end

			if arg_3_0.PurpleSkillJumpCD_ < 1 and var_3_0[1] ~= arg_3_0.PurpleSkillTarget_[1] then
				local var_3_3 = arg_3_0:createNewBuffs({
					var_0_19,
					var_0_20
				}, var_3_0[1], arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				var_3_0[1]:addBuffs(var_3_3)

				if not arg_3_0.PurpleSkillTarget_[1]:isDeath() then
					arg_3_0.PurpleSkillTarget_[1]:removeBuffByID(var_0_19)
					arg_3_0.PurpleSkillTarget_[1]:removeBuffByID(var_0_20)
				end

				arg_3_0.PurpleSkillTarget_ = var_3_0
				arg_3_0.PurpleSkillJumpCD_ = var_0_18
			end
		end

		arg_3_0.PurpleSkillTime_ = arg_3_0.PurpleSkillTime_ - 1
	elseif arg_3_0.hasPurpleSkill_ and arg_3_0.PurpleSkillTime_ < 1 then
		if not arg_3_0.PurpleSkillTarget_[1]:isDeath() then
			arg_3_0.PurpleSkillTarget_[1]:removeBuffByID(var_0_19)
			arg_3_0.PurpleSkillTarget_[1]:removeBuffByID(var_0_20)
		end

		arg_3_0.hasPurpleSkill_ = false
		arg_3_0.PurpleSkillCD_ = var_0_16
		arg_3_0.PurpleSkillTime_ = var_0_17
		arg_3_0.PurpleSkillJumpCD_ = var_0_18
		arg_3_0.PurpleSkillTarget_ = {}
	end
end

function var_0_3.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5 = var_0_3.super.updateUnitDataByFighter(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5, arg_4_6, arg_4_7)
	local var_4_6 = arg_4_1.skillID

	if var_4_2 > 0 and var_4_6 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_4_7 = arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

		var_4_2 = var_4_2 + arg_4_1.target:getEnergy() * var_0_14 * var_4_7

		if arg_4_0:isHasBuffByID(var_0_8) then
			var_4_4 = var_4_2 * var_0_15
		end
	end

	return var_4_0, var_4_1, var_4_2, var_4_3, var_4_4, var_4_5
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_0 = arg_5_0:createNewBuffs({
			var_0_21
		}, arg_5_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

		arg_5_0:addBuffs(var_5_0)

		if arg_5_0:isHasBuffByID(var_0_8) then
			local var_5_1 = arg_5_0:createNewBuffs({
				var_0_11,
				var_0_12
			}, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			arg_5_1.target:addBuffs(var_5_1)
		end
	elseif arg_5_1.skillID == var_0_9 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_1:isDeath() and iter_5_1:isHasBuffByID(var_0_7) then
				local var_5_2 = arg_5_0:createNewBuffs({
					var_0_11,
					var_0_12
				}, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				iter_5_1:addBuffs(var_5_2)
			end
		end
	elseif arg_5_1.skillID == var_0_10 and arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_5_0.hasPurpleSkill_ then
			arg_5_0.PurpleSkillTime_ = arg_5_0.PurpleSkillTime_ + var_0_17
		else
			arg_5_0.PurpleSkillCD_ = 0

			local var_5_3 = arg_5_0:selectTargetByTypeB31()

			if not var_5_3 or not next(var_5_3) then
				arg_5_0.hasPurpleSkill_ = false
				arg_5_0.PurpleSkillTime_ = var_0_17
				arg_5_0.PurpleSkillJumpCD_ = var_0_18
				arg_5_0.PurpleSkillTarget_ = {}

				return
			end

			local var_5_4 = arg_5_0:createNewBuffs({
				var_0_19,
				var_0_20
			}, var_5_3[1], arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			var_5_3[1]:addBuffs(var_5_4)

			arg_5_0.PurpleSkillTarget_ = var_5_3
			arg_5_0.hasPurpleSkill_ = true
			arg_5_0.PurpleSkillTime_ = var_0_17
			arg_5_0.PurpleSkillJumpCD_ = var_0_18
		end
	end
end

function var_0_3.buffAddAction(arg_6_0, arg_6_1)
	if arg_6_1:getTableID() == var_0_11 then
		arg_6_1.manualRevise = -((1 - arg_6_0:getADJianShang()) * var_0_13)
	elseif arg_6_1:getTableID() == var_0_12 then
		arg_6_1.manualRevise = -((1 - arg_6_0:getAPJianShang()) * var_0_13)
	end
end

function var_0_3.buffRemoveAction(arg_7_0, arg_7_1)
	if arg_7_1:getTableID() == var_0_8 then
		for iter_7_0, iter_7_1 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_1:isDeath() and iter_7_1:isHasBuffByID(var_0_11) or iter_7_1:isHasBuffByID(var_0_12) then
				iter_7_1:removeBuffByID(var_0_11)
				iter_7_1:removeBuffByID(var_0_12)
			end
		end
	elseif arg_7_1:getTableID() == var_0_21 then
		for iter_7_2, iter_7_3 in ipairs(arg_7_0.selfTeam_) do
			if not iter_7_3:isDeath() and iter_7_3:isHasBuffByID(var_0_11) or iter_7_3:isHasBuffByID(var_0_12) then
				iter_7_3:removeBuffByID(var_0_11)
				iter_7_3:removeBuffByID(var_0_12)
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_8_0)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and not iter_8_1:isApImmortal() then
			table.insert(var_8_0, iter_8_1)
		end
	end

	for iter_8_2, iter_8_3 in ipairs(arg_8_0.selfTeam_) do
		if not iter_8_3:isDeath() and not iter_8_3:isAffected() and not iter_8_3:isApImmortal() and iter_8_3 ~= arg_8_0 and not iter_8_3:isHasBuffByID(var_0_7) then
			table.insert(var_8_0, iter_8_3)
		end
	end

	return var_8_0
end

function var_0_3.selectTargetByTypeD2(arg_9_0)
	local var_9_0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1 ~= arg_9_0 and (not var_9_0 or iter_9_1:getEnergy() > var_9_0:getEnergy()) then
			var_9_0 = iter_9_1
		end
	end

	if var_9_0 then
		return {
			var_9_0
		}
	else
		return {
			arg_9_0
		}
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeB31(arg_10_0)
	local var_10_0
	local var_10_1

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and iter_10_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_10_1 or var_10_1 < iter_10_1.harms) then
			var_10_0 = iter_10_1
			var_10_1 = iter_10_1.harms
		end
	end

	return {
		var_10_0
	}
end

return var_0_3
