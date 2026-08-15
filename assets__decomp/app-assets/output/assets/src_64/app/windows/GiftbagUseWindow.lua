local var_0_0 = class("GiftbagUseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.itemID = arg_1_2.item_id
	arg_1_0.giftID = arg_1_2.gift_id
	arg_1_0.itemType = arg_1_2.item_type
	arg_1_0.itemNode = arg_1_2.item_node
	arg_1_0.partnerId = arg_1_2.partner_id
	arg_1_0.favorDegree = arg_1_2.favor_degree
	arg_1_0.heroTableID = arg_1_2.hero_table_id
	arg_1_0.hasNum = arg_1_0.selfPlayer:getBackpack():getItemNumByID(arg_1_0.itemID)

	if arg_1_0.itemType == xyd.ConsumeItemType.LOVE_ITEM then
		local var_1_0 = math.ceil((xyd.tables.misc.libraryFavorLimit - arg_1_0.favorDegree) / arg_1_0:finalAmour())

		arg_1_0.maxNum = math.min(arg_1_0.hasNum, var_1_0)
	else
		arg_1_0.maxNum = arg_1_0.hasNum
	end

	arg_1_0.currentNum = 1
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.finalAmour(arg_4_0)
	local var_4_0 = xyd.tables.item:getAmour(arg_4_0.itemID)
	local var_4_1 = xyd.tables.libraryGift:getItemLikeType(arg_4_0.itemID)

	if var_4_1 == xyd.tables.hero:giftLikeType(arg_4_0.heroTableID) then
		var_4_0 = var_4_0 + xyd.tables.misc.libraryGiftRight
	end

	if var_4_1 == xyd.tables.hero:giftDislikeType(arg_4_0.heroTableID) then
		var_4_0 = var_4_0 + xyd.tables.misc.libraryGiftWrong
	end

	return var_4_0
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("img_icon"):removeAllChildren()
	xyd.setItemBorder(arg_5_0:nodeByName("img_icon"), arg_5_0.itemID)
	arg_5_0:nodeByName("name_text"):setString(xyd.tables.item:name(arg_5_0.itemID))
	arg_5_0:nodeByName("has_txt"):setString(var_0_1:translation("ITEM_OWN"))
	arg_5_0:nodeByName("jian_txt"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_5_0:nodeByName("select_txt"):setString(var_0_1:translation("SELECT_NUM"))
	arg_5_0:nodeByName("num_txt"):setString(arg_5_0.hasNum)
	arg_5_0:nodeByName("use_num_txt"):setString(arg_5_0.currentNum .. "/" .. arg_5_0.maxNum)
	arg_5_0:nodeByName("max_txt"):setString(var_0_1:translation("MAX"))

	local var_5_0

	if arg_5_0.itemType == xyd.ConsumeItemType.ENERGY_ITEM then
		arg_5_0:nodeByName("use_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_6_0 = {
					item_id = arg_5_0.itemID,
					item_num = arg_5_0.currentNum
				}

				arg_5_0.selfPlayer:useEnergyItem(var_6_0, function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						local var_7_0 = xyd.WindowManager.get():getWindow("backpack")

						if var_7_0 and not tolua.isnull(var_7_0) then
							var_7_0:updateItems()
						end

						local var_7_1 = xyd.WindowManager.get():getWindow("equipment_backpack")

						if var_7_1 and not tolua.isnull(var_7_1) then
							var_7_1:updateItems()
						end

						xyd.WindowManager.get():closeWindow(arg_5_0.name)
					end
				end)
			end
		end)
	elseif arg_5_0.itemType == xyd.ConsumeItemType.SKILL_POINT then
		arg_5_0:nodeByName("use_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_8_0 = {
					item_id = arg_5_0.itemID,
					item_num = arg_5_0.currentNum
				}

				arg_5_0.selfPlayer:useSkillPointItem(var_8_0, function(arg_9_0)
					if arg_9_0 == xyd.error.OK then
						local var_9_0 = xyd.WindowManager.get():getWindow("backpack")

						if var_9_0 then
							var_9_0:updateItems()
						end

						xyd.WindowManager.get():closeWindow(arg_5_0.name)
					end
				end)
			end
		end)
	elseif arg_5_0.itemType == xyd.ConsumeItemType.LOVE_ITEM then
		arg_5_0:nodeByName("use_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_10_0 = {
					gift_id = arg_5_0.itemID,
					gift_num = arg_5_0.currentNum,
					partner_id = arg_5_0.partnerId
				}
				local var_10_1 = xyd.WindowManager.get():getWindow("hero_gift_box")

				if var_10_1 then
					var_10_1:addFavorOrMarried(var_10_0, arg_5_0.itemNode)
				end

				xyd.WindowManager.get():closeWindow(arg_5_0.name)
			end
		end)
	else
		arg_5_0:nodeByName("use_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_5_0:isSelectEquip() then
					local var_11_0 = {
						itemID = arg_5_0.itemID,
						num = arg_5_0.currentNum
					}
					local var_11_1 = true

					for iter_11_0, iter_11_1 in pairs(xyd.tables.item:gifts(arg_5_0.itemID)) do
						if xyd.tables.gift:items(iter_11_1)[1] == nil then
							var_11_1 = false

							print(iter_11_1 .. " has no id in gift")
						end
					end

					if var_11_1 then
						xyd.WindowManager.get():openWindow("select_equip", var_11_0)
						xyd.WindowManager.get():closeWindow(arg_5_0)
					end

					return
				end

				local var_11_2 = {
					item_id = arg_5_0.itemID,
					gift_id = arg_5_0.giftID,
					num = arg_5_0.currentNum
				}

				xyd.Backend.get():request(xyd.mid.EXCHAGE_CODE_HERO, var_11_2, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						local var_12_0 = {
							itemID = var_11_2.item_id,
							itemNum = arg_5_0.currentNum
						}

						arg_5_0.selfPlayer:getBackpack():removeItem(var_12_0)
						arg_5_0.selfPlayer:handleRewards(arg_12_1.awards, nil, arg_12_1.spirit_awards)

						local var_12_1 = xyd.WindowManager.get():getWindow("backpack")

						if var_12_1 then
							var_12_1:updateItemDetail(var_11_2.item_id)
							var_12_1:refreshDisplayOption()
						end

						xyd.WindowManager.get():closeWindow(arg_5_0.name)
					end
				end)
			end
		end)
	end

	arg_5_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)

	local var_5_1 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_5_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_1:setScale(1, 1)
	var_5_1:addTo(arg_5_0:nodeByName("decrease_button"))
	var_5_1:setName("jiandian")

	local var_5_2 = false

	var_5_1:onButtonPressed(function(arg_14_0)
		local var_14_0 = 0

		local function var_14_1()
			var_14_0 = var_14_0 + 0.03

			if arg_5_0.decreaseCurrentNum then
				arg_5_0:decreaseCurrentNum()
			end
		end

		local function var_14_2()
			var_14_0 = var_14_0 + 0.1

			if var_14_0 > 0.5 and var_14_0 <= 4 then
				var_5_2 = true

				if arg_5_0.decreaseCurrentNum then
					arg_5_0:decreaseCurrentNum()
				end
			elseif var_14_0 > 4 then
				arg_5_0.handler[2] = var_0_2.scheduleGlobal(var_14_1, 0.03)

				var_0_2.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_2 = false
			end
		end

		var_5_2 = false
		arg_5_0.handler[1] = var_0_2.scheduleGlobal(var_14_2, 0.1)
	end)
	var_5_1:onButtonRelease(function(arg_17_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_2 == false and arg_5_0.decreaseCurrentNum then
			arg_5_0:decreaseCurrentNum()
		end
	end)

	local var_5_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_5_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_3:setScale(1, 1)
	var_5_3:addTo(arg_5_0:nodeByName("increase_button"))
	var_5_3:setName("jiadian")

	local var_5_4 = false

	var_5_3:onButtonPressed(function(arg_18_0)
		local var_18_0 = 0

		local function var_18_1()
			var_18_0 = var_18_0 + 0.03

			if arg_5_0.addCurrentNum then
				arg_5_0:addCurrentNum()
			end
		end

		local function var_18_2()
			var_18_0 = var_18_0 + 0.1

			if var_18_0 > 0.5 and var_18_0 <= 4 then
				var_5_4 = true

				if arg_5_0.addCurrentNum then
					arg_5_0:addCurrentNum()
				end
			elseif var_18_0 > 4 then
				arg_5_0.handler[2] = var_0_2.scheduleGlobal(var_18_1, 0.03)

				var_0_2.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_4 = false
			end
		end

		var_5_4 = false
		arg_5_0.handler[1] = var_0_2.scheduleGlobal(var_18_2, 0.1)
	end)
	var_5_3:onButtonRelease(function(arg_21_0)
		if arg_5_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_4 == false and arg_5_0.addCurrentNum then
			arg_5_0:addCurrentNum()
		end
	end)
	arg_5_0:nodeByName("max_button"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_5_0.currentNum = arg_5_0.maxNum

			arg_5_0:updateNum()
		end
	end)
	arg_5_0:initChatBox()
end

function var_0_0.addCurrentNum(arg_23_0)
	if arg_23_0.currentNum + 1 >= arg_23_0.maxNum then
		arg_23_0.currentNum = arg_23_0.maxNum
	else
		arg_23_0.currentNum = arg_23_0.currentNum + 1
	end

	arg_23_0:nodeByName("use_num_txt"):setString(arg_23_0.currentNum .. "/" .. arg_23_0.maxNum)
	arg_23_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_24_0)
	if arg_24_0.currentNum - 1 <= 0 then
		arg_24_0.currentNum = 1
	else
		arg_24_0.currentNum = arg_24_0.currentNum - 1
	end

	arg_24_0:nodeByName("use_num_txt"):setString(arg_24_0.currentNum .. "/" .. arg_24_0.maxNum)
	arg_24_0:updateNum()
