local var_0_0 = class("Backpack")
local var_0_1 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0)
	arg_1_0.list_ = {}
end

function var_0_0.populate(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.list
	local var_2_1 = arg_2_1.spirit_list

	arg_2_0.list_ = {}

	for iter_2_0, iter_2_1 in ipairs(var_2_0) do
		local var_2_2 = {
			itemTime = iter_2_1.time,
			itemID = iter_2_1.table_id,
			itemNum = iter_2_1.item_num
		}

		var_2_2.itemType = xyd.tables.item:type(var_2_2.itemID)
		var_2_2.itemQuality = xyd.tables.item:quality(var_2_2.itemID)
		var_2_2.startTime = iter_2_1.time

		table.insert(arg_2_0.list_, var_2_2)
	end

	arg_2_0.spiritList_ = {}
	arg_2_0.spiritNum_ = 0

	if var_2_1 then
		for iter_2_2, iter_2_3 in ipairs(var_2_1) do
			arg_2_0.spiritList_[iter_2_3.spirit_id] = iter_2_3
			arg_2_0.spiritNum_ = arg_2_0.spiritNum_ + 1
		end
	end
end

function var_0_0.getItemNumByID(arg_3_0, arg_3_1)
	if arg_3_0.list_ == nil then
		return 0
	end

	for iter_3_0, iter_3_1 in pairs(arg_3_0.list_) do
		if iter_3_1.itemID == arg_3_1 then
			return iter_3_1.itemNum
		end
	end

	return 0
end

function var_0_0.getSkillBookNum(arg_4_0)
	if arg_4_0.list_ == nil then
		return 0
	end

	for iter_4_0, iter_4_1 in pairs(arg_4_0.list_) do
		if iter_4_1.itemID == xyd.tables.misc.skillBookItem then
			return iter_4_1.itemNum
		end
	end

	return 0
end

function var_0_0.getItemByID(arg_5_0, arg_5_1)
	if not arg_5_0.list_ then
		return
	end

	for iter_5_0, iter_5_1 in pairs(arg_5_0.list_) do
		if iter_5_1.itemID == arg_5_1 then
			return iter_5_1
		end
	end
end

function var_0_0.setItemNumByID(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_0.list_ == nil then
		return 0
	end

	for iter_6_0 = #arg_6_0.list_, 1, -1 do
		if arg_6_0.list_[iter_6_0].itemID == arg_6_1 then
			arg_6_0.list_[iter_6_0].itemNum = arg_6_2
		end

		if arg_6_0.list_[iter_6_0].itemNum <= 0 then
			table.remove(arg_6_0.list_, iter_6_0)
		end
	end
end

function var_0_0.getItemsByTypes(arg_7_0, arg_7_1)
	local var_7_0 = {}
	local var_7_1 = 0
	local var_7_2 = 0
	local var_7_3 = {}
	local var_7_4 = {
		[xyd.ItemType.CONSUMABLES] = 1,
		[xyd.ItemType.EQUIPMENT] = 2,
		[xyd.ItemType.REEL] = 3,
		[xyd.ItemType.REEL_FRAGMENT] = 4,
		[xyd.ItemType.EQUIPMENT_FRAGMENT] = 5,
		[xyd.ItemType.STONE] = 6,
		[xyd.ItemType.INSCRIPTION] = 7
	}

	for iter_7_0, iter_7_1 in pairs(arg_7_0.list_) do
		if table.indexof(arg_7_1, iter_7_1.itemType) then
			if var_7_4[iter_7_1.itemType] == nil then
				var_7_4[iter_7_1.itemType] = iter_7_1.itemType
			end

			if var_7_1 < var_7_4[iter_7_1.itemType] then
				var_7_1 = var_7_4[iter_7_1.itemType]
			end

			if var_7_2 < iter_7_1.itemQuality then
				var_7_2 = iter_7_1.itemQuality
			end

			if var_7_3[var_7_4[iter_7_1.itemType]] == nil then
				var_7_3[var_7_4[iter_7_1.itemType]] = {}
			end

			if var_7_3[var_7_4[iter_7_1.itemType]][iter_7_1.itemQuality] == nil then
				var_7_3[var_7_4[iter_7_1.itemType]][iter_7_1.itemQuality] = {}
			end

			table.insert(var_7_3[var_7_4[iter_7_1.itemType]][iter_7_1.itemQuality], iter_7_1)
		end
	end

	for iter_7_2 = 1, var_7_1 do
		if var_7_3[iter_7_2] ~= nil then
			for iter_7_3 = 1, var_7_2 do
				if var_7_3[iter_7_2][iter_7_3] ~= nil then
					table.insertto(var_7_0, var_7_3[iter_7_2][iter_7_3])
				end
			end
		end
	end

	return var_7_0
end

function var_0_0.getItems(arg_8_0)
	return arg_8_0.list_
end

function var_0_0.getSpiritItems(arg_9_0)
	return arg_9_0.spiritList_
end

function var_0_0.getSpiritNum(arg_10_0)
	return arg_10_0.spiritNum_
end

function var_0_0.getSpiritItemBySpiritID(arg_11_0, arg_11_1)
	return arg_11_0.spiritList_[arg_11_1]
end

function var_0_0.addItem(arg_12_0, arg_12_1)
	local function var_12_0(arg_13_0)
		local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if arg_13_0.itemType == xyd.ItemType.STONE then
			local var_13_1 = xyd.tables.item:heroID(arg_13_0.itemID)
			local var_13_2 = xyd.db.localGuides:getLocalGuideID(var_13_0.playerID, var_13_1)

			if var_13_0:getHeroByTableID(var_13_1) == nil and var_13_0:getHeroByTableID(xyd.tables.hero:afterAwaken(var_13_1)) == nil and var_13_2 == 0 then
				local var_13_3 = var_0_1.new()

				var_13_3:initUnCollected(var_13_1)

				if var_13_3:canSummon() then
					xyd.db.localGuides:setLocalGuideID(var_13_0.playerID, var_13_1)
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.PLAY_FUNC_GUIDE,
						params = {
							guide_id = var_13_1
						}
					})
				end
			end
		end
	end

	local var_12_1 = false

	arg_12_1.itemType = xyd.tables.item:type(arg_12_1.itemID)
	arg_12_1.itemQuality = xyd.tables.item:quality(arg_12_1.itemID)
	arg_12_1.itemTime = xyd.ServerTime.get():getServerTime()

	if #arg_12_0.list_ == 0 then
		table.insert(arg_12_0.list_, arg_12_1)
		var_12_0(arg_12_1)

		return
	end

	for iter_12_0, iter_12_1 in pairs(arg_12_0.list_) do
		if iter_12_1.itemID == arg_12_1.itemID then
			iter_12_1.itemNum = iter_12_1.itemNum + arg_12_1.itemNum

			if iter_12_1.itemNum > xyd.tables.item:stack(arg_12_1.itemID) then
				var_12_1 = true
				iter_12_1.itemNum = xyd.tables.item:stack(arg_12_1.itemID)
			end

			if var_12_1 and xyd.tables.item:stackMail(arg_12_1.itemID) == 1 and not xyd.WindowManager.get():getWindow("toast") then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ITEM_EXCEED_TIP")
				})
			end

			var_12_0(arg_12_1)

			return
		end
	end

	table.insert(arg_12_0.list_, arg_12_1)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):checkEquipableAndSummon()
	var_12_0(arg_12_1)
