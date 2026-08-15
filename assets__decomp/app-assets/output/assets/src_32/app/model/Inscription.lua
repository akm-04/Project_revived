local var_0_0 = class("Inscription", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.inscriptionSuit

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.make(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_MAKE, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.rebuild(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_REBUILD, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.insert(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_INSERT, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			local var_8_0 = {
				itemID = var_7_0.item_id
			}

			var_8_0.itemNum = 1

			arg_7_0.selfPlayer:getBackpack():removeItem(var_8_0)

			if var_7_0.replace_item_id then
				arg_7_0.selfPlayer:getBackpack():addItemsByID(var_7_0.replace_item_id, 1)
			end
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.remove(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_REMOVE, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.selfPlayer:getBackpack():addItemsByID(var_9_0.item_id, 1)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.resolve(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_RESOLVE, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = {
				itemID = var_11_0.item_id,
				itemNum = var_11_0.resolve_num
			}

			arg_11_0.selfPlayer:getBackpack():removeItem(var_12_0)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.saveRedo(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_SAVE_REBUILD, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.abandonRedo(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.INSCRIPTION_ABANDON_REBUILD, var_15_0, function(arg_16_0, arg_16_1)
		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.exchangeMaterials(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.EXCHANGE_MATERIALS, var_17_0, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.handleExchangeMaterials(arg_19_0)
	local var_19_0 = {}
	local var_19_1 = xyd.tables.misc.inscriptCostItems

	for iter_19_0 = 1, #var_19_1 do
		if arg_19_0.selfPlayer:getBackpack():getItemNumByID(var_19_1[iter_19_0]) > 0 then
			table.insert(var_19_0, arg_19_0.selfPlayer:getBackpack():getItemByID(var_19_1[iter_19_0]))
		end
	end

	if #var_19_0 > 0 then
		arg_19_0:exchangeMaterials({}, function(arg_20_0, arg_20_1)
			if arg_20_0 == xyd.error.OK and arg_20_1.currency_change then
				for iter_20_0 = 1, #var_19_0 do
					arg_19_0.selfPlayer:getBackpack():removeItem(var_19_0[iter_20_0])
				end

				local var_20_0 = xyd.WindowManager.get():getWindow("backpack")

				if var_20_0 then
					var_20_0:refreshDisplayOptionAfterSell()
				end

				local var_20_1 = {
					currency_change = arg_20_1.currency_change
				}

				xyd.WindowManager.get():openWindow("exchange_material", var_20_1)
			end
		end)
	end
end

function var_0_0.setInscriptionInfo(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	xyd.setItemBorder(arg_21_1:getChildByName("icon_container"), arg_21_2)

	local var_21_0 = xyd.tables.item:inscriptId(arg_21_2)

	arg_21_1:getChildByName("txt_lv"):setString(xyd.tables.inscription:level(var_21_0))
	arg_21_1:getChildByName("name_txt"):setString(xyd.tables.item:name(arg_21_2))

	local var_21_1, var_21_2, var_21_3 = arg_21_0:getInscriptionAttrLabelText(arg_21_2)

	arg_21_1:getChildByName("desc_txt1"):setString(var_21_1)
	arg_21_1:getChildByName("desc_txt2"):setString("+" .. math.abs(var_21_2) .. var_21_3)
	arg_21_1:getChildByName("desc_txt2"):setPositionX(arg_21_1:getChildByName("desc_txt1"):getPositionX() + arg_21_1:getChildByName("desc_txt1"):getContentSize().width + 10)
end

function var_0_0.getRedoItemsBaseOnType(arg_22_0, arg_22_1)
	local var_22_0 = xyd.tables.inscription:getItemIDsBaseOnType(arg_22_1)
	local var_22_1 = {}

	for iter_22_0 = 1, #var_22_0 do
		local var_22_2 = xyd.tables.inscription:itemID(var_22_0[iter_22_0])

		for iter_22_1 = 1, #var_22_2 do
			if arg_22_0.selfPlayer:getBackpack():getItemNumByID(var_22_2[iter_22_1]) > 0 then
				table.insert(var_22_1, 1, arg_22_0.selfPlayer:getBackpack():getItemByID(var_22_2[iter_22_1]))
			end
		end
	end

	table.sort(var_22_1, function(arg_23_0, arg_23_1)
		local var_23_0 = xyd.tables.item:inscriptId(arg_23_0.itemID)
		local var_23_1 = xyd.tables.item:inscriptId(arg_23_1.itemID)

		levA = xyd.tables.inscription:level(var_23_0)
		levB = xyd.tables.inscription:level(var_23_1)

		if levA ~= levB then
			return levA > levB
		end

		return arg_23_0.itemTime > arg_23_1.itemTime
	end)

	return var_22_1
end

function var_0_0.getRedoItemsBaseOnLev(arg_24_0, arg_24_1)
	local var_24_0 = xyd.tables.inscription:getItemIDsBaseOnLevel(arg_24_1)
	local var_24_1 = {}

	for iter_24_0 = 1, #var_24_0 do
		local var_24_2 = xyd.tables.inscription:itemID(var_24_0[iter_24_0])

		for iter_24_1 = 1, #var_24_2 do
			if arg_24_0.selfPlayer:getBackpack():getItemNumByID(var_24_2[iter_24_1]) > 0 then
				table.insert(var_24_1, var_24_2[iter_24_1])
			end
		end
	end

	return var_24_1
end

function var_0_0.getInscriptionItemsBaseOnTypeAndLevel(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = xyd.tables.inscription:getItemsByPosAndLevel(arg_25_1, arg_25_2)
	local var_25_1 = {}

	for iter_25_0 = 1, #var_25_0 do
		if arg_25_0.selfPlayer:getBackpack():getItemNumByID(var_25_0[iter_25_0]) > 0 and var_25_0[iter_25_0] ~= arg_25_3:getInscriptItem(arg_25_1) then
			table.insert(var_25_1, arg_25_0.selfPlayer:getBackpack():getItemByID(var_25_0[iter_25_0]))
		end
	end

	local var_25_2 = arg_25_0:getSuitInfo(arg_25_3)

	table.sort(var_25_1, function(arg_26_0, arg_26_1)
		for iter_26_0, iter_26_1 in pairs(var_25_2) do
			if iter_26_1 then
				-- block empty
			elseif not iter_26_1 and xyd.tableHaveElement(xyd.tables.inscriptionSuit:itemID(iter_26_0), arg_26_0.itemID) then
				return true
			elseif not iter_26_1 and xyd.tableHaveElement(xyd.tables.inscriptionSuit:itemID(iter_26_0), arg_26_1.itemID) then
				return false
			end
		end

		if xyd.tables.item:inscriptSuitId(arg_26_0.itemID) > 0 and xyd.tables.item:inscriptSuitId(arg_26_1.itemID) == 0 then
			return true
		elseif xyd.tables.item:inscriptSuitId(arg_26_1.itemID) > 0 and xyd.tables.item:inscriptSuitId(arg_26_0.itemID) == 0 then
			return false
		else
			return arg_26_0.itemTime > arg_26_1.itemTime
		end
	end)

	return var_25_1
end

function var_0_0.getInscriptionAttrLabelText(arg_27_0, arg_27_1)
	local var_27_0 = xyd.tables.item:attrs(arg_27_1)

	for iter_27_0, iter_27_1 in pairs(var_27_0) do
		local var_27_1 = xyd.tables.attr:suffix(iter_27_0)

		if var_27_1 ~= "%" then
			var_27_1 = ""
		end

		if xyd.tables.attr:isPercent(iter_27_0) then
			iter_27_1 = math.floor(iter_27_1 * 100)
		end

		return xyd.tables.attr:name(iter_27_0), math.abs(iter_27_1), var_27_1
	end

	return "", 0
end

function var_0_0.getInscriptionSuitAttrLabelText(arg_28_0, arg_28_1)
	local var_28_0 = var_0_2:attrs(arg_28_1)

	for iter_28_0, iter_28_1 in pairs(var_28_0) do
		local var_28_1 = xyd.tables.attr:suffix(iter_28_0)

		if var_28_1 ~= "%" then
			var_28_1 = ""
		end

		if xyd.tables.attr:isPercent(iter_28_0) then
			iter_28_1 = math.floor(iter_28_1 * 100)
		end

		return xyd.tables.attr:name(iter_28_0), math.abs(iter_28_1), var_28_1
	end

	return "", 0
end

function var_0_0.setTransparentBorder(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = xyd.tables.item:transparentIcon(arg_29_2)
	local var_29_1 = xyd.SpriteLoader.new(var_29_0, nil, nil, xyd.DefaultImageType.INSCRIPTION)
	local var_29_2 = arg_29_1:getContentSize().width
	local var_29_3 = arg_29_1:getContentSize().height

	var_29_1:setScale(0.5)
	var_29_1:addTo(arg_29_1)
	var_29_1:setPosition(cc.p(var_29_2 / 2, var_29_3 / 2))
end

function var_0_0.levelName(arg_30_0, arg_30_1)
	return xyd.split(var_0_1:translation("INSCRIPTION_BUTTON_LEVEL_NAME"), ",")[arg_30_1]
end

function var_0_0.getMaterialIcon(arg_31_0, arg_31_1)
	local var_31_0
	local var_31_1 = arg_31_1 == 19 and "images/icon/eco/erudition_star.png" or arg_31_1 == 20 and "images/icon/eco/model_star.png" or arg_31_1 == 21 and "images/icon/eco/green_star.png" or xyd.tables.item:transparentIcon(arg_31_1)
	local var_31_2 = xyd.AssetLoader:get():loadSprite(var_31_1)

	var_31_2:setScale(0.85)

	if arg_31_1 > 100000 and var_31_2:getContentSize().width > 54 then
		var_31_2:setScale(54 / var_31_2:getContentSize().width)
	end

	return var_31_2
end

function var_0_0.getMaterialNumByID(arg_32_0, arg_32_1)
	local var_32_0 = 0

	if arg_32_1 == 19 then
		var_32_0 = arg_32_0.selfPlayer.degreeCer
	elseif arg_32_1 == 20 then
		var_32_0 = arg_32_0.selfPlayer.graduateCer
	elseif arg_32_1 == 21 then
		var_32_0 = arg_32_0.selfPlayer.patentCer
	end

	return var_32_0
end

function var_0_0.getCurrentInscriptionType(arg_33_0)
	if arg_33_0.currentInscriptionType then
		return arg_33_0.currentInscriptionType
	else
		return nil
	end
end

function var_0_0.setCurrentInscriptionType(arg_34_0, arg_34_1)
	arg_34_0.currentInscriptionType = arg_34_1
end

function var_0_0.getSuitInfo(arg_35_0, arg_35_1)
	local var_35_0 = arg_35_1:getInscriptItems()
	local var_35_1 = var_0_2:ids()
	local var_35_2 = {}

	for iter_35_0, iter_35_1 in ipairs(var_35_0) do
		for iter_35_2, iter_35_3 in ipairs(var_35_1) do
			if xyd.tableHaveElement(var_0_2:itemID(iter_35_3), iter_35_1) then
				local var_35_3 = true

				for iter_35_4, iter_35_5 in ipairs(var_0_2:itemID(iter_35_3)) do
					if not xyd.tableHaveElement(var_35_0, iter_35_5) then
						var_35_3 = false
					end
				end

				var_35_2[iter_35_3] = var_35_3
			end
		end
	end

	return var_35_2
end

return var_0_0
