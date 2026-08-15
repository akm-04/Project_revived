local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Hucheer", var_0_1.ctx.battle.getRequire("BaseFighter"))
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
local var_0_10 = 600

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.nightLayer_ = nil
	arg_1_0.greenSkillCount_ = nil
	arg_1_0.count_ = false
	arg_1_0.isNight_ = false
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)
	local var_2_1 = var_0_5:buffOrb(var_2_0)

	if var_2_1 > 0 and var_0_1.ctx.battle.nightCount > 0 then
		return var_2_1
	end

	return var_0_3.super.getOrbOfFrontSkill(arg_2_0)
end

function var_0_3.toDoPerFrames(arg_3_0)
	if not arg_3_0.count_ then
		arg_3_0:addPurpleBuff(false)

		arg_3_0.count_ = true
	end

	if var_0_1.ctx.battle.nightCount == 0 then
		arg_3_0:removeNightLayer()

		if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
			arg_3_0:addPurpleBuff(false)
		end
	elseif arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_3_0:addPurpleBuff(true)
	end

	if arg_3_0:isDeath() then
		return
	end

	if arg_3_0.greenSkillCount_ then
		arg_3_0.greenSkillCount_ = math.max(0, arg_3_0.greenSkillCount_ - 1)

		if arg_3_0.greenSkillCount_ == 0 then
			arg_3_0.greenSkillCount_ = nil

			arg_3_0:setImmuneControl(false)
		end
	end

	if arg_3_0.energyCount_ then
		arg_3_0.energyCount_ = arg_3_0.energyCount_ - 1

		if arg_3_0.energyCount_ <= 0 then
			arg_3_0.energyCount_ = nil

			if var_0_1.ctx.battle.nightCount == 0 then
				arg_3_0:addNightLayer()
			end

			var_0_1.ctx.battle.nightCount = var_0_10

			arg_3_0:addPurpleBuff(true)
		end
	end
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if var_0_1.ctx.battle.nightCount == 0 and arg_4_1.rootID_ == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_4_0:setImmuneControl(true)

		arg_4_0.greenSkillCount_ = var_0_5:pretime(var_0_7)
	end

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyCount_ = var_0_5:pretime(var_0_6)
	end
end

function var_0_3.newBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		local var_5_1 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = arg_5_0:getSkillLevelByID(arg_5_3),
			skillID = arg_5_3,
			fighter = arg_5_0,
			target = arg_5_2
		})

		var_5_1:setIsHit(true)
		var_5_1:setYongJiu()
		var_5_1:setDirection(arg_5_0:getFighterModel():getFlipX())
		table.insert(var_5_0, var_5_1)
	end

	return var_5_0
end

function var_0_3.addPurpleBuff(arg_6_0, arg_6_1)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) <= 0 then
		return
	end

	if arg_6_1 then
		if arg_6_0:isHasBuffByID(var_0_9[1]) then
			return
		end

		for iter_6_0, iter_6_1 in ipairs(var_0_8) do
			arg_6_0:removeBuffByID(iter_6_1)
		end

		local var_6_0 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_1 = arg_6_0:newBuff(var_0_9, arg_6_0, var_6_0)

		arg_6_0:addBuffs(var_6_1)
	else
		if arg_6_0:isHasBuffByID(var_0_8[1]) then
			return
		end

		for iter_6_2, iter_6_3 in ipairs(var_0_9) do
			arg_6_0:removeBuffByID(iter_6_3)
		end

		local var_6_2 = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_6_3 = arg_6_0:newBuff(var_0_8, arg_6_0, var_6_2)

		arg_6_0:addBuffs(var_6_3)
	end
end

function var_0_3.addNightLayer(arg_7_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_7_0.nightLayer_ then
		arg_7_0.nightLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 200))

		if not var_0_1.ctx.battle.isUnlimitBattle then
			arg_7_0.nightLayer_:size(var_0_2.STAGE_WIDTH, var_0_2.STAGE_HEIGHT)
		else
			arg_7_0.nightLayer_:setScale(1.6666666666666667)
		end

		arg_7_0.nightLayer_:align(display.LEFT_BOTTOM, 0, 0):addTo(var_0_1.ctx.battle.unitBottomLayer)
	end

	arg_7_0.nightLayer_:show()

	arg_7_0.isNight_ = true
end

function var_0_3.removeNightLayer(arg_8_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_8_0.isNight_ and arg_8_0.nightLayer_ and not tolua.isnull(arg_8_0.nightLayer_) then
		arg_8_0.nightLayer_:hide()

		arg_8_0.isNight_ = false
	end
end

return var_0_3
