local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = {
	40010129
}
local var_0_7 = 10000410
local var_0_8 = 10000411
local var_0_9 = 0.03
local var_0_10 = 0

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.purpleInit = 0
	arg_1_0.purpleStep = 0
	arg_1_0.count = false
end

function var_0_3.updateEnergyBar(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	var_0_3.super.updateEnergyBar(arg_2_0)
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0.count then
		local var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)

		arg_3_0.purpleInit = unpack(var_0_5:descNumInit(var_3_0)) / 100
		arg_3_0.purpleStep = unpack(var_0_5:descNumStep(var_3_0)) / 100
		arg_3_0.count = true
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		local var_4_0 = arg_4_1.target
		local var_4_1 = arg_4_0.purpleInit + arg_4_0.purpleStep * arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if arg_4_0.isStarPurple_ then
			var_4_1 = var_4_1 + 0.1
		end

		local var_4_2 = var_4_0:getEnergy() * var_4_1

		arg_4_1.target:updateEnergyBy(-var_4_2)
	end

	if arg_4_1.skillID == var_0_7 then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_1:isAffected() and not iter_4_1:isDeath() then
				arg_4_0:addEnergyBuff(iter_4_1)
			end
		end

		arg_4_0:die()
		arg_4_0:updateHp(0)
		arg_4_0:updateEnergyTo(0)
	end
end

function var_0_3.addEnergyBuff(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0:getEnergySkillID()
	local var_5_1 = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	local var_5_2 = var_0_9 + var_0_10 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
	local var_5_3 = arg_5_0:getAP() * var_5_2

	for iter_5_0, iter_5_1 in ipairs(var_0_6) do
		local var_5_4 = var_0_4.new({
			tableID = iter_5_1,
			start = var_0_1.ctx.battle.count,
			level = var_5_1,
			skillID = var_5_0,
			fighter = arg_5_0,
			target = arg_5_1
		})

		var_5_4.manualRevise = var_5_3

		var_5_4:setIsHit(true)
		var_5_4:setDirection(arg_5_0:getFighterModel():getFlipX())
		arg_5_1:addBuffs({
			var_5_4
		})
	end
end

function var_0_3.selectTargetByTypeD1(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0
	local var_6_1 = 0

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and var_6_1 < iter_6_1:getAP() then
			var_6_0 = iter_6_1
		end
	end

	return {
		var_6_0
	}
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_1:getLevel()
	local var_7_1 = var_0_5:desc4NumStep(arg_7_1:getSkillID())[2]

	if arg_7_1:getSkillID() == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_7_0.isStarBlue_ then
		arg_7_1.manualRevise = var_7_1 * var_7_0 * -1
	elseif arg_7_1:getSkillID() == var_0_8 and arg_7_0.isStarEnergy_ then
		arg_7_1.manualRevise = -0.1
	end
end

return var_0_3
