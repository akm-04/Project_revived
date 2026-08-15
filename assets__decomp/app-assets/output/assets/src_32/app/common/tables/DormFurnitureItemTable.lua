local var_0_0 = class("DormFurnitureItemTable")
local var_0_1 = {
	Floor = 1,
	RightWall = 3,
	LeftWall = 2
}

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids = {}
	arg_1_0.name_ = {}
	arg_1_0.subtype_ = {}
	arg_1_0.comfort_ = {}
	arg_1_0.floor_ = {}
	arg_1_0.paper_ = {}
	arg_1_0.canRotate_ = {}
	arg_1_0.canPile_ = {}
	arg_1_0.canBePile_ = {}
	arg_1_0.specialType_ = {}
	arg_1_0.placeWall_ = {}
	arg_1_0.coverLength_ = {}
	arg_1_0.coverWidth_ = {}
	arg_1_0.coverHeight_ = {}
	arg_1_0.isPileLimit_ = {}
	arg_1_0.pileLimitCoordinateStart_ = {}
	arg_1_0.pileLimitCoordinateEnd_ = {}
	arg_1_0.correctPos_ = {}
	arg_1_0.actType_ = {}
	arg_1_0.sleepIcon_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.wallIcon_ = {}
	arg_1_0.expandIcons_ = {}

	import("app.common.tables.TableParser").parse("dorm_furniture_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.item_id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.subtype_[var_2_0] = tonumber(arg_2_0.subtype)
		arg_1_0.comfort_[var_2_0] = tonumber(arg_2_0.comfort)
		arg_1_0.floor_[var_2_0] = tonumber(arg_2_0.floor)
		arg_1_0.paper_[var_2_0] = tonumber(arg_2_0.paper)
		arg_1_0.canRotate_[var_2_0] = tonumber(arg_2_0.can_rotate)
		arg_1_0.canPile_[var_2_0] = tonumber(arg_2_0.can_pile)
		arg_1_0.canBePile_[var_2_0] = tonumber(arg_2_0.can_be_pile)
		arg_1_0.specialType_[var_2_0] = tonumber(arg_2_0.special_type)
		arg_1_0.placeWall_[var_2_0] = xyd.splitToNumber(arg_2_0.place_wall, "|")
		arg_1_0.coverLength_[var_2_0] = tonumber(arg_2_0.cover_length)
		arg_1_0.coverWidth_[var_2_0] = tonumber(arg_2_0.cover_width)
		arg_1_0.coverHeight_[var_2_0] = tonumber(arg_2_0.cover_height)
		arg_1_0.isPileLimit_[var_2_0] = tonumber(arg_2_0.is_pile_limit)
		arg_1_0.pileLimitCoordinateStart_[var_2_0] = xyd.splitToNumber(arg_2_0.pile_limit_coordinate_start, "|")
		arg_1_0.pileLimitCoordinateEnd_[var_2_0] = xyd.splitToNumber(arg_2_0.pile_limit_coordinate_end, "|")
		arg_1_0.correctPos_[var_2_0] = xyd.splitToNumber(arg_2_0.correct_pos, "|")
		arg_1_0.actType_[var_2_0] = tonumber(arg_2_0.act_type)
		arg_1_0.sleepIcon_[var_2_0] = arg_2_0.sleep_icon
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.wallIcon_[var_2_0] = arg_2_0.wall_icon
		arg_1_0.expandIcons_[var_2_0] = xyd.split(arg_2_0.expand_icons, "|")
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.subtype(arg_5_0, arg_5_1)
	return arg_5_0.subtype_[arg_5_1] or 0
end

function var_0_0.comfort(arg_6_0, arg_6_1)
	return arg_6_0.comfort_[arg_6_1] or 0
end

function var_0_0.floor(arg_7_0, arg_7_1)
	return arg_7_0.floor_[arg_7_1] or 2
end

function var_0_0.paper(arg_8_0, arg_8_1)
	return arg_8_0.paper_[arg_8_1] or 0
end

function var_0_0.canRotate(arg_9_0, arg_9_1)
	return arg_9_0.canRotate_[arg_9_1] or 0
end

function var_0_0.canFlip(arg_10_0, arg_10_1)
	return arg_10_0:canRotate(arg_10_1) == 1
end

function var_0_0.canPile(arg_11_0, arg_11_1)
	return arg_11_0.canPile_[arg_11_1] or 0
end

function var_0_0.canBePile(arg_12_0, arg_12_1)
	return arg_12_0.canBePile_[arg_12_1] or 0
end

function var_0_0.specialType(arg_13_0, arg_13_1)
	return arg_13_0.specialType_[arg_13_1] or 0
end

function var_0_0.placeWall(arg_14_0, arg_14_1)
	return arg_14_0.placeWall_[arg_14_1] or {
		1
	}
end

function var_0_0.coverLength(arg_15_0, arg_15_1)
	return arg_15_0.coverLength_[arg_15_1] or 0
end

function var_0_0.coverWidth(arg_16_0, arg_16_1)
	return arg_16_0.coverWidth_[arg_16_1] or 0
end

function var_0_0.coverHeight(arg_17_0, arg_17_1)
	return arg_17_0.coverHeight_[arg_17_1] or 0
end

function var_0_0.getItemSize(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = {}

	if arg_18_1 == xyd.DormRoomGirlItemID then
		local var_18_1 = xyd.tables.misc.dormGirlCoverSize

		var_18_0.long, var_18_0.width, var_18_0.height = var_18_1[1], var_18_1[2], var_18_1[3]

		return var_18_0
	end

	local var_18_2 = arg_18_0:placeWall(arg_18_1)[1]

	var_18_0.long = arg_18_0:coverLength(arg_18_1)
	var_18_0.width = arg_18_0:coverWidth(arg_18_1)
	var_18_0.height = arg_18_0:coverHeight(arg_18_1)

	if arg_18_2 == 1 and var_18_2 == var_0_1.Floor then
		var_18_0.long, var_18_0.width = var_18_0.width, var_18_0.long
	end

	return var_18_0
end

function var_0_0.isPileLimit(arg_19_0, arg_19_1)
	return arg_19_0.isPileLimit_[arg_19_1] or 0
end

function var_0_0.pileLimitCoordinateStart(arg_20_0, arg_20_1)
	return arg_20_0.pileLimitCoordinateStart_[arg_20_1] or {}
end

function var_0_0.pileLimitCoordinateEnd(arg_21_0, arg_21_1)
	return arg_21_0.pileLimitCoordinateEnd_[arg_21_1] or {}
end

function var_0_0.correctPos(arg_22_0, arg_22_1)
	return arg_22_0.correctPos_[arg_22_1] or {}
end

function var_0_0.actType(arg_23_0, arg_23_1)
	return arg_23_0.actType_[arg_23_1] or 0
end

function var_0_0.wallIcon(arg_24_0, arg_24_1)
	return arg_24_0.wallIcon_[arg_24_1] or ""
end

function var_0_0.sleepIcon(arg_25_0, arg_25_1)
	return arg_25_0.sleepIcon_[arg_25_1] or ""
end

function var_0_0.icon(arg_26_0, arg_26_1)
	return arg_26_0.icon_[arg_26_1] or ""
end

function var_0_0.itemIds(arg_27_0)
	return table.keys(arg_27_0.name_) or {}
end

function var_0_0.expandIcons(arg_28_0, arg_28_1)
	return arg_28_0.expandIcons_[arg_28_1] or {}
end

return var_0_0
