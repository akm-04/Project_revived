local var_0_0 = class("VipBoxDrawTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.totalIds1_ = {}
	arg_1_0.totalIds2_ = {}
	arg_1_0.normalIds_ = {}
	arg_1_0.rareIds_ = {}

	import("app.common.tables.TableParser").parse("activity_en_christmas_hero.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.hero)
		local var_2_1 = tonumber(arg_2_0.type)
		local var_2_2 = tonumber(arg_2_0.rarity)

		if var_2_1 == 1 then
			table.insert(arg_1_0.totalIds1_, var_2_0)
		else
			table.insert(arg_1_0.totalIds2_, var_2_0)

			if var_2_2 == 1 then
				table.insert(arg_1_0.normalIds_, var_2_0)
			else
				table.insert(arg_1_0.rareIds_, var_2_0)
			end
		end
	end)
end

function var_0_0.normalIds(arg_3_0)
	return arg_3_0.normalIds_ or {}
end

function var_0_0.rareIds(arg_4_0)
	return arg_4_0.rareIds_ or {}
end

function var_0_0.totalIds1(arg_5_0)
	return arg_5_0.totalIds1_ or {}
end

function var_0_0.totalIds2(arg_6_0)
	return arg_6_0.totalIds2_ or {}
end

return var_0_0
