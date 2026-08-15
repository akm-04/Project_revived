local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ModelPointsTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.leftX_ = {}
	arg_1_0.leftY_ = {}
	arg_1_0.rightX_ = {}
	arg_1_0.rightY_ = {}
	arg_1_0.headX_ = {}
	arg_1_0.headY_ = {}
	arg_1_0.footX_ = {}
	arg_1_0.footY_ = {}
	arg_1_0.attackedX_ = {}
	arg_1_0.attackedY_ = {}
	arg_1_0.chestX_ = {}
	arg_1_0.chestY_ = {}
	arg_1_0.attackNum_ = {}
	arg_1_0.attackXs_ = {}
	arg_1_0.attackYs_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("model_points.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("model_points", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.ID)

	if arg_2_0.leftX_[var_2_0] then
		error("model id duplicated: ", var_2_0)
	end

	arg_2_0.leftX_[var_2_0] = tonumber(arg_2_1.PleftX)
	arg_2_0.leftY_[var_2_0] = tonumber(arg_2_1.PleftY)
	arg_2_0.rightX_[var_2_0] = tonumber(arg_2_1.PrightX)
	arg_2_0.rightY_[var_2_0] = tonumber(arg_2_1.PrightY)
	arg_2_0.headX_[var_2_0] = tonumber(arg_2_1.PheadX)
	arg_2_0.headY_[var_2_0] = tonumber(arg_2_1.PheadY)
	arg_2_0.footX_[var_2_0] = tonumber(arg_2_1.PfootX)
	arg_2_0.footY_[var_2_0] = tonumber(arg_2_1.PfootY)
	arg_2_0.attackedX_[var_2_0] = tonumber(arg_2_1.PshoujiX)
	arg_2_0.attackedY_[var_2_0] = tonumber(arg_2_1.PshoujiY)
	arg_2_0.chestX_[var_2_0] = tonumber(arg_2_1.PchestX)
	arg_2_0.chestY_[var_2_0] = tonumber(arg_2_1.PchestY)
	arg_2_0.attackNum_[var_2_0] = tonumber(arg_2_1.PattackNum)
	arg_2_0.attackXs_[var_2_0] = var_0_1.splitToNumber(arg_2_1.PattackXs, "|")
	arg_2_0.attackYs_[var_2_0] = var_0_1.splitToNumber(arg_2_1.PattackYs, "|")
end

function var_0_2.PleftX(arg_3_0, arg_3_1)
	return arg_3_0.leftX_[arg_3_1] or 0
end

function var_0_2.PleftY(arg_4_0, arg_4_1)
	return arg_4_0.leftY_[arg_4_1] or 0
end

function var_0_2.PrightX(arg_5_0, arg_5_1)
	return arg_5_0.rightX_[arg_5_1] or 0
end

function var_0_2.PrightY(arg_6_0, arg_6_1)
	return arg_6_0.rightY_[arg_6_1] or 0
end

function var_0_2.PheadX(arg_7_0, arg_7_1)
	return arg_7_0.headX_[arg_7_1] or 0
end

function var_0_2.PheadY(arg_8_0, arg_8_1)
	return arg_8_0.headY_[arg_8_1] or 0
end

function var_0_2.PfootX(arg_9_0, arg_9_1)
	return arg_9_0.footX_[arg_9_1] or 0
end

function var_0_2.PfootY(arg_10_0, arg_10_1)
	return arg_10_0.footY_[arg_10_1] or 0
end

function var_0_2.PshoujiX(arg_11_0, arg_11_1)
	return arg_11_0.attackedX_[arg_11_1] or 0
end

function var_0_2.PshoujiY(arg_12_0, arg_12_1)
	return arg_12_0.attackedY_[arg_12_1] or 0
end

function var_0_2.PchestX(arg_13_0, arg_13_1)
	return arg_13_0.chestX_[arg_13_1] or 0
end

function var_0_2.PchestY(arg_14_0, arg_14_1)
	return arg_14_0.chestY_[arg_14_1] or 0
end

function var_0_2.attackNum(arg_15_0, arg_15_1)
	return arg_15_0.attackNum_[arg_15_1] or 0
end

function var_0_2.PattackXs(arg_16_0, arg_16_1)
	return arg_16_0.attackXs_[arg_16_1] or {}
end

function var_0_2.PattackYs(arg_17_0, arg_17_1)
	return arg_17_0.attackYs_[arg_17_1] or {}
end

return var_0_2
