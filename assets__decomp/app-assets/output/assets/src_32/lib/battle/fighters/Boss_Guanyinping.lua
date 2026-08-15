local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guanyinping", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.model
local var_0_6 = 537
local var_0_7 = 3
local var_0_8 = 10000603
local var_0_9 = 0
local var_0_10 = 3
local var_0_11 = 75
local var_0_12 = 33

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isEnergyBuff_ = false
	arg_1_0.energyCount_ = 0
	arg_1_0.moveCount_ = 0
	arg_1_0.ReadyMoveCount_ = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.ReadyMoveCount_ > 0 then
		arg_2_0.ReadyMoveCount_ = arg_2_0.ReadyMoveCount_ - 1

		if arg_2_0.ReadyMoveCount_ == 0 then
			arg_2_0.moveCount_ = 30
		end
	end

	if arg_2_0.moveCount_ > 0 then
		if not arg_2_0:isCreatingUnits() then
			arg_2_0.moveCount_ = 0
		else
			arg_2_0.moveCount_ = arg_2_0.moveCount_ - 1

			local var_2_0 = arg_2_0:getFlipX() == true and 1 or -1

			arg_2_0:moveByX(var_2_0 * 10)
		end
	end

	if arg_2_0.energyCount_ > 0 then
		arg_2_0.energyCount_ = arg_2_0.energyCount_ - 1

		if arg_2_0.energyCount_ == 0 then
			arg_2_0.isEnergyBuff_ = false
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and var_0_1.ctx.battle.count % 30 < 1 then
		local var_2_1 = (var_0_9 + var_0_10 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * arg_2_0:getDCureRate()

		arg_2_0:updateHp(arg_2_0:getHp() + var_2_1)
	end
end

function var_0_3.attacked(arg_3_0)
	if arg_3_0:getFighterModel().currentAnimation_ and arg_3_0:getFighterModel().currentAnimation_ == "hurt" then
		return
	end

	if arg_3_0.fighterModel:getScale() ~= 1 then
		arg_3_0.fighterModel:scale(1)
	end

	local var_3_0 = var_0_5:hurtDuration(arg_3_0:getModelID())

	arg_3_0.skillRoll_ = var_3_0
	arg_3_0.unableEnergySkill_ = var_0_1.ctx.battle.count + var_3_0

	if not arg_3_0.isEnergyBuff_ then
		arg_3_0:getFighterModel():attacked(function()
			if arg_3_0:getFighterModel().currentAnimation_ == "hurt" then
				arg_3_0:resumeIdle()
			end
		end)
	else
		arg_3_0:getFighterModel():playAnimation_("hurt01", false, nil, nil, function()
			if arg_3_0:getFighterModel().currentAnimation_ == "hurt01" then
				arg_3_0:resumeIdle()
			end
		end)
	end
end

function var_0_3.playWin(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if not arg_6_0.isEnergyBuff_ then
		arg_6_0:getFighterModel():win(true)
	else
		arg_6_0:getFighterModel():playAnimation_("win01", true, nil, nil)
	end
end

function var_0_3.modelWalk(arg_7_0)
	if not arg_7_0.isEnergyBuff_ then
		if arg_7_0.fighterModel:getScale() ~= 1 then
			arg_7_0.fighterModel:scale(1)
		end

		arg_7_0:getFighterModel():walk(true)
	else
		arg_7_0:getFighterModel():playAnimation_("run01", true, nil, nil)
	end
end

function var_0_3.resumeIdle(arg_8_0)
	if not arg_8_0.isEnergyBuff_ then
		if not arg_8_0:isDeath() and arg_8_0:getFighterModel() then
			arg_8_0:getFighterModel():idle()
		end
	else
		arg_8_0:getFighterModel():playAnimation_("idle01", true, nil, nil)
	end
end

function var_0_3.checkEnergySkill(arg_9_0)
	if arg_9_0.isEnergyBuff_ then
		return false
	else
		return var_0_3.super.checkEnergySkill(arg_9_0)
	end
end

function var_0_3.getOrbOfFrontSkill(arg_10_0)
	local var_10_0 = var_0_3.super.getOrbOfFrontSkill(arg_10_0)
	local var_10_1 = var_0_4:buffOrb(var_10_0)

	if var_10_1 > 0 and arg_10_0.isEnergyBuff_ then
		return var_10_1
	end

	return var_10_0
end

function var_0_3.beginAttackEnd(arg_11_0, arg_11_1)
	var_0_3.super.beginAttackEnd(arg_11_0, arg_11_1)

	if arg_11_1.rootID_ == arg_11_0:getEnergySkillID() then
		arg_11_0.ReadyMoveCount_ = var_0_12
	end
end

function var_0_3.applySingleUnit(arg_12_0, arg_12_1)
	var_0_3.super.applySingleUnit(arg_12_0, arg_12_1)

	if var_0_4:father(arg_12_1.skillID) == arg_12_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) and arg_12_1.target == arg_12_0 then
		arg_12_0.isEnergyBuff_ = true
		arg_12_0.energyCount_ = var_0_6 + var_0_7 * arg_12_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	end
end

function var_0_3.getInterval(arg_13_0)
	if arg_13_0.isEnergyBuff_ then
		return var_0_11
	else
		return var_0_3.super.getInterval(arg_13_0)
	end
end

function var_0_3.isBreakImmortal(arg_14_0)
	return true
end

return var_0_3
