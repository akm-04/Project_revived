local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("LibraryAmourTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.amour_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.actId_ = {}
	arg_1_0.missionId_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("library_amour.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("library_amour", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.amour_[var_2_0] = tonumber(arg_2_1.amour)
	arg_2_0.attr_[var_2_0] = tonumber(arg_2_1.attr)
	arg_2_0.actId_[var_2_0] = tonumber(arg_2_1.act_id)
	arg_2_0.missionId_[var_2_0] = tonumber(arg_2_1.mission_id)
end

function var_0_2.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_2.amour(arg_4_0, arg_4_1)
	return arg_4_0.amour_[arg_4_1] or 0
end

function var_0_2.attr(arg_5_0, arg_5_1)
	return arg_5_0.attr_[arg_5_1] or 0
end

function var_0_2.actId(arg_6_0, arg_6_1)
	return arg_6_0.actId_[arg_6_1] or 0
end

function var_0_2.missionId(arg_7_0, arg_7_1)
	return arg_7_0.missionId_[arg_7_1] or 0
end

function var_0_2.getCurrentId(arg_8_0, arg_8_1)
	for iter_8_0 = 1, #arg_8_0.amour_ do
		if arg_8_1 <= arg_8_0.amour_[iter_8_0] then
			return iter_8_0
		end
	end

	return #arg_8_0.amour_
end

return var_0_2
