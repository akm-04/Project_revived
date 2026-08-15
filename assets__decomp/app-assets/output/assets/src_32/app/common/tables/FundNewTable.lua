local var_0_0 = class("FundNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.vipReq_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.rebateNum_ = {}
	arg_1_0.items_ = {}

	import("app.common.tables.TableParser").parse("activity_fund_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.vipReq_[var_2_0] = tonumber(arg_2_0.vip_req)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.rebateNum_[var_2_0] = tonumber(arg_2_0.rebate_num)
		arg_1_0.items_[var_2_0] = {}

		for iter_2_0 = 1, arg_1_0.rebateNum_[var_2_0] do
			local var_2_1 = xyd.splitToNumber(arg_2_0["rebate" .. iter_2_0], "|")

			table.insert(arg_1_0.items_[var_2_0], var_2_1)
		end
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.vipReq(arg_5_0, arg_5_1)
	return arg_5_0.vipReq_[arg_5_1] or 0
end

function var_0_0.cost(arg_6_0, arg_6_1)
	return arg_6_0.cost_[arg_6_1] or 0
end

function var_0_0.rebateNum(arg_7_0, arg_7_1)
	return arg_7_0.rebateNum_[arg_7_1] or 0
end

function var_0_0.items(arg_8_0, arg_8_1)
	return arg_8_0.items_[arg_8_1] or {}
end

return var_0_0
