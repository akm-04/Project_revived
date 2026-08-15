local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caoxiu", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.hero
local var_0_6 = {
	40010373
}
local var_0_7 = {
	40010374,
	40010375
}
local var_0_8 = {
	40010376
}

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.currentPurpleType_ = 0
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_2_0:addPurpleBuff()
	end
end

function var_0_3.addPurpleBuff(arg_3_0)
	local var_3_0 = 0
	local var_3_1 = 0
	local var_3_2 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() then
			local var_3_3 = var_0_5:distanceType(iter_3_1:getTableID())

			if var_3_3 == var_0_2.DistanceType.QIANPAI then
				var_3_0 = var_3_0 + 1
			elseif var_3_3 == var_0_2.DistanceType.ZHONGPAI then
				var_3_1 = var_3_1 + 1
			elseif var_3_3 == var_0_2.DistanceType.HOUPAI then
				var_3_2 = var_3_2 + 1
			end
		end
	end

	if var_3_1 < var_3_0 and var_3_2 < var_3_0 then
		arg_3_0:addFrontBuff()
	elseif var_3_2 < var_3_1 and var_3_0 < var_3_1 then
		arg_3_0:addMidBuff()
	else
		arg_3_0:addBackBuff()
	end
end

function var_0_3.addFrontBuff(arg_4_0)
	for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() then
			local var_4_0 = arg_4_0:newBuff(var_0_6, iter_4_1, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_4_1:addBuffs(var_4_0)
		end
	end
end

function var_0_3.addMidBuff(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() then
			local var_5_0 = arg_5_0:newBuff(var_0_7, iter_5_1, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_5_1:addBuffs(var_5_0)
		end
	end
end

function var_0_3.addBackBuff(arg_6_0)
	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			local var_6_0 = arg_6_0:newBuff(var_0_8, iter_6_1, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

			iter_6_1:addBuffs(var_6_0)
		end
	end
end

function var_0_3.removePurpleBuffByType(arg_7_0, arg_7_1, arg_7_2)
	if not arg_7_1 then
		return
	end

	local var_7_0

	if arg_7_1 == 1 then
		var_7_0 = var_0_6
	elseif arg_7_1 == 2 then
		var_7_0 = var_0_7
	else
		var_7_0 = var_0_8
	end

	for iter_7_0, iter_7_1 in ipairs(var_7_0) do
		arg_7_2:removeBuffByID(iter_7_1)
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

return var_0_3
