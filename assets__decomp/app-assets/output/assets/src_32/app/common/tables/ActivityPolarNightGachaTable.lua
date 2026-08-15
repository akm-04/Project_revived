local var_0_0 = class("ActivityPolarNightGachaTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rareType_ = {}
	arg_1_0.dropRate_ = {}
	arg_1_0.purpleIds = {}
	arg_1_0.blueIds = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_gacha.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.rareType_[var_2_0] = tonumber(arg_2_0.rare_type)
		arg_1_0.dropRate_[var_2_0] = tonumber(arg_2_0.drop_rate)

		if arg_1_0.rareType_[var_2_0] == 1 then
			table.insert(arg_1_0.purpleIds, var_2_0)
		elseif arg_1_0.rareType_[var_2_0] == 2 then
			table.insert(arg_1_0.blueIds, var_2_0)
		end
	end)
end

function var_0_0.getPurpleIds(arg_3_0)
	return arg_3_0.purpleIds or {}
end

function var_0_0.getBlueIds(arg_4_0)
	return arg_4_0.blueIds or {}
end

function var_0_0.itemId(arg_5_0, arg_5_1)
	return arg_5_0.itemId_[arg_5_1] or 0
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 0
end

function var_0_0.dropRate(arg_7_0, arg_7_1)
	return arg_7_0.dropRate_[arg_7_1] or 0
end

return var_0_0
