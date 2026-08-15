local var_0_0 = class("ActivityChestNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.totalIds = {}

	import("app.common.tables.TableParser").parse("activity_chest2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.hero)
		local var_2_1 = tonumber(arg_2_0.type)
		local var_2_2 = tonumber(arg_2_0.rarity)

		if not arg_1_0.totalIds[var_2_1] then
			arg_1_0.totalIds[var_2_1] = {}
		end

		if not arg_1_0.totalIds[var_2_1][var_2_2] then
			arg_1_0.totalIds[var_2_1][var_2_2] = {}
		end

		table.insert(arg_1_0.totalIds[var_2_1][var_2_2], var_2_0)
	end)
end

function var_0_0.getTotalIds(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_2 then
		return arg_3_0.totalIds[arg_3_1] or {}
	elseif not arg_3_0.totalIds[arg_3_1] then
		return {}
	else
		return arg_3_0.totalIds[arg_3_1][arg_3_2] or {}
	end
end

return var_0_0
