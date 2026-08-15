local var_0_0 = class("WarCampTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.link_ = {}
	arg_1_0.buffIds_ = {}
	arg_1_0.openTime_ = {}
	arg_1_0.freeWordTime_ = {}
	arg_1_0.bossId_ = {}
	arg_1_0.bossHp_ = {}
	arg_1_0.buffDesc_ = {}

	import("app.common.tables.TableParser").parse("camp_war.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.link_[var_2_0] = xyd.splitToNumber(arg_2_0.link, "|")
		arg_1_0.buffIds_[var_2_0] = xyd.splitToNumber(arg_2_0.buff_ids, "|")
		arg_1_0.freeWordTime_[var_2_0] = tonumber(arg_2_0.free_word_time)
		arg_1_0.openTime_[var_2_0] = tonumber(arg_2_0.open_time)
		arg_1_0.bossId_[var_2_0] = tonumber(arg_2_0.boss_id)
		arg_1_0.bossHp_[var_2_0] = tonumber(arg_2_0.boss_hp)
		arg_1_0.buffDesc_[var_2_0] = xyd.split(arg_2_0.buff_desc, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.charge(arg_5_0, arg_5_1)
	return arg_5_0.link_[arg_5_1] or 0
end

function var_0_0.link(arg_6_0, arg_6_1)
	return arg_6_0.link_[arg_6_1] or {}
end

function var_0_0.buffIds(arg_7_0, arg_7_1)
	return arg_7_0.buffIds_[arg_7_1] or {}
end

function var_0_0.freeWordTime(arg_8_0, arg_8_1)
	return arg_8_0.freeWordTime_[arg_8_1] or 0
end

function var_0_0.openTime(arg_9_0, arg_9_1)
	return arg_9_0.openTime_[arg_9_1] or 0
end

function var_0_0.bossId(arg_10_0, arg_10_1)
	return arg_10_0.bossId_[arg_10_1] or 0
end

function var_0_0.bossHp(arg_11_0, arg_11_1)
	return arg_11_0.bossHp_[arg_11_1] or 0
end

function var_0_0.buffDesc(arg_12_0, arg_12_1)
	return arg_12_0.buffDesc_[arg_12_1] or {}
end

return var_0_0
