local var_0_0 = class("AnnounceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids = {}
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.haveCD_ = {}
	arg_1_0.activityID_ = {}
	arg_1_0.content_ = {}

	import("app.common.tables.TableParser").parse("announce.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.haveCD_[var_2_0] = tonumber(arg_2_0.have_cd)
		arg_1_0.activityID_[var_2_0] = tonumber(arg_2_0.activity)
		arg_1_0.content_[var_2_0] = arg_2_0.content
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or {}
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or {}
end

function var_0_0.haveCD(arg_5_0, arg_5_1)
	return arg_5_0.haveCD_[arg_5_1] or 0
end

function var_0_0.getIDByActivityID(arg_6_0, arg_6_1)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.ids) do
		if arg_6_0.activityID_[iter_6_1] == arg_6_1 then
			table.insert(var_6_0, iter_6_1)
		end
	end

	if #var_6_0 == 1 then
		return var_6_0[1]
	else
		return var_6_0
	end
end

function var_0_0.content(arg_7_0, arg_7_1)
	return arg_7_0.content_[arg_7_1] or {}
end

return var_0_0
