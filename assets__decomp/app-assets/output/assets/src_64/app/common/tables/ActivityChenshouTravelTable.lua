local var_0_0 = class("ActivityChenshouTravelTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.campaignId_ = {}
	arg_1_0.type_ = {}
	arg_1_0.typeNum = {
		type1 = {},
		type2 = {}
	}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_chenshou_travel.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.campaignId_[var_2_0] = tonumber(arg_2_0.campaign_id)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)

		if arg_1_0.type_[var_2_0] == 1 then
			table.insert(arg_1_0.typeNum.type1, var_2_0)
		elseif arg_1_0.type_[var_2_0] == 2 then
			table.insert(arg_1_0.typeNum.type2, var_2_0)
		end

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.campaignId(arg_4_0, arg_4_1)
	return arg_4_0.campaignId_[arg_4_1] or 0
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

function var_0_0.getIdByType(arg_7_0, arg_7_1)
	if arg_7_1 == 1 then
		return arg_7_0.typeNum.type1
	elseif arg_7_1 == 2 then
		return arg_7_0.typeNum.type2
	else
		return 0
	end
end

return var_0_0
