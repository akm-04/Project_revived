local var_0_0 = class("ActivityDecodeMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.content_ = {}
	arg_1_0.num_ = {}
	arg_1_0.energy_ = {}

	import("app.common.tables.TableParser").parse("activity_decode_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.content_[var_2_0] = arg_2_0.content
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.energy_[var_2_0] = tonumber(arg_2_0.energy)
	end)
end

function var_0_0.content(arg_3_0, arg_3_1)
	return arg_3_0.content_[arg_3_1] or ""
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1] or 0
end

function var_0_0.energy(arg_5_0, arg_5_1)
	return arg_5_0.energy_[arg_5_1] or 0
end

return var_0_0
