local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Simayi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.model
local var_0_6 = 80010103
local var_0_7 = 10001616
local var_0_8 = 10001615

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isDemon_ = false
	arg_1_0.demonCount_ = nil
	arg_1_0.skinSkillCount = 0
	arg_1_0.skinSkillActive = false
end

function var_0_3.getAD(arg_2_0)
	if arg_2_0.skinSkillActive then
		return math.max(var_0_3.super.getAD(arg_2_0), var_0_3.super.getAP(arg_2_0))
	else
		return var_0_3.super.getAD(arg_2_0)
	end
end

function var_0_3.getAP(arg_3_0)
	if arg_3_0.skinSkillActive then
		return math.max(var_0_3.super.getAD(arg_3_0), var_0_3.super.getAP(arg_3_0))
	else
		return var_0_3.super.getAP(arg_3_0)
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_0.skinSkillID_ == var_0_6 and var_0_4:father(arg_4_1.skillID) == var_0_4:buffOrb(var_0_7) or var_0_4:father(arg_4_1.skillID) == var_0_4:buffOrb(arg_4_0:getPugongID()) then
		arg_4_0:updateEnergyBy(var_0_4:reMP(arg_4_1.skillID))
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.getOrbOfFrontSkill(arg_5_0)
	local var_5_0 = var_0_3.super.getOrbOfFrontSkill(arg_5_0)
	local var_5_1 = var_0_4:buffOrb(var_5_0)

	if var_5_1 > 0 and arg_5_0.isDemon_ then
		return var_5_1
	end

	return var_5_0
end

function var_0_3.getFrontSkill(arg_6_0)
	if arg_6_0:isPugongOnly() then
		return arg_6_0.skinSkillID_ == var_0_6 and var_0_7 or arg_6_0:getPugongID()
	end

	if arg_6_0.isEnergySkill_ and arg_6_0:getEnergySkillID() > 0 then
		return arg_6_0:getEnergySkillID()
	end

	if arg_6_0.isDemon_ then
		return arg_6_0.skinSkillID_ == var_0_6 and var_0_7 or arg_6_0:getPugongID()
	end

	if next(arg_6_0.startSkillQueue_) then
		return arg_6_0.startSkillQueue_[1]
	end

	return arg_6_0.skillQueue_[1]
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	if arg_7_1.rootID_ == arg_7_0:getEnergySkillID() then
		arg_7_0.demonCount_ = var_0_4:pretime(arg_7_1.rootID_)

		arg_7_0:setImmuneControl(true)
	end

	if arg_7_0.skinSkillID_ == var_0_6 then
		if var_0_4:father(arg_7_1.rootID_) ~= var_0_7 and var_0_4:father(arg_7_1.rootID_) ~= arg_7_0:getPugongID() and var_0_4:father(arg_7_1.rootID_) ~= var_0_4:buffOrb(arg_7_0:getPugongID()) and var_0_4:father(arg_7_1.rootID_) ~= var_0_8 then
			arg_7_0.skinSkillCount = arg_7_0.skinSkillCount + 2
		elseif arg_7_0.skinSkillCount > 0 then
			arg_7_0.skinSkillCount = arg_7_0.skinSkillCount - 1
			arg_7_0.skinSkillActive = true
		else
			arg_7_0.skinSkillActive = false
		end
	end

	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)
end

function var_0_3.resumeIdle(arg_8_0)
	if arg_8_0.isDemon_ then
		arg_8_0:getFighterModel():playAnimation_("idle2", true, nil, nil)
	elseif not arg_8_0:isDeath() and arg_8_0:getFighterModel() then
		arg_8_0:getFighterModel():idle()
	end
end

function var_0_3.modelWalk(arg_9_0)
	if arg_9_0.isDemon_ then
		arg_9_0:getFighterModel():playAnimation_("run2", true, nil, nil)
	else
		if arg_9_0.fighterModel:getScale() ~= 1 then
			arg_9_0.fighterModel:scale(1)
		end

		arg_9_0:getFighterModel():walk(true)
	end
end

function var_0_3.playAttack(arg_10_0, arg_10_1, arg_10_2)
	if not arg_10_1 then
		return
	end

	if arg_10_1 == 4 and arg_10_0.isDemon_ then
		arg_10_1 = 6
	end

	arg_10_0.skillRoll_ = var_0_5:duration(arg_10_0:getModelID(), arg_10_1)

	arg_10_0:getFighterModel():attack(arg_10_1, nil, nil, function()
		if arg_10_2 then
			arg_10_2()
		end

		if arg_10_0.fighterModel:getScale() ~= 1 then
			arg_10_0.fighterModel:scale(1)
		end

		if arg_10_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_10_1) then
			arg_10_0:resumeIdle()
		end
	end)
end

function var_0_3.toDoPerFrames(arg_12_0)
	if arg_12_0:isDeath() then
		return
	end

	if arg_12_0.demonCount_ then
		arg_12_0.demonCount_ = arg_12_0.demonCount_ - 1

		if arg_12_0.demonCount_ == 0 then
			arg_12_0.demonCount_ = nil

			arg_12_0:energyChange()
			arg_12_0:setImmuneControl(false)
			arg_12_0:resumeIdle()

			arg_12_0.leftInterval_ = 0
		end
	end
end

function var_0_3.energyChange(arg_13_0)
	if arg_13_0.isDemon_ then
		arg_13_0.isDemon_ = false
	else
		arg_13_0.isDemon_ = true
	end

	if arg_13_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_13_0 = arg_13_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)
		local var_13_1 = arg_13_0:createAttackUnits({
			arg_13_0
		}, var_13_0)

		for iter_13_0, iter_13_1 in ipairs(var_13_1) do
			table.insert(arg_13_0.moveAttackUnits_, iter_13_1)
			table.insert(arg_13_0.records_.special_units, iter_13_1)
		end
	end
end

return var_0_3
