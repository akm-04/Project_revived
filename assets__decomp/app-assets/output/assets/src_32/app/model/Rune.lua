local var_0_0 = xyd.tables.rune
local var_0_1 = class("RuneAttr")
local var_0_2 = -1

function var_0_1.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_1 = arg_1_1 or 0
	arg_1_2 = arg_1_2 or 0

	if arg_1_1 then
		arg_1_0.attrID_ = arg_1_1
		arg_1_0.value_ = arg_1_2
	else
		arg_1_0.attrID_ = var_0_2
	end
end

function var_0_1.outputToLabel(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = var_0_0:getAttrName(arg_2_0.attrID_)
	local var_2_1

	if var_0_0:isRatio(arg_2_0.attrID_) then
		var_2_1 = string.format("+%.0f%%", arg_2_0.value_ / xyd.DECIMAL_BASE * 100)
	else
		var_2_1 = "+" .. arg_2_0.value_
	end

	if arg_2_2 then
		arg_2_1:setString(var_2_0)
		arg_2_2:setString(var_2_1)
	else
		arg_2_1:setString(var_2_0 .. var_2_1)
	end
end

local var_0_3 = xyd.AssetLoader.get()
local var_0_4 = class("Rune")
local var_0_5 = -1

function var_0_4.ctor(arg_3_0)
	arg_3_0.runeID_ = var_0_5
end

function var_0_4.populate(arg_4_0, arg_4_1)
	arg_4_0.runeID_ = arg_4_1.rune_id or arg_4_0.runeID_
	arg_4_0.tableID_ = arg_4_1.table_id or arg_4_0.tableID_
	arg_4_0.star_ = arg_4_1.star or arg_4_0.star_
	arg_4_0.level_ = arg_4_1.power_lev or arg_4_0.level_
	arg_4_0.rarity_ = arg_4_1.rarity or arg_4_0.rarity_

	if arg_4_1.attr_main_id then
		arg_4_0.mainAttr_ = var_0_1.new(arg_4_1.attr_main_id, var_0_0:getMainAttrValue(arg_4_1.attr_main_id, arg_4_0.star_, arg_4_0.level_))
	end

	if arg_4_0.mainAttr_ and arg_4_1.power_lev then
		arg_4_0.mainAttr_.value_ = var_0_0:getMainAttrValue(arg_4_0.mainAttr_.attrID_, arg_4_0.star_, arg_4_0.level_)
	end

	if arg_4_1.attr_extra_id then
		arg_4_0.extraAttr_ = var_0_1.new(arg_4_1.attr_extra_id, arg_4_1.attr_extra_value)
	end

	arg_4_0.bonusAttrs_ = arg_4_0.bonusAttrs_ or {
		var_0_1.new(),
		var_0_1.new(),
		var_0_1.new(),
		var_0_1.new()
	}

	if arg_4_1.attr_bonus_1_id then
		arg_4_0.bonusAttrs_[1] = var_0_1.new(arg_4_1.attr_bonus_1_id, arg_4_1.attr_bonus_1_value)
	end

	if arg_4_1.attr_bonus_2_id then
		arg_4_0.bonusAttrs_[2] = var_0_1.new(arg_4_1.attr_bonus_2_id, arg_4_1.attr_bonus_2_value)
	end

	if arg_4_1.attr_bonus_3_id then
		arg_4_0.bonusAttrs_[3] = var_0_1.new(arg_4_1.attr_bonus_3_id, arg_4_1.attr_bonus_3_value)
	end

	if arg_4_1.attr_bonus_4_id then
		arg_4_0.bonusAttrs_[4] = var_0_1.new(arg_4_1.attr_bonus_4_id, arg_4_1.attr_bonus_4_value)
	end
end

function var_0_4.toParams(arg_5_0)
	local var_5_0 = {
		rune_id = arg_5_0.runeID_,
		table_id = arg_5_0.tableID_,
		star = arg_5_0.star_,
		power_lev = arg_5_0.level_,
		rarity = arg_5_0.rarity_
	}

	if arg_5_0.mainAttr_ then
		var_5_0.attr_main_id = arg_5_0.mainAttr_.attrID_
	end

	if arg_5_0.extraAttr_ then
		var_5_0.attr_extra_id = arg_5_0.extraAttr_.attrID_
		var_5_0.attr_extra_value = arg_5_0.extraAttr_.value_
	end

	if arg_5_0.bonusAttrs_ then
		for iter_5_0 = 1, 4 do
			if arg_5_0.bonusAttrs_[iter_5_0] then
				var_5_0["attr_bonus_" .. iter_5_0 .. "_id"] = arg_5_0.bonusAttrs_[iter_5_0].attrID_
				var_5_0["attr_bonus_" .. iter_5_0 .. "_value"] = arg_5_0.bonusAttrs_[iter_5_0].value_
			end
		end
	end

	return var_5_0
end

function var_0_4.toString(arg_6_0)
	return json.encode(arg_6_0:toParams())
end

function var_0_4.getName(arg_7_0)
	local var_7_0 = var_0_0:getMainName(arg_7_0.tableID_)
	local var_7_1 = (var_0_0:getPrefixName(arg_7_0.extraAttr_.attrID_) .. var_7_0) .. var_0_0:getSuffixName(arg_7_0.rarity_)

	if arg_7_0.level_ > 0 then
		var_7_1 = "+" .. arg_7_0.level_ .. " " .. var_7_1
	end

	return var_7_1
end

function var_0_4.getStar(arg_8_0)
	return arg_8_0.star_
end

function var_0_4.getLevel(arg_9_0)
	return arg_9_0.level_
end

function var_0_4.getTableID(arg_10_0)
	return arg_10_0.tableID_
end

function var_0_4.getRuneID(arg_11_0)
	return arg_11_0.runeID_
end

function var_0_4.getRarity(arg_12_0)
	return arg_12_0.rarity_
end

function var_0_4.getMainAttr(arg_13_0)
	return clone(arg_13_0.mainAttr_)
end

function var_0_4.getExtraAttr(arg_14_0)
	return clone(arg_14_0.extraAttr_)
end

function var_0_4.getBonusAttr(arg_15_0, arg_15_1)
	return clone(arg_15_0.bonusAttrs_[arg_15_1])
end

function var_0_4.getSlot(arg_16_0)
	return var_0_0:getSlot(arg_16_0.tableID_)
end

function var_0_4.getSetID(arg_17_0)
	return var_0_0:getRuneSet(arg_17_0.tableID_)
end

function var_0_4.getUnequipPrice(arg_18_0)
	return var_0_0:getUnequipPrice(arg_18_0.star_)
end

function var_0_4.getPowerupPrice(arg_19_0)
	return var_0_0:getPowerupPrice(arg_19_0.level_, arg_19_0.star_)
end

function var_0_4.getNextMainAttrValue(arg_20_0)
	if arg_20_0.level_ == 15 then
		return ""
	end

	local var_20_0 = var_0_0:getMainAttrValue(arg_20_0.mainAttr_.attrID_, arg_20_0.star_, arg_20_0.level_ + 1)
	local var_20_1

	if var_0_0:isRatio(arg_20_0.mainAttr_.attrID_) then
		var_20_1 = string.format("+%.0f%%", var_20_0 / xyd.DECIMAL_BASE * 100)
	else
		var_20_1 = "+" .. var_20_0
	end

	return var_20_1
end

function var_0_4.getSellPrice(arg_21_0)
	return math.floor(var_0_0:getBaseSellPrice(var_0_0:getSlot(arg_21_0.tableID_), arg_21_0.star_) * var_0_0:getSellRatio(var_0_0:getRuneSet(arg_21_0.tableID_), arg_21_0.rarity_, arg_21_0.extraAttr_.attrID_) / xyd.DECIMAL_BASE)
end

function var_0_4.getIcon(arg_22_0, arg_22_1)
	local var_22_0

	if arg_22_1 then
		var_22_0 = var_0_3:loadSprite(var_0_0:getCircleBackground(arg_22_0.rarity_))
	else
		var_22_0 = var_0_3:loadSprite(var_0_0:getSquareBackground(arg_22_0.rarity_))
	end

	if not var_22_0 then
		return var_22_0
	end

	local var_22_1 = var_0_3:loadSprite(var_0_0:getRuneImage(arg_22_0.tableID_))

	xyd.displaySpriteOnContainer(var_22_1, var_22_0, false)

	return var_22_0
end

function var_0_4.getColor(arg_23_0)
	return ({
		cc.c4b(255, 255, 255, 255),
		cc.c4b(108, 255, 0, 255),
		cc.c4b(0, 152, 255, 255),
		cc.c4b(234, 0, 255, 255),
		(cc.c4b(255, 150, 0, 255))
	})[arg_23_0.rarity_]
end

function var_0_4.powerup(arg_24_0, arg_24_1)
	xyd.Backend.get():request(xyd.mid.POWERUP_RUNE, {
		rune_id = arg_24_0.runeID_
	}, function(arg_25_0)
		if arg_24_1 then
			arg_24_1(arg_25_0)
		end
	end)
end

return var_0_4
