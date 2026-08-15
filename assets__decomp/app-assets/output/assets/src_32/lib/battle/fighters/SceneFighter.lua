local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("SceneFighter", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("AttackUnit")

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	arg_1_0.partnerID_ = arg_1_1:getTableID()
	arg_1_0.hero_ = arg_1_1
	arg_1_0.level_ = arg_1_1:getLevel()

	arg_1_0:initElementEquip()

	arg_1_0.isSceneFighter = true
end

function var_0_3.singleLoop(arg_2_0)
	if arg_2_0:acttionInBlack() then
		arg_2_0:applyUnitMoves()
		arg_2_0:applyUnitHarms()
	end

	arg_2_0:toDoPerFrames()
end

function var_0_3.isAffected(arg_3_0)
	return true
end

function var_0_3.isDeath(arg_4_0)
	return false
end

function var_0_3.getFlipX(arg_5_0)
	return false
end

function var_0_3.checkKilling(arg_6_0, arg_6_1)
	arg_6_0.killCount = arg_6_0.killCount + 1
end

function var_0_3.createAttackUnits(arg_7_0, arg_7_1, arg_7_2)
	local function var_7_0(arg_8_0)
		local var_8_0 = {
			skillID = arg_7_2,
			fighter = arg_7_0,
			target = arg_8_0,
			count = var_0_1.ctx.battle.count
		}

		return var_0_4.new(var_8_0)
	end

	if arg_7_1 == nil or next(arg_7_1) == nil then
		return {}
	end

	local var_7_1 = {}

	for iter_7_0, iter_7_1 in ipairs(arg_7_1) do
		local var_7_2 = var_7_0(iter_7_1)

		table.insert(arg_7_0.records_.attackunit, var_7_2)
		table.insert(var_7_1, var_7_2)

		var_7_2.recordIndex_ = #arg_7_0.records_.attackunit
	end

	return var_7_1
end

function var_0_3.getPos(arg_9_0)
	return 0, 0
end

function var_0_3.getAttackPoint(arg_10_0, arg_10_1)
	return {
		x = 0,
		y = 0
	}
end

return var_0_3
