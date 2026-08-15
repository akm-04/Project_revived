local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yidenglong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.model
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011954
local var_0_8 = 10010245

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.dieCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	local var_2_0 = false

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
		if not iter_2_1:isDeath() or iter_2_1:canReborn() then
			var_2_0 = true
		end
	end

	if not var_2_0 then
		arg_2_0:updateHp(0)
		arg_2_0:die()
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_2_0:updateHp(0)
		arg_2_0:die()

		return
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	if arg_3_1.skillID == var_0_8 and arg_3_4 > 0 and arg_3_1.target:isHasBuffByID(var_0_7) then
		arg_3_4 = arg_3_1.basicHarm
	end

	return var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)
end

function var_0_3.playAttack(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_1 then
		return
	end

	if var_0_1.ctx.battle.infoListener.action_info then
		local var_5_0 = {
			fighter = arg_5_0,
			action_type = var_0_2.ActionType.attack
		}

		table.insert(var_0_1.ctx.battle.infoListener.action_info, var_5_0)
	end

	arg_5_0.skillRoll_ = var_0_5:duration(arg_5_0:getModelID(), arg_5_1)

	arg_5_0:getFighterModel():attack(arg_5_1, nil, nil, function()
		if arg_5_2 then
			arg_5_2()
		end

		if arg_5_0.fighterModel:getScale() ~= 1 then
			arg_5_0.fighterModel:scale(1)
		end

		if arg_5_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_5_1) then
			arg_5_0:resumeIdle()
		end

		if arg_5_1 == 1 then
			arg_5_0:updateHp(0)
			arg_5_0:die()
		end
	end)
end

function var_0_3.checkMove(arg_7_0)
	return false
end

function var_0_3.isAffected(arg_8_0)
	return true
end

function var_0_3.getAP(arg_9_0)
	if arg_9_0.summoner then
		return arg_9_0.summoner:getAP()
	else
		return var_0_3.super.getAP(arg_9_0)
	end
end

function var_0_3.getAPBaoJi(arg_10_0)
	if arg_10_0.summoner then
		return arg_10_0.summoner:getAPBaoJi()
	else
		return var_0_3.super.getAPBaoJi(arg_10_0)
	end
end

function var_0_3.getAPBaoJiHarm(arg_11_0)
	if arg_11_0.summoner then
		return arg_11_0.summoner:getAPBaoJiHarm()
	else
		return var_0_3.super.getAPBaoJiHarm(arg_11_0)
	end
end

return var_0_3
