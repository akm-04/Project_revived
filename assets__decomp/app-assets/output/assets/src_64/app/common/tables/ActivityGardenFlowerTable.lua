local var_0_0 = class("ActivityGardenFlowerTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.seedId_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.flowerImg_ = {}
	arg_1_0.growTime_ = {}
	arg_1_0.maxGain_ = {}
	arg_1_0.witherParam_ = {}
	arg_1_0.witherLimit_ = {}
	arg_1_0.pickParam_ = {}
	arg_1_0.pickLimit_ = {}
	arg_1_0.witherBegin_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_garden_flower.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.seedId_[var_2_0] = tonumber(arg_2_0.seed_id)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.flowerImg_[var_2_0] = arg_2_0.flower_img
		arg_1_0.growTime_[var_2_0] = tonumber(arg_2_0.grow_time)
		arg_1_0.maxGain_[var_2_0] = tonumber(arg_2_0.max_gain)
		arg_1_0.witherParam_[var_2_0] = tonumber(arg_2_0.wither_param)
		arg_1_0.witherLimit_[var_2_0] = tonumber(arg_2_0.wither_limit)
		arg_1_0.pickParam_[var_2_0] = tonumber(arg_2_0.pick_param)
		arg_1_0.pickLimit_[var_2_0] = tonumber(arg_2_0.pick_limit)
		arg_1_0.witherBegin_[var_2_0] = xyd.splitToNumber(arg_2_0.wither_begin, "|")
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.seedId(arg_4_0, arg_4_1)
	return arg_4_0.seedId_[arg_4_1] or 0
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.flowerImg(arg_6_0, arg_6_1)
	return arg_6_0.flowerImg_[arg_6_1] or ""
end

function var_0_0.growTime(arg_7_0, arg_7_1)
	return arg_7_0.growTime_[arg_7_1] or 0
end

function var_0_0.maxGain(arg_8_0, arg_8_1)
	return arg_8_0.maxGain_[arg_8_1] or 0
end

function var_0_0.witherParam(arg_9_0, arg_9_1)
	return arg_9_0.witherParam_[arg_9_1] or 0
end

function var_0_0.witherLimit(arg_10_0, arg_10_1)
	return arg_10_0.witherLimit_[arg_10_1] or 0
end

function var_0_0.pickParam(arg_11_0, arg_11_1)
	return arg_11_0.pickParam_[arg_11_1] or 0
end

function var_0_0.pickLimit(arg_12_0, arg_12_1)
	return arg_12_0.pickLimit_[arg_12_1] or 0
end

function var_0_0.witherBegin(arg_13_0, arg_13_1)
	return arg_13_0.witherBegin_[arg_13_1] or {}
end

function var_0_0.price(arg_14_0, arg_14_1)
	return arg_14_0.price_[arg_14_1] or 0
end

function var_0_0.ids(arg_15_0)
	return table.keys(arg_15_0.price_) or {}
end

function var_0_0.getBySeedId(arg_16_0, arg_16_1)
	for iter_16_0, iter_16_1 in pairs(arg_16_0.seedId_) do
		if iter_16_1 == arg_16_1 then
			return iter_16_0
		end
	end
end

return var_0_0
