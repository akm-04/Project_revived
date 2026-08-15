local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhangfei", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 40010890
local var_0_6 = 40010888
local var_0_7 = 40010891
local var_0_8 = 10
local var_0_9 = 30
local var_0_10 = 30
local var_0_11 = 81020035
local var_0_12 = 80010035

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.skinSkillUsed = false
	arg_1_0.skinTotalCureHp = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if not arg_2_0.skinSkillUsed and arg_2_0.skinSkillID_ == var_0_12 then
		arg_2_0.skinSkillUsed = true

		arg_2_0:addBuffs({
			var_0_4.new({
				tableID = var_0_5,
				start = var_0_1.ctx.battle.count,
				level = arg_2_0:getLevel(),
				skillID = var_0_12,
				fighter = arg_2_0,
				target = arg_2_0
			})
		})
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_0.skinSkillID_ == var_0_12 then
		if arg_3_1:getTableID() == var_0_5 then
			local var_3_0 = var_0_4.new({
				tableID = var_0_6,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getLevel(),
				skillID = var_0_12,
				fighter = arg_3_0,
				target = arg_3_0
			})

			var_3_0.manualDharm = arg_3_0.skinTotalCureHp
			arg_3_0.skinTotalCureHp = 0

			local var_3_1 = var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_3_0:getLevel(),
				skillID = var_0_12,
				fighter = arg_3_0,
				target = arg_3_0
			})

			arg_3_0:addBuffs({
				var_3_0,
				var_3_1
			})
		elseif arg_3_1:getTableID() == var_0_6 then
			arg_3_0:removeBuffByID(var_0_7)
		end
	end
end

function var_0_3.die(arg_4_0)
	var_0_3.super.die(arg_4_0)

	if arg_4_0:isForverNeverDie() then
		var_0_3.super.updateHp(arg_4_0, 1)
	end
end

function var_0_3.updateHp(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_0.skinSkillID_ == var_0_12 and arg_5_1 > arg_5_0:getHp() and arg_5_0:isHasBuffByID(var_0_5) then
		arg_5_0.skinTotalCureHp = arg_5_0.skinTotalCureHp + arg_5_1 - arg_5_0:getHp()
		arg_5_1 = arg_5_0:getHp()
	end

	var_0_3.super.updateHp(arg_5_0, arg_5_1, arg_5_2)
end

function var_0_3.getDamageCount(arg_6_0)
	local var_6_0 = arg_6_0:getHp()
	local var_6_1 = arg_6_0:getHpLimit()
	local var_6_2 = math.floor(100 * (var_6_1 - var_6_0) / var_6_1)

	return (math.floor(var_6_2 / var_0_8))
end

function var_0_3.getHuJia(arg_7_0)
	local var_7_0 = var_0_3.super.getHuJia(arg_7_0)

	if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_11 then
		var_7_0 = var_7_0 + arg_7_0:getDamageCount() * var_0_9
	end

	return var_7_0
end

function var_0_3.getMoKang(arg_8_0)
	local var_8_0 = var_0_3.super.getMoKang(arg_8_0)

	if arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_11 then
		var_8_0 = var_8_0 + arg_8_0:getDamageCount() * var_0_10
	end

	return var_8_0
end

return var_0_3
