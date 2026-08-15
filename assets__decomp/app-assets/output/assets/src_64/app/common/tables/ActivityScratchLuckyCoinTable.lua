local var_0_0 = class("ActivityScratchLuckyCoinTable ")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.luckycoin_num_ = {}
	arg_1_0.sell_price_ = {}

	import("app.common.tables.TableParser").parse("activity_scratch_luckycoin.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.luckycoin_num_[var_2_0] = tonumber(arg_2_0.luckycoin_num)
		arg_1_0.sell_price_[var_2_0] = tonumber(arg_2_0.sell_price)
	end)
end

function var_0_0.getName(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or 0
end

function var_0_0.getDesc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or " "
end

function var_0_0.getLuckyCoinNum(arg_5_0, arg_5_1)
	return arg_5_0.luckycoin_num_[arg_5_1] or 0
end

function var_0_0.getSellPrice(arg_6_0, arg_6_1)
	return arg_6_0.sell_price_[arg_6_1] or 0
end

function var_0_0.allcount(arg_7_0)
	return #arg_7_0.name_ or 0
end

return var_0_0
