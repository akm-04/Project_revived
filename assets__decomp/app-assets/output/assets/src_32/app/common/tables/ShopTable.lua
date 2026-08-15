local var_0_0 = class("ShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.slotNums_ = {}
	arg_1_0.refreshTypes_ = {}
	arg_1_0.refreshKeys_ = {}
	arg_1_0.refreshTimes_ = {}
	arg_1_0.dialogClick_ = {}
	arg_1_0.soundClick_ = {}
	arg_1_0.timeClick_ = {}
	arg_1_0.dialogBuy_ = {}
	arg_1_0.soundBuy_ = {}
	arg_1_0.timeBuy_ = {}
	arg_1_0.dialogSoldOut_ = {}
	arg_1_0.soundSoldOut_ = {}
	arg_1_0.timeSoldOut_ = {}
	arg_1_0.imagePath_ = {}
	arg_1_0.shopChangePath_ = {}
	arg_1_0.shopChangeName_ = {}
	arg_1_0.specialDialog_ = {}
	arg_1_0.specialSound_ = {}
	arg_1_0.teamDungeonHomologousId_ = {}
	arg_1_0.isTeamShop_ = {}
	arg_1_0.isDynamic_ = {}
	arg_1_0.dynamicImagePath_ = {}
	arg_1_0.scaling_ = {}
	arg_1_0.location_ = {}
	arg_1_0.limitTimes_ = {}
	arg_1_0.isflip_ = {}
	arg_1_0.isAlone_ = {}

	import("app.common.tables.TableParser").parse("shop_config.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.slotNums_[var_2_0] = tonumber(arg_2_0.slot_num)
		arg_1_0.refreshTypes_[var_2_0] = tonumber(arg_2_0.refresh_type)
		arg_1_0.refreshKeys_[var_2_0] = arg_2_0.refresh_key
		arg_1_0.refreshTimes_[var_2_0] = xyd.splitToNumber(arg_2_0.refresh_time, "|")
		arg_1_0.dialogClick_[var_2_0] = xyd.split(arg_2_0.dialog_click, "|")
		arg_1_0.soundClick_[var_2_0] = xyd.split(arg_2_0.click_sound, "|")
		arg_1_0.timeClick_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog_click_time, "|")
		arg_1_0.dialogBuy_[var_2_0] = xyd.split(arg_2_0.dialog_buy, "|")
		arg_1_0.soundBuy_[var_2_0] = xyd.split(arg_2_0.buy_sound, "|")
		arg_1_0.timeBuy_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog_buy_time, "|")
		arg_1_0.dialogSoldOut_[var_2_0] = xyd.split(arg_2_0.dialog_sell_out, "|")
		arg_1_0.soundSoldOut_[var_2_0] = xyd.split(arg_2_0.sell_out_sound, "|")
		arg_1_0.timeSoldOut_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog_sell_out_time, "|")
		arg_1_0.imagePath_[var_2_0] = xyd.split(arg_2_0.shop_image, "|")
		arg_1_0.shopChangePath_[var_2_0] = arg_2_0.shop_change
		arg_1_0.shopChangeName_[var_2_0] = arg_2_0.shop_change_name
		arg_1_0.specialDialog_[var_2_0] = xyd.split(arg_2_0.dialog_special, "|")
		arg_1_0.specialSound_[var_2_0] = xyd.split(arg_2_0.special_sound, "|")
		arg_1_0.teamDungeonHomologousId_[var_2_0] = tonumber(arg_2_0.team_dungeon_homologous_id)
		arg_1_0.isTeamShop_[var_2_0] = tonumber(arg_2_0.is_team_shop)
		arg_1_0.isDynamic_[var_2_0] = tonumber(arg_2_0.is_dynamic)
		arg_1_0.dynamicImagePath_[var_2_0] = arg_2_0.dynamic_image
		arg_1_0.scaling_[var_2_0] = tonumber(arg_2_0.scaling)
		arg_1_0.location_[var_2_0] = xyd.splitToNumber(arg_2_0.location, "|")
		arg_1_0.limitTimes_[var_2_0] = xyd.splitToNumber(arg_2_0.limit_times, "|")
		arg_1_0.isflip_[var_2_0] = tonumber(arg_2_0.flip)
		arg_1_0.isAlone_[var_2_0] = tonumber(arg_2_0.is_alone)
	end)
end