end

function var_0_0.addSpiritItem(arg_14_0, arg_14_1)
	arg_14_0.spiritList_[arg_14_1.spirit_id] = arg_14_1
	arg_14_0.spiritNum_ = arg_14_0.spiritNum_ + 1
end

function var_0_0.removeSpiritItems(arg_15_0, arg_15_1)
	for iter_15_0, iter_15_1 in ipairs(arg_15_1) do
		arg_15_0.spiritList_[iter_15_1] = nil
		arg_15_0.spiritNum_ = arg_15_0.spiritNum_ - 1
	end
end

function var_0_0.removeItem(arg_16_0, arg_16_1)
	if #arg_16_0.list_ == 0 then
		return
	end

	for iter_16_0 = #arg_16_0.list_, 1, -1 do
		if arg_16_0.list_[iter_16_0].itemID == arg_16_1.itemID then
			arg_16_0.list_[iter_16_0].itemNum = math.max(arg_16_0.list_[iter_16_0].itemNum - arg_16_1.itemNum, 0)

			if arg_16_0.list_[iter_16_0].itemNum == 0 then
				table.remove(arg_16_0.list_, iter_16_0)
			end

			break
		end
	end

	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):checkEquipableAndSummon()
end

function var_0_0.delItem(arg_17_0, arg_17_1)
	if not arg_17_0.list_ or not next(arg_17_0.list_) then
		return
	end

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.list_) do
		if iter_17_1.itemID == arg_17_1 then
			table.remove(arg_17_0.list_, iter_17_0)

			break
		end
	end

	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):checkEquipableAndSummon()
