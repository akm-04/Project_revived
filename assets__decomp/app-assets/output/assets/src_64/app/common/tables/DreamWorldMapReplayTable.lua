local var_0_0 = class("DreamWorldMapReplayTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.startPoint_ = {}
	arg_1_0.endPoint_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_map_replay.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.startPoint_[var_2_0] = xyd.splitToNumber(arg_2_0.start_id, "|")
		arg_1_0.endPoint_[var_2_0] = xyd.splitToNumber(arg_2_0.end_id, "|")
	end)
end

function var_0_0.startPoint(arg_3_0, arg_3_1)
	return arg_3_0.startPoint_[arg_3_1] or {}
end

function var_0_0.endPoint(arg_4_0, arg_4_1)
	return arg_4_0.endPoint_[arg_4_1] or {}
end

return var_0_0
