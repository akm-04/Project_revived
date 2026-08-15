local var_0_0 = class("RankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.title_ = {}
	arg_1_0.infoText_ = {}
	arg_1_0.isRealtime_ = {}
	arg_1_0.type_ = {}
	arg_1_0.subType_ = {}
	arg_1_0.isShow_ = {}

	import("app.common.tables.TableParser").parse("rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.infoText_[var_2_0] = arg_2_0.info_text
		arg_1_0.isRealtime_[var_2_0] = tonumber(arg_2_0.is_realtime)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.subType_[var_2_0] = tonumber(arg_2_0.sub_type)
		arg_1_0.isShow_[var_2_0] = tonumber(arg_2_0.is_show)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.title(arg_4_0, arg_4_1)
	return arg_4_0.title_[arg_4_1] or ""
end

function var_0_0.infoText(arg_5_0, arg_5_1)
	return arg_5_0.infoText_[arg_5_1] or ""
end

function var_0_0.isRealtime(arg_6_0, arg_6_1)
	return arg_6_0.isRealtime_[arg_6_1] or 0
end

function var_0_0.type(arg_7_0, arg_7_1)
	return arg_7_0.type_[arg_7_1] or 0
end

function var_0_0.subType(arg_8_0, arg_8_1)
	return arg_8_0.subType_[arg_8_1] or 0
end

function var_0_0.isShow(arg_9_0, arg_9_1)
	return arg_9_0.isShow_[arg_9_1] or 0
end

function var_0_0.getSubsByType(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1
	local var_10_1 = {}

	for iter_10_0 = 1, #arg_10_0.ids_ do
		if arg_10_0:subType(arg_10_0.ids_[iter_10_0]) == var_10_0 then
			table.insert(var_10_1, arg_10_0.ids_[iter_10_0])
		end
	end

	return var_10_1
end

function var_0_0.getIDBySubType(arg_11_0, arg_11_1)
	for iter_11_0 = 1, #arg_11_0.ids_ do
		if arg_11_0:subType(arg_11_0.ids_[iter_11_0]) == arg_11_1 then
			return arg_11_0.ids_[iter_11_0]
		end
	end

	return nil
end

return var_0_0
