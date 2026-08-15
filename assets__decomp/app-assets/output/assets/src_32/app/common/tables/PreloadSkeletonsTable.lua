local var_0_0 = class("PreloadSkeletonsTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.path_ = {}

	import("app.common.tables.TableParser").parse("preload_skeletons.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.hero_name

		arg_1_0.path_[var_2_0] = {}

		local var_2_1 = arg_1_0:lua_string_split(arg_2_0.path, "|")

		if var_2_1 then
			for iter_2_0, iter_2_1 in pairs(var_2_1) do
				table.insert(arg_1_0.path_[var_2_0], iter_2_1)
			end
		end
	end)
end

function var_0_0.path(arg_3_0, arg_3_1)
	return arg_3_0.path_[arg_3_1]
end

function var_0_0.lua_string_split(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_1 then
		return nil
	end

	local var_4_0 = {}

	while true do
		local var_4_1 = string.find(arg_4_1, arg_4_2)

		if not var_4_1 then
			var_4_0[#var_4_0 + 1] = arg_4_1

			break
		end

		local var_4_2 = string.sub(arg_4_1, 1, var_4_1 - 1)

		var_4_0[#var_4_0 + 1] = var_4_2
		arg_4_1 = string.sub(arg_4_1, var_4_1 + 1, #arg_4_1)
	end

	return var_4_0
end

return var_0_0