function var_0_0.limitTimes(arg_3_0, arg_3_1)
	return arg_3_0.limitTimes_[arg_3_1] or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.names_[arg_4_1]
end

function var_0_0.slotNum(arg_5_0, arg_5_1)
	return arg_5_0.slotNums_[arg_5_1]
end

function var_0_0.refreshType(arg_6_0, arg_6_1)
	return arg_6_0.refreshTypes_[arg_6_1]
end

function var_0_0.refreshKey(arg_7_0, arg_7_1)
	return arg_7_0.refreshKeys_[arg_7_1]
end

function var_0_0.refreshTime(arg_8_0, arg_8_1)
	return arg_8_0.refreshTimes_[arg_8_1]
end

function var_0_0.isTeamShop(arg_9_0, arg_9_1)
	return arg_9_0.isTeamShop_[arg_9_1]
end

function var_0_0.isDynamic(arg_10_0, arg_10_1)
	return arg_10_0.isDynamic_[arg_10_1]
end

function var_0_0.dialogClick(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0.dialogClick_[arg_11_1]
	local var_11_1 = arg_11_0.soundClick_[arg_11_1]
	local var_11_2 = arg_11_0.timeClick_[arg_11_1]
	local var_11_3 = math.random(#var_11_0)

	return var_11_0[var_11_3], var_11_1[var_11_3], var_11_2[var_11_3]
end

function var_0_0.dialogBuy(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.dialogBuy_[arg_12_1]
	local var_12_1 = arg_12_0.soundBuy_[arg_12_1]
	local var_12_2 = arg_12_0.timeBuy_[arg_12_1]
	local var_12_3 = math.random(#var_12_0)

	return var_12_0[var_12_3], var_12_1[var_12_3], var_12_2[var_12_3]
end

function var_0_0.dialogSoldOut(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.dialogSoldOut_[arg_13_1]
	local var_13_1 = arg_13_0.soundSoldOut_[arg_13_1]
	local var_13_2 = arg_13_0.timeSoldOut_[arg_13_1]
	local var_13_3 = math.random(#var_13_0)

	return var_13_0[var_13_3], var_13_1[var_13_3], var_13_2[var_13_3]
end

function var_0_0.nextRefreshTime(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_0.refreshTimes_[arg_14_1]

	if not var_14_0 or not next(var_14_0) then
		return -1
	end

	for iter_14_0, iter_14_1 in pairs(var_14_0) do
		if arg_14_2 < iter_14_1 then
			return iter_14_1
		end
	end

	return -1
end

function var_0_0.imagePath(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_2 then
		return arg_15_0.imagePath_[arg_15_1][2]
	else
		return arg_15_0.imagePath_[arg_15_1][1]
	end
end

function var_0_0.dynamicImagePath(arg_16_0, arg_16_1)
	return arg_16_0.dynamicImagePath_[arg_16_1]
end

function var_0_0.shopChangePath(arg_17_0, arg_17_1)
	return arg_17_0.shopChangePath_[arg_17_1]
end

function var_0_0.shopChangeName(arg_18_0, arg_18_1)
	return arg_18_0.shopChangeName_[arg_18_1]
end

function var_0_0.teamDungeonHomologousIds(arg_19_0, arg_19_1)
	return arg_19_0.teamDungeonHomologousId_
end

function var_0_0.specialDialog(arg_20_0, arg_20_1, arg_20_2)
	if arg_20_2 then
		return arg_20_0.specialDialog_[arg_20_1][2]
	else
		return arg_20_0.specialDialog_[arg_20_1][1]
	end
end

function var_0_0.specialSound(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_2 then
		return arg_21_0.specialSound_[arg_21_1][2]
	else
		return arg_21_0.specialSound_[arg_21_1][1]
	end
end

function var_0_0.scaling(arg_22_0, arg_22_1)
	return arg_22_0.scaling_[arg_22_1] or 1
end

function var_0_0.location(arg_23_0, arg_23_1)
	return cc.p(arg_23_0.location_[arg_23_1][1], arg_23_0.location_[arg_23_1][2] or 0)
end

function var_0_0.isFlip(arg_24_0, arg_24_1)
	if arg_24_0.isflip_[arg_24_1] == 1 then
		return true
	else
		return false
	end
end

function var_0_0.isAlone(arg_25_0, arg_25_1)
	return arg_25_0.isAlone_[arg_25_1] or 0
end

return var_0_0
