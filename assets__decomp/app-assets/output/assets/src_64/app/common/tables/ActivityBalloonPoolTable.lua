local var_0_0 = class("ActivityBalloonPoolTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.speicalItemId_ = {}

	import("app.common.tables.TableParser").parse("activity_balloon_pool.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.speicalItemId_[var_2_0] = tonumber(arg_2_0.speical_item_id)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.speicalItemId(arg_4_0, arg_4_1)
	return arg_4_0.speicalItemId_[arg_4_1] or 0
end

return var_0_0
