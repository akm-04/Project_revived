local var_0_0 = class("WarCampMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.showItem_ = {}
	arg_1_0.showItemNums_ = {}
	arg_1_0.req_ = {}

	import("app.common.tables.TableParser").parse("camp_war_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.showItem_[var_2_0] = tonumber(arg_2_0.show_item)
		arg_1_0.showItemNums_[var_2_0] = tonumber(arg_2_0.show_item_nums)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.giftId(arg_6_0, arg_6_1)
	return arg_6_0.giftId_[arg_6_1] or 0
end

function var_0_0.showItem(arg_7_0, arg_7_1)
	return arg_7_0.showItem_[arg_7_1] or 0
end

function var_0_0.showItemNums(arg_8_0, arg_8_1)
	return arg_8_0.showItemNums_[arg_8_1] or 0
end

function var_0_0.req(arg_9_0, arg_9_1)
	return arg_9_0.req_[arg_9_1] or 0
end

return var_0_0
