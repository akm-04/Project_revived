local var_0_0 = class("TreasureTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.product_ = {}
	arg_1_0.openLv_ = {}
	arg_1_0.map_ = {}
	arg_1_0.sound_ = {}

	import("app.common.tables.TableParser").parse("treasure.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.product_[var_2_0] = arg_2_0.product
		arg_1_0.openLv_[var_2_0] = tonumber(arg_2_0.open_lv)
		arg_1_0.map_[var_2_0] = arg_2_0.map_images
		arg_1_0.sound_[var_2_0] = arg_2_0.sound
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.product(arg_4_0, arg_4_1)
	return arg_4_0.product_[arg_4_1] or ""
end

function var_0_0.openLv(arg_5_0, arg_5_1)
	return arg_5_0.openLv_[arg_5_1] or 0
end

function var_0_0.map(arg_6_0, arg_6_1)
	return arg_6_0.map_[arg_6_1] or ""
end

function var_0_0.sound(arg_7_0, arg_7_1)
	return arg_7_0.sound_[arg_7_1] or ""
end

function var_0_0.openTypeNum(arg_8_0, arg_8_1)
	local var_8_0 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.openLv_) do
		if iter_8_1 <= arg_8_1 then
			var_8_0 = var_8_0 + 1
		end
	end

	return var_8_0
end

return var_0_0
