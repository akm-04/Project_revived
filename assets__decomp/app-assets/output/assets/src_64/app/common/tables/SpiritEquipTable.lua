local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SpiritEquipTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.from_ = {}
	arg_1_0.modelId_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("spirit_equip.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("spirit_equip", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.item_id)

	arg_2_0.from_[var_2_0] = tonumber(arg_2_1.from)
	arg_2_0.modelId_[var_2_0] = tonumber(arg_2_1.model_id)
end

function var_0_2.from(arg_3_0, arg_3_1)
	return arg_3_0.from_[arg_3_1] or 0
end

function var_0_2.modelId(arg_4_0, arg_4_1)
	return arg_4_0.modelId_[arg_4_1] or 0
end

return var_0_2
