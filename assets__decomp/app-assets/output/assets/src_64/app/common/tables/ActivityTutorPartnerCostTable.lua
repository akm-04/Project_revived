local var_0_0 = class("ActivityTutorPartnerCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.playerLevel_ = {}
	arg_1_0.partnerColour_ = {}
	arg_1_0.partnerPrice_ = {}

	import("app.common.tables.TableParser").parse("activity_tutor_partner_cost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.playerLevel_[var_2_0] = tonumber(arg_2_0.player_level)
		arg_1_0.partnerColour_[var_2_0] = tonumber(arg_2_0.partner_colour)
		arg_1_0.partnerPrice_[var_2_0] = tonumber(arg_2_0.partner_price)
	end)
end

function var_0_0.playerLevel(arg_3_0, arg_3_1)
	return arg_3_0.playerLevel_[arg_3_1] or 0
end

function var_0_0.partnerColour(arg_4_0, arg_4_1)
	return arg_4_0.partnerColour_[arg_4_1] or 0
end

function var_0_0.partnerPrice(arg_5_0, arg_5_1)
	return arg_5_0.partnerPrice_[arg_5_1] or 0
end

function var_0_0.playerLevels(arg_6_0)
	return arg_6_0.playerLevel_
end

return var_0_0
