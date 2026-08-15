local var_0_0 = class("SkinDynamicTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.partnerID_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.num_ = {}
	arg_1_0.path_ = {}
	arg_1_0.cardScale_ = {}
	arg_1_0.homeCardScale_ = {}
	arg_1_0.smallCardScale_ = {}
	arg_1_0.oldSmallCardScale_ = {}
	arg_1_0.bigCardScale_ = {}
	arg_1_0.pos_ = {}

	import("app.common.tables.TableParser").parse("skin_dynamic.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.model_id)

		arg_1_0.partnerID_[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.path_[var_2_0] = arg_2_0.path
		arg_1_0.cardScale_[var_2_0] = tonumber(arg_2_0.scaling_card)
		arg_1_0.homeCardScale_[var_2_0] = tonumber(arg_2_0.scaling_homecard)
		arg_1_0.smallCardScale_[var_2_0] = tonumber(arg_2_0.scaling_smallcard)
		arg_1_0.oldSmallCardScale_[var_2_0] = tonumber(arg_2_0.scaling_oldsmallcard)
		arg_1_0.bigCardScale_[var_2_0] = tonumber(arg_2_0.scaling_bigcard)
		arg_1_0.pos_[var_2_0] = {}

		for iter_2_0 = 1, 7 do
			arg_1_0.pos_[var_2_0][iter_2_0] = {}

			local var_2_1 = xyd.splitToNumber(arg_2_0["location" .. iter_2_0], "|")

			arg_1_0.pos_[var_2_0][iter_2_0].x = var_2_1[1] or 0
			arg_1_0.pos_[var_2_0][iter_2_0].y = var_2_1[2] or 0
		end

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.partnerID(arg_4_0, arg_4_1)
	return arg_4_0.partnerID_[arg_4_1] or 0
end

function var_0_0.cost(arg_5_0, arg_5_1)
	return arg_5_0.cost_[arg_5_1]
end

function var_0_0.num(arg_6_0, arg_6_1)
	return arg_6_0.num_[arg_6_1]
end

function var_0_0.path(arg_7_0, arg_7_1)
	return arg_7_0.path_[arg_7_1] or ""
end

function var_0_0.cardScale(arg_8_0, arg_8_1, arg_8_2)
	return arg_8_2 == 6 and arg_8_0.bigCardScale_[arg_8_1] or arg_8_0.cardScale_[arg_8_1] or 1
end

function var_0_0.homeCardScale(arg_9_0, arg_9_1)
	return arg_9_0.homeCardScale_[arg_9_1] or 1
end

function var_0_0.smallCardScale(arg_10_0, arg_10_1)
	return arg_10_0.smallCardScale_[arg_10_1] or 1
end

function var_0_0.oldSmallCardScale(arg_11_0, arg_11_1)
	return arg_11_0.oldSmallCardScale_[arg_11_1] or 1
end

function var_0_0.pos(arg_12_0, arg_12_1, arg_12_2)
	return arg_12_0.pos_[arg_12_1][arg_12_2] or {
		x = 0,
		y = 0
	}
end

return var_0_0
