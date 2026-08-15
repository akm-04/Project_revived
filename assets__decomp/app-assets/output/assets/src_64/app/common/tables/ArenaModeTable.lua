local var_0_0 = class("ArenaModeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.title_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.rule_ = {}
	arg_1_0.heroNum_ = {}
	arg_1_0.isPet_ = {}
	arg_1_0.banList_ = {}
	arg_1_0.energyRate_ = {}
	arg_1_0.isLead_ = {}

	import("app.common.tables.TableParser").parse("arena_mode.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.rule_[var_2_0] = string.gsub(arg_2_0.rule_text, "|", "\n")
		arg_1_0.heroNum_[var_2_0] = tonumber(arg_2_0.partner_num)
		arg_1_0.isPet_[var_2_0] = tonumber(arg_2_0.can_pet_join)
		arg_1_0.banList_[var_2_0] = xyd.splitToNumber(arg_2_0.banned_partner, "|")
		arg_1_0.energyRate_[var_2_0] = tonumber(arg_2_0.energy_rate)
		arg_1_0.isLead_[var_2_0] = tonumber(arg_2_0.can_leader_join)
	end)
end

function var_0_0.title(arg_3_0, arg_3_1)
	return arg_3_0.title_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.rule(arg_5_0, arg_5_1)
	return arg_5_0.rule_[arg_5_1] or ""
end

function var_0_0.heroNum(arg_6_0, arg_6_1)
	return arg_6_0.heroNum_[arg_6_1] or 5
end

function var_0_0.isPet(arg_7_0, arg_7_1)
	return arg_7_0.isPet_[arg_7_1] or 0
end

function var_0_0.banList(arg_8_0, arg_8_1)
	return arg_8_0.banList_[arg_8_1] or {}
end

function var_0_0.energyRate(arg_9_0, arg_9_1)
	return arg_9_0.energyRate_[arg_9_1] or 1
end

function var_0_0.isLead(arg_10_0, arg_10_1)
	return arg_10_0.isLead_[arg_10_1] or 0
end

return var_0_0
