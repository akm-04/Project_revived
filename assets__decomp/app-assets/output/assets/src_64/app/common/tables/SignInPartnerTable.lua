local var_0_0 = class("SignInPartnerTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.icon_ = {}
	arg_1_0.x_ = {}
	arg_1_0.y_ = {}
	arg_1_0.isSkin_ = {}

	import("app.common.tables.TableParser").parse("sign_in_partner.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.partner_id)

		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.x_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.y_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.isSkin_[var_2_0] = tonumber(arg_2_0.is_skin)
	end)
end

function var_0_0.icon(arg_3_0, arg_3_1)
	return arg_3_0.icon_[arg_3_1] or ""
end

function var_0_0.x(arg_4_0, arg_4_1)
	return arg_4_0.x_[arg_4_1] or 0
end

function var_0_0.y(arg_5_0, arg_5_1)
	return arg_5_0.y_[arg_5_1] or 0
end

function var_0_0.isSkin(arg_6_0, arg_6_1)
	return arg_6_0.isSkin_[arg_6_1] or 0
end

return var_0_0
