local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Maliang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.model
local var_0_8 = var_0_2.tables.cabinetSkillTable
local var_0_9 = 1050
local var_0_10 = 10010151
local var_0_11 = 10000353
local var_0_12 = 20030006
local var_0_13 = 40011919
local var_0_14 = 10001781
local var_0_15 = 450
local var_0_16 = 40011920

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleCount_ = 0
	arg_1_0.extraUnits_ = {}
	arg_1_0.energyTargets_ = {}
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:acttionInBlack() then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0.extraUnits_) do
			arg_2_0.extraUnits_[iter_2_0] = arg_2_0.extraUnits_[iter_2_0] - 1
		end

		if arg_2_0.extraUnits_[1] and arg_2_0.extraUnits_[1] < 1 and not arg_2_0.specialSkills_ then
			arg_2_0:createSpecialSkill()
			table.remove(arg_2_0.extraUnits_, 1)
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) < 1 or arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.extraSkillJudge then
		arg_2_0.extraSkillJudge = true
		arg_2_0.extraSkillLevel = arg_2_0.hero_:skillBook()[tostring(var_0_12)] or 0
	end

	if arg_2_0.purpleCount_ <= 15 then
		arg_2_0:setPurpleBuffVisible(true)
	end

	arg_2_0.purpleCount_ = arg_2_0.purpleCount_ > 0 and arg_2_0.purpleCount_ - 1 or 0

	if arg_2_0.purpleCount_ > 0 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_2_0 = var_0_5:scope(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

	if arg_2_0.purpleCount_ < 1 and arg_2_0:getNearestTarget() and not arg_2_0:getNearestTarget():isDeath() and math.abs(arg_2_0:getNearestTarget():getX() - arg_2_0:getX()) < var_2_0 / 2 then
		arg_2_0:updatePurpleSkill(arg_2_0:getNearestTarget())
	end
end

function var_0_3.createSpecialSkill(arg_3_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_0:getEnergySkillID()
	local var_3_1 = var_0_5:sound(var_3_0)

	var_0_1.ctx.battle.pushSoundQueue(var_3_1)

	arg_3_0.specialSkills_ = var_0_4.new({
		fighter = arg_3_0,
		skillID = var_3_0
	})

	arg_3_0:beginAttackEnd(arg_3_0.specialSkills_)
end

function var_0_3.updatePurpleSkill(arg_4_0, arg_4_1)
	local var_4_0

	if arg_4_0.isSkinSkillOn_ then
		var_4_0 = var_0_14
	else
		var_4_0 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	end

	arg_4_0.purpleTarget_ = arg_4_1

	local var_4_1 = var_0_5:sound(var_4_0)

	var_0_1.ctx.battle.pushSoundQueue(var_4_1)

	arg_4_0.specialSkills_ = var_0_4.new({
		fighter = arg_4_0,
		skillID = var_4_0
	})

	arg_4_0:beginAttackEnd(arg_4_0.specialSkills_)
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if arg_5_1.rootID_ == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) or arg_5_1.rootID_ == var_0_14 then
		if arg_5_0.isSkinSkillOn_ then
			arg_5_0.purpleCount_ = var_0_15
		else
			arg_5_0.purpleCount_ = var_0_9
		end

		if arg_5_0.extraSkillLevel > 0 then
			local var_5_0 = arg_5_0.extraSkillLevel * var_0_8:attrValues(var_0_12) * 30

			arg_5_0.purpleCount_ = arg_5_0.purpleCount_ - var_5_0
		end

		arg_5_0:setPurpleBuffVisible(false)
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_0.energyTargets_[1] then
		return {}
	end

	if arg_6_0.energyTargets_[1]:isDeath() or arg_6_0.energyTargets_[1]:isAffected() then
		table.remove(arg_6_0.energyTargets_, 1)

		return arg_6_0:selectTargetByTypeD1()
	end

	local var_6_0 = arg_6_0.energyTargets_[1]

	table.remove(arg_6_0.energyTargets_, 1)

	return {
		var_6_0
	}
end

function var_0_3.selectTargetByTypeD2(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.purpleTarget_ and not arg_7_0.purpleTarget_:isDeath() and not arg_7_0.purpleTarget_:isDeath() then
		return {
			arg_7_0.purpleTarget_
		}
	end

	return {}
end

function var_0_3.getEnergyTargets(arg_8_0, arg_8_1)
	local var_8_0 = {}
	local var_8_1 = var_0_5:scope(var_0_11)

	for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and math.abs(iter_8_1:getX() - arg_8_1:getX()) < var_8_1 / 2 then
			table.insert(var_8_0, iter_8_1)
		end
	end

	return var_8_0
end

function var_0_3.setPurpleBuffVisible(arg_9_0, arg_9_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_9_0.purpleEffect_ then
		local var_9_0

		if arg_9_0.isSkinSkillOn_ then
			var_9_0 = var_0_13
		else
			var_9_0 = var_0_10
		end

		local var_9_1, var_9_2, var_9_3 = var_0_6:effectResource(var_9_0)

		if var_9_1 and var_9_2 and var_9_1 ~= "" and var_9_2 ~= "" then
			arg_9_0.purpleEffect_ = sp.SkeletonAnimation:create(var_9_1, var_9_2, var_9_3)

			arg_9_0.purpleEffect_:addTo(arg_9_0.fighterModel:getBuffLayer())
			arg_9_0.purpleEffect_:setAnimation(0, "texiao", true)

			if var_0_6:position(var_0_10) == var_0_2.BuffPosition.Head then
				arg_9_0.purpleEffect_:align(display.CENTER_BOTTOM, arg_9_0:getFighterModel().headPoint.x, arg_9_0:getFighterModel().headPoint.y)
			elseif var_0_6:position(var_0_10) == var_0_2.BuffPosition.Foot then
				arg_9_0.purpleEffect_:align(display.CENTER_BOTTOM, arg_9_0:getFighterModel().footPoint.x, arg_9_0:getFighterModel().footPoint.y)
			else
				arg_9_0.purpleEffect_:align(display.CENTER_BOTTOM, arg_9_0:getFighterModel().chestPoint.x, arg_9_0:getFighterModel().chestPoint.y)
			end
		end
	end

	arg_9_0.purpleEffect_:setVisible(arg_9_1)
end

function var_0_3.beginAttack(arg_10_0)
	var_0_3.super.beginAttack(arg_10_0)

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_10_0 = arg_10_0.unitSkills_

	if not var_10_0 then
		return
	end

	if var_10_0.rootID_ == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_10_1 = var_0_5:attackIndex(var_10_0.rootID_)
		local var_10_2 = var_0_7:duration(arg_10_0:getModelID(), var_10_1)
		local var_10_3 = var_0_5:pretime(var_10_0.rootID_)

		arg_10_0.extraUnits_ = {}
		arg_10_0.energyTargets_ = {}

		for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
			if not iter_10_1:isDeath() and not iter_10_1:isAffected() then
				table.insert(arg_10_0.extraUnits_, var_10_3)
				table.insert(arg_10_0.energyTargets_, iter_10_1)
			end
		end

		local var_10_4 = (var_10_2 - var_10_3) / (#arg_10_0.extraUnits_ + 1)

		for iter_10_2, iter_10_3 in ipairs(arg_10_0.extraUnits_) do
			arg_10_0.extraUnits_[iter_10_2] = arg_10_0.extraUnits_[iter_10_2] + (iter_10_2 - 1) * var_10_4
		end
	end
end

function var_0_3.applySingleUnit(arg_11_0, arg_11_1)
	var_0_3.super.applySingleUnit(arg_11_0, arg_11_1)

	if arg_11_0.isSkinSkillOn_ and arg_11_1.skillID == arg_11_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) or arg_11_1.skillID == var_0_14 then
		local var_11_0 = arg_11_0:createNewBuffs({
			var_0_16
		}, arg_11_0, var_0_14)

		arg_11_0:addBuffs(var_11_0)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_11_1.skillID == arg_11_0:getEnergySkillID() then
		local var_11_1 = arg_11_0:getEnergyTargets(arg_11_1.target)
		local var_11_2 = arg_11_0:createAttackUnits(var_11_1, var_0_11)

		for iter_11_0, iter_11_1 in ipairs(var_11_2) do
			table.insert(arg_11_0.moveAttackUnits_, iter_11_1)
			table.insert(arg_11_0.records_.special_units, iter_11_1)
		end
	end
end

return var_0_3
