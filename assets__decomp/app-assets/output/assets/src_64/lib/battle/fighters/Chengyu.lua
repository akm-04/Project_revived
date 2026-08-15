local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chengyu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = 80010018
local var_0_7 = {
	40011595,
	40011596
}
local var_0_8 = 0.15
local var_0_9 = 0.1
local var_0_10 = 80110018
local var_0_11 = 0.05
local var_0_12 = 600
local var_0_13 = 0.6
local var_0_14 = 300
local var_0_15 = 40011715

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isSkinSkillUsed = false
	arg_1_0.skinStealCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.skinSkillID_ == var_0_6 and not arg_2_0.isSkinSkillUsed then
		arg_2_0.isSkinSkillUsed = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_0 = arg_2_0:createAttackUnits(var_0_5.A2(arg_2_0, var_0_6), var_0_6)

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end

	if arg_2_0.skinSkillID_ == var_0_10 then
		if arg_2_0.skinStealCount < 5 * var_0_14 then
			arg_2_0.skinStealCount = arg_2_0.skinStealCount + 1
		end

		if arg_2_0.skinStealCount % var_0_14 == 0 then
			local var_2_1

			for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
				if not iter_2_3:isDeath() and (not var_2_1 or iter_2_3:getAP() > var_2_1:getAP()) then
					var_2_1 = iter_2_3
				end
			end

			if var_2_1 then
				arg_2_0:addBuffs({
					var_0_4.new({
						tableID = var_0_15,
						start = var_0_1.ctx.battle.count,
						level = arg_2_0:getLevel(),
						skillID = var_0_10,
						fighter = arg_2_0,
						target = arg_2_0,
						manualRevise = math.min(var_2_1:getAP() * var_0_11, var_0_12)
					})
				})
				var_2_1:addBuffs({
					var_0_4.new({
						tableID = var_0_15,
						start = var_0_1.ctx.battle.count,
						level = arg_2_0:getLevel(),
						skillID = var_0_10,
						fighter = arg_2_0,
						target = var_2_1,
						manualRevise = -math.min(var_2_1:getAP() * var_0_11, var_0_12)
					})
				})
			end
		end
	end
end

function var_0_3.forceDie(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		for iter_3_2, iter_3_3 in ipairs(var_0_7) do
			iter_3_1:removeBuffByID(iter_3_3)
		end
	end

	var_0_3.super.forceDie(arg_3_0)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	if arg_4_1.target:getEnergy() < arg_4_0:getEnergy() and arg_4_0.skinSkillID_ == var_0_6 then
		arg_4_1:setExtraHarm(arg_4_1.basicHarm * var_0_8)

		if arg_4_1.attackType == var_0_2.AttackType.AP and var_0_2.weightedChoise({
			var_0_9,
			1 - var_0_9
		}) == 1 then
			arg_4_1.mustBaoji = true
		end
	end

	if arg_4_0.skinSkillID_ == var_0_10 then
		local var_4_0 = arg_4_0:getAP() - arg_4_1.target:getAP()

		if var_4_0 > 0 then
			arg_4_1:setExtraHarm(var_4_0 * var_0_13)
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

return var_0_3