end

function var_0_0.addItemsByID(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = {
		itemID = arg_18_1,
		itemNum = arg_18_2,
		itemTime = xyd.ServerTime.get():getServerTime()
	}

	var_18_0.itemType = xyd.tables.item:type(var_18_0.itemID)
	var_18_0.itemQuality = xyd.tables.item:quality(var_18_0.itemID)

	local var_18_1 = false
	local var_18_2 = arg_18_3 or false

	for iter_18_0, iter_18_1 in pairs(arg_18_0.list_) do
		if iter_18_1.itemID == arg_18_1 then
			iter_18_1.itemNum = iter_18_1.itemNum + arg_18_2

			if iter_18_1.itemNum <= 0 then
				table.remove(arg_18_0.list_, iter_18_0)

				return
			end

			if iter_18_1.itemNum > xyd.tables.item:stack(arg_18_1) then
				var_18_1 = true
				iter_18_1.itemNum = xyd.tables.item:stack(arg_18_1)
			end

			if var_18_1 and not var_18_2 and xyd.tables.item:stackMail(arg_18_1) == 1 and not xyd.WindowManager.get():getWindow("toast") then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ITEM_EXCEED_TIP")
				})
			end

			return
		end
	end

	if var_18_0.itemNum < 1 or not var_18_0.itemType then
		return
	end

	table.insert(arg_18_0.list_, var_18_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):checkEquipableAndSummon()
end

function var_0_0.isHasEnergyItem(arg_19_0)
	local var_19_0 = arg_19_0:getItems()

	for iter_19_0, iter_19_1 in ipairs(var_19_0) do
		if xyd.tables.item:subType(iter_19_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

function var_0_0.setSpiritItem(arg_20_0, arg_20_1, arg_20_2)
	if arg_20_0.spiritList_[arg_20_1] then
		if arg_20_2.item then
			arg_20_0.spiritList_[arg_20_1] = arg_20_2.item

			return
		end

		if arg_20_2.is_equip then
			arg_20_0.spiritList_[arg_20_1].is_equip = arg_20_2.is_equip
		end

		if arg_20_2.is_lock then
			arg_20_0.spiritList_[arg_20_1].is_lock = arg_20_2.is_lock
		end
	end
end

function var_0_0.addSpiritColloCount(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_0.spiritList_[arg_21_1] then
		if not arg_21_0.spiritList_[arg_21_1].collo_count then
			arg_21_0.spiritList_[arg_21_1].collo_count = 0
		end

		arg_21_0.spiritList_[arg_21_1].collo_count = arg_21_0.spiritList_[arg_21_1].collo_count + arg_21_2
	end
end

return var_0_0
