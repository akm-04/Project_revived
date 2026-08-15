local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caorui", var_0_1.ctx.battle.requireFighter("Caorui"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 1
local var_0_8 = 600
local var_0_9 = {
	40010928,
	40010929,
	40010930
}
local var_0_10 = 180

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.greenBuffTargets = {}
	arg_2_0.addGreenBuff = {
		false,
		false,
		false
	}
	arg_2_0.awakeTwiceCD = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0.AwakeSplitTimeCD then
		arg_3_0.AwakeSplitTimeCD = var_0_8 - arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) * 0.1 * 30
	end

	if arg_3_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % arg_3_0.AwakeSplitTimeCD == 1 then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.sideTeam_) do
			if not iter_3_1:isDeath() and (iter_3_1:isHasBuffByID(var_0_9[1]) or iter_3_1:isHasBuffByID(var_0_9[2]) or iter_3_1:isHasBuffByID(var_0_9[3])) then
				table.insert(arg_3_0.greenBuffTargets, iter_3_1)
			end
		end

		if next(arg_3_0.greenBuffTargets) then
			arg_3_0.addGreenBuff = {
				false,
				false,
				false
			}

			local var_3_0 = math.random(#arg_3_0.greenBuffTargets)
			local var_3_1 = arg_3_0.greenBuffTargets[var_3_0]

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_2 = arg_3_0:createAttackUnits({
					var_3_1
				}, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))

				for iter_3_2, iter_3_3 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	end

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_3_4, iter_3_5 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_5.target:getTeamType() ~= arg_3_0:getTeamType() and iter_3_5:getAttrType() == var_0_2.AttributeType.ACK_SPEED and iter_3_5:getAttr() < 0 then
				arg_3_0:AwakeTwiceSkill(iter_3_5.target)
			end
		end
	end
end

function var_0_3.AwakeTwiceSkill(arg_4_0, arg_4_1)
	if not arg_4_0.awakeTwiceCD[arg_4_1] or var_0_1.ctx.battle.count - arg_4_0.awakeTwiceCD[arg_4_1] >= var_0_10 then
		arg_4_0:addBlueSpecialBuff(false, arg_4_1, true)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1
			}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				iter_4_1:calculate()

				local var_4_1 = 0

				for iter_4_2 = 1, #var_0_9 do
					var_4_1 = var_4_1 + #arg_4_1:getBuffsByID(var_0_9[iter_4_2])
				end

				if var_4_1 > 1 then
					iter_4_1:setExtraHarm(iter_4_1.harm * (var_4_1 - 1))
				end

				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end

		arg_4_0.awakeTwiceCD[arg_4_1] = var_0_1.ctx.battle.count
	end
end

function var_0_3.addBlueSpecialBuff(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local function var_5_0(arg_6_0)
		for iter_6_0 = 1, #var_0_9 do
			if not arg_6_0:isHasBuffByID(var_0_9[iter_6_0]) then
				local var_6_0 = arg_5_0:newBuff({
					var_0_9[iter_6_0]
				}, arg_6_0, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

				arg_6_0:addBuffs(var_6_0)

				if not arg_5_3 then
					arg_5_0.greenBuffsCD_[arg_6_0] = var_0_1.ctx.battle.count
				end

				break
			end
		end
	end

	if not arg_5_1 and arg_5_2 and (not arg_5_0.greenBuffsCD_[arg_5_2] or var_0_1.ctx.battle.count - arg_5_0.greenBuffsCD_[arg_5_2] >= var_0_7 or arg_5_3) then
		var_5_0(arg_5_2)
	elseif arg_5_1 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isDeath() and not iter_5_1:isAffected() and arg_5_0:getBlueBuffsNum(iter_5_1) > 0 then
				var_5_0(iter_5_1)
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	local var_7_0 = arg_7_1.target

	if arg_7_1.skillID == arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake) then
		for iter_7_0 = 1, 3 do
			if var_7_0:isHasBuffByID(var_0_9[iter_7_0]) then
				arg_7_0.addGreenBuff[iter_7_0] = true
			end
		end

		local var_7_1 = arg_7_0:getAwakeRoundSkillTarget(var_7_0, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake))
		local var_7_2 = {}

		for iter_7_1 = 1, 3 do
			if arg_7_0.addGreenBuff[iter_7_1] == true then
				table.insert(var_7_2, var_0_9[iter_7_1])
			end
		end

		for iter_7_2, iter_7_3 in ipairs(var_7_1) do
			local var_7_3 = arg_7_0:createNewBuffs(var_7_2, iter_7_3, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

			iter_7_3:addBuffs(var_7_3)
		end
	end
end

function var_0_3.getAwakeRoundSkillTarget(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {}
	local var_8_1, var_8_2 = arg_8_1:getPos()
	local var_8_3 = var_0_6:scope(arg_8_2)
	local var_8_4, var_8_5 = var_0_5.getTeam(arg_8_1)

	for iter_8_0, iter_8_1 in ipairs(var_8_4) do
		local var_8_6, var_8_7 = iter_8_1:getPos()

		if not iter_8_1:isDeath() and not iter_8_1:isAffected() and var_8_3 >= math.abs(var_8_1 - var_8_6) and iter_8_1 ~= arg_8_1 then
			table.insert(var_8_0, iter_8_1)
		end
	end

	return var_8_0
end

return var_0_3
