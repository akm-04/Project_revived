local var_0_0 = class("SuperPartnerStarTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.starColor_ = {}
	arg_1_0.manaCost_ = {}
	arg_1_0.stoneCost_ = {}
	arg_1_0.needHeroNum_ = {}
	arg_1_0.equipLimit_ = {}

	import("app.common.tables.TableParser").parse("super_partner_star.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.star)

		arg_1_0.starColor_[var_2_0] = tonumber(arg_2_0.star_color)
		arg_1_0.manaCost_[var_2_0] = tonumber(arg_2_0.mana_cost)
		arg_1_0.stoneCost_[var_2_0] = tonumber(arg_2_0.stone_cost)
		arg_1_0.needHeroNum_[var_2_0] = tonumber(arg_2_0.need_hero_num)
		arg_1_0.equipLimit_[var_2_0] = tonumber(arg_2_0.equipment_limit)
	end)
end

function var_0_0.starColor(arg_3_0, arg_3_1)
	return arg_3_0.starColor_[arg_3_1] or 0
end

function var_0_0.manaCost(arg_4_0, arg_4_1)
	return arg_4_0.manaCost_[arg_4_1] or 0
end

function var_0_0.stoneCost(arg_5_0, arg_5_1)
	return arg_5_0.stoneCost_[arg_5_1] or 0
end

function var_0_0.needHeroNum(arg_6_0, arg_6_1)
	return arg_6_0.needHeroNum_[arg_6_1] or 0
end

function var_0_0.equipLimit(arg_7_0, arg_7_1)
	return arg_7_0.equipLimit_[arg_7_1] or 0
end

return var_0_0
