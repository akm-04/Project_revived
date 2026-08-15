local var_0_0 = class("ZhugeHeroTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.awakenTableID_ = {}
	arg_1_0.zhugeSkill_ = {}
	arg_1_0.ids_[xyd.ZhugeRentHeroType.HERO] = {}
	arg_1_0.ids_[xyd.ZhugeRentHeroType.PET] = {}
	arg_1_0.awakenTableID_[xyd.ZhugeRentHeroType.HERO] = {}
	arg_1_0.awakenTableID_[xyd.ZhugeRentHeroType.PET] = {}

	import("app.common.tables.TableParser").parse("zhuge_partner", handler(arg_1_0, arg_1_0.zhugePartner))
	import("app.common.tables.TableParser").parse("zhuge_pet", handler(arg_1_0, arg_1_0.zhugePet))
end

function var_0_0.zhugePartner(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	table.insert(arg_2_0.ids_[xyd.ZhugeRentHeroType.HERO], var_2_0)

	arg_2_0.awakenTableID_[xyd.ZhugeRentHeroType.HERO][var_2_0] = tonumber(arg_2_1.awaken_table_id)
	arg_2_0.zhugeSkill_[var_2_0] = tonumber(arg_2_1.zhuge_skill)
end

function var_0_0.zhugePet(arg_3_0, arg_3_1)
	local var_3_0 = tonumber(arg_3_1.id)

	table.insert(arg_3_0.ids_[xyd.ZhugeRentHeroType.PET], var_3_0)

	arg_3_0.awakenTableID_[xyd.ZhugeRentHeroType.PET][var_3_0] = tonumber(arg_3_1.awaken_table_id)
end

function var_0_0.ids(arg_4_0, arg_4_1)
	return arg_4_0.ids_[arg_4_1] or {}
end

function var_0_0.awakenTableID(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0.awakenTableID_[arg_5_1][arg_5_2] or 0
end

function var_0_0.zhugeSkill(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.zhugeSkill_[arg_6_1]

	if not var_6_0 or var_6_0 == 0 then
		local var_6_1 = xyd.tables.hero:beforeAwaken(arg_6_1)

		var_6_0 = arg_6_0.zhugeSkill_[var_6_1] or 0
	end

	return var_6_0
end

return var_0_0
