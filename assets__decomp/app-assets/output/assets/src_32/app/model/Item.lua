local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("Item")
local var_0_3 = var_0_1.tables.item
local var_0_4 = -1

function var_0_2.ctor(arg_1_0)
	arg_1_0.itemID_ = var_0_4

	if isClient then
		arg_1_0.selfPlayer = var_0_1.ModelManager.get():loadModel(var_0_1.ModelType.SELF_PLAYER)
		arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	end
end

function var_0_2.populate(arg_2_0, arg_2_1)
	arg_2_0.itemID_ = arg_2_1.item_id
	arg_2_0.tableID_ = arg_2_1.table_id
	arg_2_0.moneng_ = arg_2_1.moneng or 0
	arg_2_0.equipLevel_ = arg_2_1.equip_level or 0
	arg_2_0.collected_ = arg_2_1.is_collected or false
	arg_2_0.attrs_ = var_0_0.clone(var_0_3:attrs(arg_2_0:getTableID()))
	arg_2_0.fumoValuesByLevel_ = var_0_0.clone(var_0_3:fumoValuesByLevel(arg_2_0:getTableID())) or {}
end

function var_0_2.toParams(arg_3_0)
	return {
		item_id = arg_3_0.itemID_,
		table_id = arg_3_0.tableID_,
		moneng = arg_3_0.moneng_,
		equip_level = arg_3_0.equipLevel_,
		is_collected = arg_3_0.collected_
	}
end

function var_0_2.getTableID(arg_4_0)
	return arg_4_0.tableID_
end

function var_0_2.getName(arg_5_0)
	return var_0_3:name(arg_5_0:getTableID())
end

function var_0_2.getDesc(arg_6_0)
	return var_0_3:desc2(arg_6_0:getTableID())
end

function var_0_2.getSubDesc(arg_7_0)
	return var_0_3:desc1(arg_7_0:getTableID())
end

function var_0_2.getAttr(arg_8_0)
	return arg_8_0.attrs_
end

function var_0_2.getAttrFloat(arg_9_0, arg_9_1)
	local var_9_0 = var_0_0.clone(arg_9_0:getAttr())

	if arg_9_0.attrs_[1] and arg_9_0.attrs_[1] > 0 then
		var_9_0[var_0_1.AttributeType.HP] = math.ceil((var_9_0[var_0_1.AttributeType.HP] or 0) + arg_9_0.attrs_[1] * var_0_1.STRENGTH_HP_RATE)
		var_9_0[var_0_1.AttributeType.HUJIA] = math.ceil((var_9_0[var_0_1.AttributeType.HUJIA] or 0) + arg_9_0.attrs_[1] * var_0_1.STRENGTH_HUJIA_RATE)
	end

	if arg_9_0.attrs_[2] and arg_9_0.attrs_[2] > 0 then
		var_9_0[var_0_1.AttributeType.AP] = math.ceil((var_9_0[var_0_1.AttributeType.AP] or 0) + arg_9_0.attrs_[2] * var_0_1.WISE_AP_RATE)
		var_9_0[var_0_1.AttributeType.MOKANG] = math.ceil((var_9_0[var_0_1.AttributeType.MOKANG] or 0) + arg_9_0.attrs_[2] * var_0_1.WISE_MOKANG_RATE)
	end

	if arg_9_0.attrs_[3] and arg_9_0.attrs_[3] > 0 then
		var_9_0[var_0_1.AttributeType.AD] = math.ceil((var_9_0[var_0_1.AttributeType.AD] or 0) + arg_9_0.attrs_[3] * var_0_1.AGILE_AD_RATE)
		var_9_0[var_0_1.AttributeType.HUJIA] = math.ceil((var_9_0[var_0_1.AttributeType.HUJIA] or 0) + arg_9_0.attrs_[3] * var_0_1.AGILE_HUJIA_RATE)
		var_9_0[var_0_1.AttributeType.AD_BAOJI] = math.ceil((var_9_0[var_0_1.AttributeType.AD_BAOJI] or 0) + arg_9_0.attrs_[3] * var_0_1.AGILE_AD_BAOJI_RATE)
	end

	if arg_9_1 and arg_9_0.attrs_[arg_9_1] then
		var_9_0[var_0_1.AttributeType.AD] = (var_9_0[var_0_1.AttributeType.AD] or 0) + arg_9_0.attrs_[arg_9_1]
	end

	return var_9_0
