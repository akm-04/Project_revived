local var_0_0 = class("ActivityNewLevUpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.level_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.giftDesc_ = {}
	arg_1_0.giftIcon_ = {}
	arg_1_0.isGlow_ = {}

	import("app.common.tables.TableParser").parse("activity_new_levelup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.giftDesc_[var_2_0] = arg_2_0.gift_desc
		arg_1_0.giftIcon_[var_2_0] = arg_2_0.gift_icon
		arg_1_0.isGlow_[var_2_0] = tonumber(arg_2_0.is_glow)
	end)
end

function var_0_0.getIDs(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or {}
end

function var_0_0.level(arg_6_0, arg_6_1)
	return arg_6_0.level_[arg_6_1] or 0
end

function var_0_0.giftDesc(arg_7_0, arg_7_1)
	return arg_7_0.giftDesc_[arg_7_1] or ""
end

function var_0_0.giftIcon(arg_8_0, arg_8_1)
	return arg_8_0.giftIcon_[arg_8_1] or ""
end

function var_0_0.isGlow(arg_9_0, arg_9_1)
	return arg_9_0.isGlow_[arg_9_1] or 0
end

return var_0_0
