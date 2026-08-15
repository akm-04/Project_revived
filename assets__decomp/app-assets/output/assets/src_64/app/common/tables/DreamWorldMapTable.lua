local var_0_0 = class("DreamWorldMapTable")
local var_0_1 = 26
local var_0_2 = 3

function var_0_0.ctor(arg_1_0)
	arg_1_0.cellID_ = {}

	for iter_1_0 = 1, var_0_2 do
		arg_1_0:parse(iter_1_0, "dreamworld_map" .. iter_1_0)
	end
end

function var_0_0.parse(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0.cellID_[arg_2_1] = {}

	import("app.common.tables.TableParser").parse(arg_2_2 .. ".lua", function(arg_3_0)
		for iter_3_0 = 1, var_0_1 do
			table.insert(arg_2_0.cellID_[arg_2_1], tonumber(arg_3_0[tostring(iter_3_0)]))
		end
	end)
end

function var_0_0.getCells(arg_4_0, arg_4_1)
	return arg_4_0.cellID_[arg_4_1]
end

return var_0_0
