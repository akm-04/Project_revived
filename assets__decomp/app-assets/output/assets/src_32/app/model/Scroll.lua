local var_0_0 = class("Scroll")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.scrollTableID_ = arg_1_1.scroll_id

	if arg_1_1.num then
		arg_1_0.scrollNum_ = arg_1_1.num
	end

	if arg_1_1.hero_id then
		arg_1_0.heroTableID_ = arg_1_1.hero_id
	end

	getmetatable(arg_1_0).__eq = function(arg_2_0, arg_2_1)
		return arg_2_0.scrollTableID_ == arg_2_1.scrollTableID_ and arg_2_0.heroTableID_ == arg_2_1.heroTableID_
	end
end

function var_0_0.getScrollID(arg_3_0)
	return arg_3_0.scrollTableID_
end

function var_0_0.getScrollNum(arg_4_0)
	return arg_4_0.scrollNum_
end

function var_0_0.getHeroID(arg_5_0)
	return arg_5_0.heroTableID_
end

function var_0_0.getName(arg_6_0)
	return xyd.tables.scroll:name(arg_6_0.scrollTableID_)
end

function var_0_0.getIcon(arg_7_0)
	if arg_7_0.heroTableID_ then
		return xyd.tables.hero:avatar(arg_7_0.heroTableID_, xyd.tables.scroll:initialStar(arg_7_0.heroTableID_))
	else
		return xyd.tables.scroll:icon(arg_7_0.scrollTableID_)
	end
end

function var_0_0.getDesc(arg_8_0)
	return xyd.tables.scroll:desc(arg_8_0.scrollTableID_)
end

function var_0_0.getMinStar(arg_9_0)
	return xyd.tables.scroll:minStar(arg_9_0.scrollTableID_)
end

function var_0_0.getMaxStar(arg_10_0)
	return xyd.tables.scroll:maxStar(arg_10_0.scrollTableID_)
end

function var_0_0.getPerfectStar(arg_11_0)
	return xyd.tables.scroll:perfectStar(arg_11_0.scrollTableID_)
end

local function var_0_1(arg_12_0)
	return xyd.tables.scroll:social(arg_12_0.scrollTableID_)
end

local function var_0_2(arg_13_0)
	return xyd.tables.scroll:crystal(arg_13_0.scrollTableID_)
end

local function var_0_3(arg_14_0)
	return xyd.tables.scroll:mana(arg_14_0.scrollTableID_)
end

function var_0_0.getCostType(arg_15_0)
	if var_0_1(arg_15_0) > 0 then
		return xyd.ScrollCostType.SOCIAL
	elseif var_0_2(arg_15_0) > 0 then
		return xyd.ScrollCostType.CRYSTAL
	elseif var_0_3(arg_15_0) >= 0 then
		return xyd.ScrollCostType.MANA
	else
		return xyd.ScrollCostType.UNKNOWN
	end
end

function var_0_0.getCost(arg_16_0)
	local var_16_0 = arg_16_0:getCostType()

	if var_16_0 == xyd.ScrollCostType.SOCIAL then
		return var_0_1(arg_16_0)
	elseif var_16_0 == xyd.ScrollCostType.CRYSTAL then
		return var_0_2(arg_16_0)
	elseif var_16_0 == xyd.ScrollCostType.MANA then
		return var_0_3(arg_16_0)
	else
		return 0
	end
end

function var_0_0.getHeroPiece(arg_17_0)
	return xyd.tables.scroll:piece(arg_17_0:getHeroID())
end

return var_0_0