end

function var_0_2.getEnhanceEquipAttr(arg_10_0)
	local var_10_0 = arg_10_0:getEquipLevel()

	if var_10_0 < 1 then
		return {}
	end

	local var_10_1 = var_0_1.tables.superEquipEnhance:getRate(var_10_0)
	local var_10_2 = var_0_0.clone(arg_10_0:getAttr())

	for iter_10_0, iter_10_1 in pairs(var_10_2) do
		var_10_2[iter_10_0] = iter_10_1 * var_10_1 - iter_10_1
	end

	return var_10_2
end

function var_0_2.getEnhanceEquipAttrByLevel(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0:getAttr()

	if not var_11_0[arg_11_1] then
		return 0
	end

	if arg_11_2 == 0 then
		return var_11_0[arg_11_1]
	end

	return var_11_0[arg_11_1] * var_0_1.tables.superEquipEnhance:getRate(arg_11_2)
end

function var_0_2.getEquipAttrFloat(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = var_0_0.clone(arg_12_0:getAttr())
	local var_12_1 = var_0_1.tables.superEquipEnhance:getRate(arg_12_0:getEquipLevel()) - var_0_1.tables.superEquipEnhance:getRate(arg_12_0:getEquipLevel() - arg_12_2)

	for iter_12_0, iter_12_1 in pairs(var_12_0) do
		var_12_0[iter_12_0] = iter_12_1 * var_12_1
	end

	if var_12_0[1] and var_12_0[1] > 0 then
		var_12_0[var_0_1.AttributeType.HP] = math.ceil((var_12_0[var_0_1.AttributeType.HP] or 0) + var_12_0[1] * var_0_1.STRENGTH_HP_RATE)
		var_12_0[var_0_1.AttributeType.HUJIA] = math.ceil((var_12_0[var_0_1.AttributeType.HUJIA] or 0) + var_12_0[1] * var_0_1.STRENGTH_HUJIA_RATE)
	end

	if var_12_0[2] and var_12_0[2] > 0 then
		var_12_0[var_0_1.AttributeType.AP] = math.ceil((var_12_0[var_0_1.AttributeType.AP] or 0) + var_12_0[2] * var_0_1.WISE_AP_RATE)
		var_12_0[var_0_1.AttributeType.MOKANG] = math.ceil((var_12_0[var_0_1.AttributeType.MOKANG] or 0) + var_12_0[2] * var_0_1.WISE_MOKANG_RATE)
	end

	if var_12_0[3] and var_12_0[3] > 0 then
		var_12_0[var_0_1.AttributeType.AD] = math.ceil((var_12_0[var_0_1.AttributeType.AD] or 0) + var_12_0[3] * var_0_1.AGILE_AD_RATE)
		var_12_0[var_0_1.AttributeType.HUJIA] = math.ceil((var_12_0[var_0_1.AttributeType.HUJIA] or 0) + var_12_0[3] * var_0_1.AGILE_HUJIA_RATE)
		var_12_0[var_0_1.AttributeType.AD_BAOJI] = math.ceil((var_12_0[var_0_1.AttributeType.AD_BAOJI] or 0) + var_12_0[3] * var_0_1.AGILE_AD_BAOJI_RATE)
	end

	if arg_12_1 and var_12_0[arg_12_1] then
		var_12_0[var_0_1.AttributeType.AD] = (var_12_0[var_0_1.AttributeType.AD] or 0) + var_12_0[arg_12_1]
	end

	return var_12_0
end

function var_0_2.getFumoAttr(arg_13_0)
	if arg_13_0:getFumoLev() < 1 then
		return {}
	end

	return arg_13_0.fumoValuesByLevel_[arg_13_0:getFumoLev()] or {}
end

function var_0_2.getFumoByLevel(arg_14_0, arg_14_1)
	if arg_14_1 < 1 then
		return {}
	end

	return arg_14_0.fumoValuesByLevel_[arg_14_1] or {}
end

function var_0_2.getIcon(arg_15_0, arg_15_1)
	if arg_15_1 then
		local var_15_0 = {
			filter = {}
		}

		var_15_0.filter.name = "GRAY"
		var_15_0.filter.value = {
			0.2,
			0.3,
			0.5,
			0.1
		}

		return var_0_1.SpriteLoader.new(var_0_3:icon(arg_15_0:getTableID()), nil, var_15_0, var_0_1.DefaultImageType.ITEM_ICON)
	else
		return var_0_1.SpriteLoader.new(var_0_3:icon(arg_15_0:getTableID()), nil, nil, var_0_1.DefaultImageType.ITEM_ICON)
	end
end

function var_0_2.getSmallIcon(arg_16_0)
	return var_0_1.AssetLoader.get():loadSprite(var_0_3:smallIcon(arg_16_0:getTableID()))
end

function var_0_2.getFumoLev(arg_17_0)
	local var_17_0 = 0
	local var_17_1 = arg_17_0.moneng_
	local var_17_2 = arg_17_0:getFumoNeed()

	if var_17_1 >= arg_17_0:getTotalFumo() then
		return arg_17_0:getMaxFumoStar()
	end

	for iter_17_0, iter_17_1 in pairs(var_17_2) do
		if var_17_1 - iter_17_1 >= 0 then
			var_17_1 = var_17_1 - iter_17_1
			var_17_0 = var_17_0 + 1
		else
			break
		end
	end

	arg_17_0.fumoLev_ = var_17_0

	return arg_17_0.fumoLev_
end

function var_0_2.getMaxFumoStar(arg_18_0)
	return #arg_18_0:getFumoNeed()
end

function var_0_2.getCurrentLevelMoneng(arg_19_0)
	local var_19_0 = arg_19_0.moneng_
	local var_19_1 = arg_19_0:getFumoNeed()

	for iter_19_0 = 1, arg_19_0:getFumoLev() do
		var_19_0 = var_19_0 - var_19_1[iter_19_0]
	end

	if var_19_0 >= var_19_1[#var_19_1] or arg_19_0:getFumoLev() == arg_19_0:getMaxFumoStar() then
		var_19_0 = var_19_1[#var_19_1]
	end

	return var_19_0
end

function var_0_2.getFumoNeed(arg_20_0)
	arg_20_0.fumoNeed_ = arg_20_0.fumoNeed_ or var_0_3:fumo(arg_20_0:getTableID())

	if #arg_20_0.fumoNeed_ == 1 and arg_20_0.fumoNeed_[1] == 0 then
		arg_20_0.fumoNeed_ = {}
	end

	return arg_20_0.fumoNeed_
end

function var_0_2.getTotalFumo(arg_21_0)
	local var_21_0 = 0

	for iter_21_0 = 1, #arg_21_0.fumoNeed_ do
		var_21_0 = arg_21_0.fumoNeed_[iter_21_0] + var_21_0
	end

	return var_21_0
end

function var_0_2.getColor(arg_22_0)
	return var_0_3:quality(arg_22_0:getTableID())
end

function var_0_2.setStateCollected(arg_23_0)
	arg_23_0.collected_ = true
end

function var_0_2.isCollected(arg_24_0)
	return arg_24_0.collected_
end

function var_0_2.setCollected(arg_25_0)
	arg_25_0.collected_ = true
end

function var_0_2.toString(arg_26_0)
	return json.encode(arg_26_0:toParams())
end

function var_0_2.getLevel(arg_27_0)
	return var_0_3:level(arg_27_0:getTableID())
end

function var_0_2.getSelfNum(arg_28_0)
	return arg_28_0.backpack:getItemNumByID(arg_28_0:getTableID())
end

function var_0_2.isInBackpack(arg_29_0)
	if not arg_29_0.backpack then
		return false
	end

	return arg_29_0.backpack:getItemNumByID(arg_29_0:getTableID()) > 0
end

function var_0_2.getCompose(arg_30_0, arg_30_1)
	if arg_30_1 then
		return var_0_3:compose(arg_30_0:getTableID(), arg_30_1)
	end

	return var_0_3:compose(arg_30_0:getTableID())
end

function var_0_2.getComposeNum(arg_31_0, arg_31_1)
	if arg_31_1 then
		return var_0_3:composeNum(arg_31_0:getTableID(), arg_31_1)
	end

	return var_0_3:composeNum(arg_31_0:getTableID())
end

function var_0_2.composeMana(arg_32_0)
	return var_0_3:composeMana(arg_32_0:getTableID())
end

function var_0_2.isHasMaterial(arg_33_0)
	arg_33_0.stack_ = {}
	arg_33_0.bag_ = {}
	arg_33_0.composeMana_ = 0
	arg_33_0.selfPlayer = var_0_1.ModelManager.get():loadModel(var_0_1.ModelType.SELF_PLAYER)
	arg_33_0.backpack = arg_33_0.selfPlayer:getBackpack()

	return arg_33_0:recursionCompose()
end

function var_0_2.recursionCompose(arg_34_0)
	arg_34_0.currentItem_ = arg_34_0:getStackItem()

	if arg_34_0.currentItem_ == nil then
		return false
	end

	if arg_34_0:currentItemHasMaterial() then
		for iter_34_0, iter_34_1 in ipairs(arg_34_0.currentItem_:getCompose()) do
			arg_34_0.bag_[iter_34_1] = arg_34_0.bag_[iter_34_1] - arg_34_0.currentItem_:getComposeNum(iter_34_0)
		end

		arg_34_0.bag_[arg_34_0.currentItem_:getTableID()] = arg_34_0.bag_[arg_34_0.currentItem_:getTableID()] + 1

		arg_34_0:popItem()

		if arg_34_0.currentItem_ ~= arg_34_0 then
			return arg_34_0:recursionCompose()
		else
			return true
		end
	elseif arg_34_0:pushItem() then
		return arg_34_0:recursionCompose()
	else
		return false
	end
end

function var_0_2.currentItemHasMaterial(arg_35_0)
	local var_35_0 = arg_35_0.currentItem_:getCompose()

	if not next(var_35_0) or var_35_0[1] == 0 then
		return false
	end

	if not arg_35_0.backpack then
		return
	end

	arg_35_0.bag_[arg_35_0.currentItem_:getTableID()] = arg_35_0.bag_[arg_35_0.currentItem_:getTableID()] or arg_35_0.backpack:getItemNumByID(arg_35_0.currentItem_:getTableID())

	local var_35_1 = {}

	for iter_35_0, iter_35_1 in ipairs(var_35_0) do
		arg_35_0.bag_[iter_35_1] = arg_35_0.bag_[iter_35_1] or arg_35_0.backpack:getItemNumByID(iter_35_1)
		var_35_1[iter_35_1] = var_35_1[iter_35_1] or arg_35_0.bag_[iter_35_1]

		if arg_35_0.currentItem_:getComposeNum(iter_35_0) > var_35_1[iter_35_1] then
			return false
		else
			var_35_1[iter_35_1] = var_35_1[iter_35_1] - arg_35_0.currentItem_:getComposeNum(iter_35_0)
		end
	end

	return true
end

function var_0_2.popItem(arg_36_0)
	table.remove(arg_36_0.stack_)
end

function var_0_2.pushItem(arg_37_0)
	if not arg_37_0.backpack then
		return false
	end

	local var_37_0 = arg_37_0.currentItem_:getCompose()

	if not next(var_37_0) or var_37_0[1] == 0 then
		return false
	end

	local var_37_1 = {}

	for iter_37_0, iter_37_1 in ipairs(arg_37_0.currentItem_:getCompose()) do
		arg_37_0.bag_[iter_37_1] = arg_37_0.bag_[iter_37_1] or arg_37_0.backpack:getItemNumByID(iter_37_1)
		var_37_1[iter_37_1] = var_37_1[iter_37_1] or arg_37_0.bag_[iter_37_1]

		if arg_37_0.currentItem_:getComposeNum(iter_37_0) > var_37_1[iter_37_1] then
			local var_37_2 = var_0_2.new()

			var_37_2:populate({
				table_id = iter_37_1
			})
			table.insert(arg_37_0.stack_, var_37_2)

			return true
		else
			var_37_1[iter_37_1] = var_37_1[iter_37_1] - arg_37_0.currentItem_:getComposeNum(iter_37_0)
		end
	end

	return false
end

function var_0_2.getStackItem(arg_38_0)
	if #arg_38_0.stack_ > 0 then
		return arg_38_0.stack_[#arg_38_0.stack_]
	end

	local var_38_0 = arg_38_0:getCompose()

	if not next(var_38_0) or var_38_0[1] == 0 then
		return
	end

	table.insert(arg_38_0.stack_, arg_38_0)

	return arg_38_0:getStackItem()
end

function var_0_2.addFumo(arg_39_0, arg_39_1)
	local var_39_0 = var_0_1.tables.item:moneng(arg_39_1.itemID)

	arg_39_0.moneng_ = arg_39_0.moneng_ + var_39_0
end

function var_0_2.removeFumo(arg_40_0, arg_40_1)
	local var_40_0 = var_0_1.tables.item:moneng(arg_40_1.itemID)

	arg_40_0.moneng_ = arg_40_0.moneng_ - var_40_0
end

function var_0_2.initDrop(arg_41_0, arg_41_1)
	local var_41_0 = var_0_1.tables.campaign:itemDisplay(arg_41_1)
	local var_41_1 = var_0_1.tables.campaign:monsterDisplay(arg_41_1)
	local var_41_2 = var_0_1.tables.campaign:fightID(arg_41_1)
	local var_41_3 = var_0_1.tables.battle:dropWeight(var_41_2)
	local var_41_4 = var_0_1.tables.battle:monsters(var_41_2)
	local var_41_5 = 1

	for iter_41_0, iter_41_1 in ipairs(var_41_4) do
		if next(iter_41_1) == nil then
			break
		end

		var_41_5 = iter_41_0
	end

	if next(var_41_1) then
		for iter_41_2, iter_41_3 in ipairs(var_41_0) do
			if iter_41_3 == arg_41_0:getTableID() then
				arg_41_0.drop_ = {
					var_41_5,
					#var_41_1
				}

				return
			end
		end
	end

	if not next(var_41_3) then
		print("================ error drop weight is null ======================")
		print("================ error battleid id " .. var_41_2 .. " ======================")
	end

	local var_41_6 = var_0_1.weightedChoise(var_41_3)
	local var_41_7 = var_0_1.tables.battle:monsters(var_41_2, var_41_6)
	local var_41_8 = {}

	for iter_41_4 = 1, #var_41_7 do
		table.insert(var_41_8, 1)
	end

	local var_41_9 = var_0_1.weightedChoise(var_41_8)

	arg_41_0.drop_ = {
		var_41_6,
		var_41_9
	}
end

function var_0_2.getEquipLevel(arg_42_0)
	return arg_42_0.equipLevel_
end

function var_0_2.addEquipLevel(arg_43_0, arg_43_1)
	arg_43_0.equipLevel_ = arg_43_0.equipLevel_ + arg_43_1
end

return var_0_2
