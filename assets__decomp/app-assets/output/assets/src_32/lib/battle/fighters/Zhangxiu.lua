local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangxiu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 10000599
local var_0_6 = 10000598
local var_0_7 = 40010510
local var_0_8 = 40010509
local var_0_9 = 0
local var_0_10 = 0.003
local var_0_11 = 0.05
local var_0_12 = 0.5
local var_0_13 = 40010507
local var_0_14 = 0
local var_0_15 = 0.008
local var_0_16 = 40011914
local var_0_17 = 80010136
local var_0_18 = 5
local var_0_19 = 0.02

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyAD_ = 0
	arg_1_0.skinAD_ = 0
	arg_1_0.isBlueReady = false
	arg_1_0.energyTarget_ = {}
end

function var_0_3.beginAttackEnd(arg_2_0, arg_2_1)
	var_0_3.super.beginAttackEnd(arg_2_0, arg_2_1)

	if arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		arg_2_0.energyAD_ = 0
	elseif arg_2_1.rootID_ == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_2_0.isBlueReady_ = true
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	if arg_3_1.skillID == var_0_6 then
		local var_3_0 = var_0_9 + var_0_10 * arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_3_1 = arg_3_1.target:getAD() * var_3_0

		if not arg_3_0.energyTarget_[arg_3_1.target] then
			arg_3_0.energyTarget_[arg_3_1.target] = true
		end

		arg_3_0.energyAD_ = var_3_1
	elseif arg_3_1.skillID == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_3_0.isBlueReady_ then
		local var_3_2 = arg_3_0:getX() < arg_3_1.target:getX() and 1 or -1

		arg_3_0:x(arg_3_1.target:getX() + var_3_2 * 120)
		arg_3_0:y(arg_3_1.target:getY())
		arg_3_0:flipX(not arg_3_0:getFlipX())

		arg_3_0.isBlueReady_ = false
	end

	if arg_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and arg_3_0.isSkinSkillOn_ then
		local var_3_3 = arg_3_0:createNewBuffs({
			var_0_16
		}, arg_3_1.target, var_0_17)

		arg_3_1.target:addBuffs(var_3_3)
	end

	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)
end

function var_0_3.buffAddAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_8 then
		arg_4_1.manualRevise = arg_4_0.energyAD_ * -1
	elseif arg_4_1:getTableID() == var_0_7 then
		arg_4_1.manualRevise = arg_4_0.energyAD_
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0 = arg_5_1.target

	if arg_5_0.energyTarget_[var_5_0] then
		if var_5_0:isHasBuffByID(var_0_8) then
			local var_5_1 = var_5_0:getHpLimit() * var_0_11 * var_5_0:getADJianShang()

			arg_5_4 = arg_5_4 + math.min(var_5_1, arg_5_0:getHpLimit() * var_0_12)
		else
			arg_5_0.energyTarget_[var_5_0] = false
		end
	end

	if arg_5_4 > 0 and arg_5_0.isSkinSkillOn_ then
		arg_5_4 = arg_5_4 + arg_5_0.skinAD_ * var_0_18
		arg_5_0.skinAD_ = var_5_0:getAD() * var_0_19
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.getUnitData(arg_6_0, arg_6_1)
	local var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5 = var_0_3.super.getUnitData(arg_6_0, arg_6_1)

	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_6_2 > 0 and arg_6_1.attackType ~= var_0_2.AttackType.Cure then
		local var_6_6 = arg_6_0:getBuffByID(var_0_13)
		local var_6_7 = var_6_2 * (var_0_14 + var_0_15 * arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))

		if not var_6_6 then
			local var_6_8 = arg_6_0:newBuff({
				var_0_13
			}, arg_6_0, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))[1]

			var_6_8.manualDharm = var_6_7

			arg_6_0:addBuffs({
				var_6_8
			})
		else
			var_6_6.manualDharm = var_6_6.manualDharm + var_6_7
			var_6_6.dHarm_ = var_6_6.dHarm_ + var_6_7
			var_6_6.leftCount_ = var_6_6:getTime()
		end

		arg_6_0:updateHpBar(true)
	end

	return var_6_0, var_6_1, var_6_2, var_6_3, var_6_4, var_6_5
end

function var_0_3.newBuff(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		local var_7_1 = var_0_4.new({
			tableID = iter_7_1,
			start = var_0_1.ctx.battle.count,
			level = arg_7_0:getSkillLevelByID(arg_7_3),
			skillID = arg_7_3,
			fighter = arg_7_0,
			target = arg_7_2
		})

		var_7_1:setIsHit(true)
		var_7_1:setDirection(arg_7_0:getFighterModel():getFlipX())
		table.insert(var_7_0, var_7_1)
	end

	return var_7_0
end

return var_0_3