end

function var_0_0.updateNum(arg_25_0)
	arg_25_0:nodeByName("use_num_txt"):setString(arg_25_0.currentNum .. "/" .. arg_25_0.maxNum)
end

function var_0_0.didClose(arg_26_0)
	if arg_26_0.handler then
		if arg_26_0.handler[1] then
			var_0_2.unscheduleGlobal(arg_26_0.handler[1])
		end

		if arg_26_0.handler[2] then
			var_0_2.unscheduleGlobal(arg_26_0.handler[2])
		end
	end
end

function var_0_0.isSelectEquip(arg_27_0, arg_27_1)
	local var_27_0 = xyd.tables.misc.selectEquipGiftIDs

	arg_27_1 = arg_27_1 or arg_27_0.itemID

	if xyd.tableHaveElement(var_27_0, arg_27_1) then
		return true
	else
		return false
	end
end

function var_0_0.initChatBox(arg_28_0)
	local var_28_0 = xyd.AssetLoader.get()
	local var_28_1 = 24
	local var_28_2 = arg_28_0:nodeByName("num_panel")
	local var_28_3 = "windows/login/transparent.png"
	local var_28_4 = var_28_0:loadSprite(var_28_3)

	arg_28_0.chatBox_ = ccui.EditBox:create(var_28_2:getContentSize(), var_28_3)

	arg_28_0.chatBox_:setAnchorPoint(0, 0)
	arg_28_0.chatBox_:pos(0, 0):addTo(var_28_2)
	arg_28_0.chatBox_:setFont(var_28_0.FONT_NAME, var_28_1)
	arg_28_0.chatBox_:setPlaceholderFont(var_28_0.FONT_NAME, var_28_1)
	arg_28_0.chatBox_:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_28_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_28_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_28_0.chatBox_:registerScriptEditBoxHandler(handler(arg_28_0, arg_28_0.inputboxEventHandler))
	arg_28_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_29_0, arg_29_1)
	if arg_29_1 == "return" then
		local var_29_0 = arg_29_0.chatBox_:getText()

		arg_29_0.chatBox_:setText("")

		local var_29_1 = xyd.getTextLen(var_29_0)
		local var_29_2 = math.floor(tonumber(var_29_0) or 0)

		arg_29_0:nodeByName("use_num_txt"):setVisible(true)

		if var_29_0 ~= "" then
			if var_29_2 then
				if var_29_2 <= arg_29_0.maxNum and var_29_2 > 0 then
					arg_29_0.currentNum = var_29_2

					arg_29_0:updateNum()
				else
					local var_29_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_29_3
					})

					return
				end

				return
			else
				local var_29_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_29_4
				})

				return
			end
		else
			return
		end
	elseif arg_29_1 == "began" then
		arg_29_0:nodeByName("use_num_txt"):setVisible(false)
		arg_29_0.chatBox_:setText("")
	end
end

return var_0_0
