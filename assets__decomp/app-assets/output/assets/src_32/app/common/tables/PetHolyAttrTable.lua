local var_0_0 = class("PetHolyAttrTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.addBuff_ = {}
	arg_1_0.campaignType_ = {}

	import("app.common.tables.TableParser").parse("pet_holyattr.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.addBuff_[var_2_0] = xyd.splitToNumber(arg_2_0.add_buff, "|")
		arg_1_0.campaignType_[var_2_0] = tonumber(arg_2_0.campaign_type)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1] or ""
end

function var_0_0.addBuff(arg_7_0, arg_7_1)
	return arg_7_0.addBuff_[arg_7_1] or {}
end

function var_0_0.campaignType(arg_8_0, arg_8_1)
	return arg_8_0.campaignType_[arg_8_1] or 0
end

return var_0_0
