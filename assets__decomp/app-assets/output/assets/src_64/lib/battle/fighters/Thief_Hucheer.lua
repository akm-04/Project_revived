local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hucheer", var_0_1.ctx.battle.requireFighter("ElementBoss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 10000393
local var_0_7 = 10000391
local var_0_8 = {
	40010109
}
local var_0_9 = {
	40010110,
	40010111,
	40010112
}
local var_0_10 = 300

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isNight_ = false
	arg_1_0.nightCount_ = nil
	arg_1_0.nightLayer_ = nil
	arg_1_0.greenSkillCount_ = nil
	arg_1_0.count = false
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)
	local var_2_1 = var_0_5:buffOrb(var_2_0)

	if var_2_1 > 0 and arg_2_0.isNight_ then
		return var_2_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_2_0)
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0:isDeath() then
		return
	end

	if not arg_3_0.count then
		arg_3_0:addPurpleBuff(false)

		arg_3_0.count = true
	end

	if arg_3_0.nightCount_ then
		arg_3_0.nightCount_ = math.max(0, arg_3_0.nightCount_ - 1)

		if arg_3_0.nightCount_ == 0 then
			arg_3_0:removeNightLayer()

			arg_3_0.isNight_ = false
			arg_3_0.nightCount_ = nil

			if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
				arg_3_0:addPurpleBuff(false)
			end
		end
	end

	if arg_3_0.greenSkillCount_ then
		arg_3_0.greenSkillCount_ = math.max(0, arg_3_0.greenSkillCount_ - 1)

		if arg_3_0.greenSkillCount_ == 0 then
			arg_3_0.greenSkillCount_ = nil

			arg_3_0:setImmuneControl(false)
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if not arg_4_0.isNight and arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0:setImmuneControl(true)

		arg_4_0.greenSkillCount_ = var_0_5:pretime(var_0_7)
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == var_0_6 then
		arg_5_0.isNight_ = true
		arg_5_0.nightCount_ = var_0_10

		arg_5_0:addNightLayer()
		arg_5_0:addPurpleBuff(true)
	end
end

function var_0_3.newBuff(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = var_0_4.new({
			tableID = iter_6_1,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByID(arg_6_3),
			skillID = arg_6_3,
			fighter = arg_6_0,
			target = arg_6_2
		})

		var_6_1:setIsHit(true)
		var_6_1:setYongJiu()
		var_6_1:setDirection(arg_6_0:getFighterModel():getFlipX())
		table.insert(var_6_0, var_6_1)
	end

	return var_6_0
end

function var_0_3.addPurpleBuff(arg_7_0, arg_7_1)
	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	if arg_7_1 then
		for iter_7_0, iter_7_1 in ipairs(var_0_8) do
			arg_7_0:removeBuffByID(iter_7_1)
		end

		local var_7_0 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_7_1 = arg_7_0:newBuff(var_0_9, arg_7_0, var_7_0)

		arg_7_0:addBuffs(var_7_1)
	else
		for iter_7_2, iter_7_3 in ipairs(var_0_9) do
			arg_7_0:removeBuffByID(iter_7_3)
		end

		local var_7_2 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_7_3 = arg_7_0:newBuff(var_0_8, arg_7_0, var_7_2)

		arg_7_0:addBuffs(var_7_3)
	end
end

function var_0_3.addNightLayer(arg_8_0)
	if not arg_8_0.nightLayer_ then
		arg_8_0.nightLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 200))

		arg_8_0.nightLayer_:size(var_0_2.STAGE_WIDTH, var_0_2.STAGE_HEIGHT)
		arg_8_0.nightLayer_:align(display.LEFT_BOTTOM, 0, 0):addTo(var_0_1.ctx.battle.unitBottomLayer)
	end

	arg_8_0.nightLayer_:show()
end

function var_0_3.removeNightLayer(arg_9_0)
	if arg_9_0.nightLayer_ then
		arg_9_0.nightLayer_:hide()
	end
end

return var_0_3
