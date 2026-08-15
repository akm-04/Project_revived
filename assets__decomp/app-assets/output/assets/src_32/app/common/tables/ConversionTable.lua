local var_0_0 = class("ConversionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.resource_ = {}
	arg_1_0.from_ = {}
	arg_1_0.from_[xyd.currencyType.MANA] = {}
	arg_1_0.from_[xyd.currencyType.CRYSTAL] = {}
	arg_1_0.from_[xyd.currencyType.MAGIC_DUST] = {}
	arg_1_0.from_[xyd.currencyType.MAGIC_LIQUID] = {}
	arg_1_0.from_[xyd.currencyType.MAGIC_ENERGY] = {}

	import("app.common.tables.TableParser").parse("event_centre_conversion.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.resource_[var_2_0] = tonumber(arg_2_0.c_resource)
		arg_1_0.from_[xyd.currencyType.MAGIC_DUST][var_2_0] = tonumber(arg_2_0.dust)
		arg_1_0.from_[xyd.currencyType.MAGIC_LIQUID][var_2_0] = tonumber(arg_2_0.liquor)
		arg_1_0.from_[xyd.currencyType.MAGIC_ENERGY][var_2_0] = tonumber(arg_2_0.power)
		arg_1_0.from_[xyd.currencyType.MANA][var_2_0] = tonumber(arg_2_0.gold)
		arg_1_0.from_[xyd.currencyType.CRYSTAL][var_2_0] = tonumber(arg_2_0.diamond)
	end)
end

function var_0_0.resource(arg_3_0, arg_3_1)
	return arg_3_0.resource_[arg_3_1] or 0
end

function var_0_0.from(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0.from_[arg_4_2][arg_4_1] or 0
end

return var_0_0
