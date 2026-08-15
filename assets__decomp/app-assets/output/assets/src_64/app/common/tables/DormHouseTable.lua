local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("DormHouseTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.key_ = {}
	arg_1_0.maintype_ = {}
	arg_1_0.areaLength_ = {}
	arg_1_0.areaWidth_ = {}
	arg_1_0.areaHeight_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.comfort_ = {}
	arg_1_0.type_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.house_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.ids_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("dorm_house.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("dorm_house", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.key_[var_2_0] = tonumber(arg_2_1.key)
	arg_2_0.maintype_[var_2_0] = tonumber(arg_2_1.maintype)
	arg_2_0.areaLength_[var_2_0] = tonumber(arg_2_1.area_length)
	arg_2_0.areaWidth_[var_2_0] = tonumber(arg_2_1.area_width)
	arg_2_0.areaHeight_[var_2_0] = tonumber(arg_2_1.area_height)
	arg_2_0.scale_[var_2_0] = tonumber(arg_2_1.scale)
	arg_2_0.comfort_[var_2_0] = var_0_1.splitToNumber(arg_2_1.comfort, "|")
	arg_2_0.type_[var_2_0] = tonumber(arg_2_1.type)
	arg_2_0.attr_[var_2_0] = var_0_1.split(arg_2_1.attr, "|")
	arg_2_0.house_[var_2_0] = arg_2_1.house
	arg_2_0.bg_[var_2_0] = arg_2_1.bg

	table.insert(arg_2_0.ids_, var_2_0)
end

function var_0_2.getIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_2.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_2.key(arg_5_0, arg_5_1)
	return arg_5_0.key_[arg_5_1] or 0
end

function var_0_2.maintype(arg_6_0, arg_6_1)
	return arg_6_0.maintype_[arg_6_1] or 0
end

function var_0_2.areaLength(arg_7_0, arg_7_1)
	return arg_7_0.areaLength_[arg_7_1] or 0
end

function var_0_2.areaWidth(arg_8_0, arg_8_1)
	return arg_8_0.areaWidth_[arg_8_1] or 0
end

function var_0_2.areaHeight(arg_9_0, arg_9_1)
	return arg_9_0.areaHeight_[arg_9_1] or 0
end

function var_0_2.scale(arg_10_0, arg_10_1)
	return arg_10_0.scale_[arg_10_1] or 0.5
end

function var_0_2.comfort(arg_11_0, arg_11_1)
	return arg_11_0.comfort_[arg_11_1] or {}
end

function var_0_2.type(arg_12_0, arg_12_1)
	return arg_12_0.type_[arg_12_1] or 0
end

function var_0_2.attr(arg_13_0, arg_13_1)
	return arg_13_0.attr_[arg_13_1] or {}
end

function var_0_2.house(arg_14_0, arg_14_1)
	return arg_14_0.house_[arg_14_1] or ""
end

function var_0_2.bg(arg_15_0, arg_15_1)
	return arg_15_0.bg_[arg_15_1] or ""
end

function var_0_2.getHouseLevByComfort(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0:comfort(arg_16_1)

	for iter_16_0 = #var_16_0, 1, -1 do
		if arg_16_2 >= var_16_0[iter_16_0] then
			return iter_16_0
		end
	end
end

function var_0_2.getAttrsGrowByLev(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_0:attr(arg_17_1)

	return var_0_1.splitToNumber(var_17_0[arg_17_2], ",")
end

function var_0_2.areaSize(arg_18_0, arg_18_1)
	return {
		long = arg_18_0:areaLength(arg_18_1),
		width = arg_18_0:areaWidth(arg_18_1),
		height = arg_18_0:areaHeight(arg_18_1)
	}
end

return var_0_2
