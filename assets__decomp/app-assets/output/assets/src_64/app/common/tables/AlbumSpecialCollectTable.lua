local var_0_0 = class("AlbumSpecialCollectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.partnerId_ = {}
	arg_1_0.title_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.reward_ = {}
	arg_1_0.num_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("collect_special.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.partnerId_[var_2_0] = xyd.splitToNumber(arg_2_0.partner_id, "|")
		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.desc_[var_2_0] = arg_2_0.dec
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.reward_[var_2_0] = tonumber(arg_2_0.content)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.icon_[var_2_0] = arg_2_0.image

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.partnerId(arg_4_0, arg_4_1)
	return arg_4_0.partnerId_[arg_4_1] or {}
end

function var_0_0.title(arg_5_0, arg_5_1)
	return arg_5_0.title_[arg_5_1] or ""
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1] or ""
end

function var_0_0.type(arg_7_0, arg_7_1)
	return arg_7_0.type_[arg_7_1] or 1
end

function var_0_0.reward(arg_8_0, arg_8_1)
	return arg_8_0.reward_[arg_8_1] or 0
end

function var_0_0.num(arg_9_0, arg_9_1)
	return arg_9_0.num_[arg_9_1] or 0
end

function var_0_0.icon(arg_10_0, arg_10_1)
	return arg_10_0.icon_[arg_10_1] or 0
end

return var_0_0
