local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhenji", var_0_1.ctx.battle.requireFighter("Zhenji"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 40011361
local var_0_9 = 40011360
local var_0_10 = 40011358
local var_0_11 = 90
local var_0_12 = 150
local var_0_13 = 60020028
local var_0_14 = 180
local var_0_15 = 30
local var_0_16 = 15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.awakeCount = 0
	arg_1_0.isAddAwakeBuff = false
	arg_1_0.isAddCureBuff = false
	arg_1_0.twiceAwakenCD = 0

	arg_1_0:listenInfo("buff_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
			if iter_2_1.target:getTeamType() ~= arg_2_0:getTeamType() then
				if iter_2_1:dBuffType() == var_0_2.DBuffType.BING_DONG then
					arg_2_0.twiceAwakenCD = math.max(0, arg_2_0.twiceAwakenCD - var_0_15)
				elseif (iter_2_1:getAttrType() == var_0_2.AttributeType.SPEED or iter_2_1:getAttrType() == var_0_2.AttributeType.ACK_SPEED) and iter_2_1:getAttr() < 0 then
					arg_2_0.twiceAwakenCD = math.max(0, arg_2_0.twiceAwakenCD - var_0_16)
				end
			end
		end

		if arg_2_0.twiceAwakenCD > 0 then
			arg_2_0.twiceAwakenCD = arg_2_0.twiceAwakenCD - 1
		else
			arg_2_0.twiceAwakenCD = var_0_14

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits(var_0_6.B3(arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)), arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice))

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end
		end
	end

	if not arg_2_0.isAddAwakeBuff then
		arg_2_0.isAddAwakeBuff = true

		local var_2_1 = arg_2_0:createNewBuffs({
			var_0_8
		}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		arg_2_0:addBuffs(var_2_1)
	end

	if arg_2_0.removeCount then
		arg_2_0.removeCount = arg_2_0.removeCount - 1

		if arg_2_0.removeCount < 1 and arg_2_0:isHasBuffByID(var_0_9) then
			arg_2_0:removeBuffByID(var_0_10)
			arg_2_0:removeBuffByID(var_0_9)
		end
	end
end

function var_0_3.updateHp(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = arg_3_0:getHp()

	if arg_3_1 < 1 and arg_3_0:isHasBuffByID(var_0_9) then
		arg_3_1 = 1
	end

	return var_0_3.super.updateHp(arg_3_0, arg_3_1, arg_3_2)
end

function var_0_3.neverDieFeedBack(arg_4_0, arg_4_1)
	if arg_4_1 == arg_4_0 then
		arg_4_0:updateHp(1, false, true)

		local var_4_0 = arg_4_0:createNewBuffs({
			var_0_9,
			var_0_10
		}, arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake), arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake))

		arg_4_0:addBuffs(var_4_0)
	end
end

function var_0_3.beginAttackEnd(arg_5_0, arg_5_1)
	var_0_3.super.beginAttackEnd(arg_5_0, arg_5_1)

	if var_0_7:father(arg_5_1.rootID_) == arg_5_0:getEnergySkillID() and arg_5_0:isHasBuffByID(var_0_9) and not arg_5_0.removeCount then
		arg_5_0.removeCount = var_0_11
	end
end

function var_0_3.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	if var_0_7:father(arg_6_1.skillID) == arg_6_1.fighter:getEnergySkillID() and arg_6_0:isHasBuffByID(var_0_9) and not arg_6_0.removeCount then
		arg_6_0.removeCount = var_0_12
	end

	return var_0_3.super.applyHurtFighter(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
end

return var_0_3
