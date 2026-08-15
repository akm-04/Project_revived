local var_0_0 = class("HunqiCombEditorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spiritSuit
local var_0_3 = xyd.tables.spirit
local var_0_4 = xyd.tables.spiritEquip
local var_0_5 = xyd.tables.attr
local var_0_6 = xyd.tables.misc
local var_0_7 = 4
local var_0_8 = 110
local var_0_9 = {
	67,
	149,
	231,
	313,
	395,
	477
}
local var_0_10 = var_0_6:getValue("spirit_program_limit")
local var_0_11 = {
	xyd.AttributeType.HP,
	xyd.AttributeType.BAOJI_RATE,
	xyd.AttributeType.AD,
	xyd.AttributeType.BAOJIHARM,
	xyd.AttributeType.AP,
	xyd.AttributeType.ZHUANGTAI_MINGZHONG,
	xyd.AttributeType.HUJIA,
	xyd.AttributeType.ZHUANGTAI_KANGXING,
	xyd.AttributeType.MOKANG,
	xyd.AttributeType.HUNQI_HP_BONUS,
	xyd.AttributeType.HUNQI_AD_AP_BONUS,
	xyd.AttributeType.HUNQI_JIAKANG_BONUS
}
local var_0_12 = {
	[xyd.AttributeType.HP] = var_0_1:translation("HUNQI_TEXT_55"),
	[xyd.AttributeType.BAOJI_RATE] = var_0_1:translation("HUNQI_TEXT_56"),
	[xyd.AttributeType.AD] = var_0_1:translation("HUNQI_TEXT_57"),
	[xyd.AttributeType.BAOJIHARM] = var_0_1:translation("HUNQI_TEXT_58"),
	[xyd.AttributeType.AP] = var_0_1:translation("HUNQI_TEXT_59"),
	[xyd.AttributeType.ZHUANGTAI_MINGZHONG] = var_0_1:translation("HUNQI_TEXT_60"),
	[xyd.AttributeType.HUJIA] = var_0_1:translation("HUNQI_TEXT_61"),
	[xyd.AttributeType.ZHUANGTAI_KANGXING] = var_0_1:translation("HUNQI_TEXT_62"),
	[xyd.AttributeType.MOKANG] = var_0_1:translation("HUNQI_TEXT_63")
}
local var_0_13 = {
	var_0_1:translation("HUNQI_TEXT_21"),
	var_0_1:translation("HUNQI_TEXT_22"),
	var_0_1:translation("HUNQI_TEXT_23"),
	var_0_5:name(xyd.AttributeType.HP),
	var_0_5:name(xyd.AttributeType.AD),
	var_0_5:name(xyd.AttributeType.AP),
	var_0_5:name(xyd.AttributeType.HUJIA),
	var_0_5:name(xyd.AttributeType.MOKANG),
	var_0_5:name(xyd.AttributeType.BAOJI_RATE),
	var_0_5:name(xyd.AttributeType.BAOJIHARM),
	var_0_5:name(xyd.AttributeType.ZHUANGTAI_KANGXING),
	var_0_5:name(xyd.AttributeType.ZHUANGTAI_MINGZHONG),
	var_0_5:name(xyd.AttributeType.HUNQI_HP_BONUS),
	var_0_5:name(xyd.AttributeType.HUNQI_AD_AP_BONUS),
	var_0_5:name(xyd.AttributeType.HUNQI_JIAKANG_BONUS)
}
local var_0_14 = {
	TWO = 2,
	ONE = 1
}
local var_0_15 = {
	AD = 5,
	HUJIA = 7,
	HP = 4,
	LEV = 1,
	ZHUANGTAI_KANGXING = 11,
	AP = 6,
	BAOJIHARM = 10,
	BAOJI_RATE = 9,
	HUNQI_HP_BONUS = 13,
	QUALITY = 2,
	MOKANG = 8,
	ZHUANGTAI_MINGZHONG = 12,
	GET_TIME = 3,
	HUNQI_JIAKANG_BONUS = 15,
	HUNQI_AD_AP_BONUS = 14
}
local var_0_16 = {
	CHOOSE_TYPE = 1,
	POS = 2,
	TYPE = 3
}
local var_0_17 = {
	EQUIP = 1,
	UNEQUIP = 2
}
local var_0_18 = {
	NOW_EQUIP = 2,
	COMB_LIST = 1
}
local var_0_19 = 15

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.showType = var_0_16.POS
	arg_1_0.typeState = nil
	arg_1_0.posState = 1
	arg_1_0.selectIndex = nil
	arg_1_0.selectNode = nil
	arg_1_0.itemShow = var_0_14.ONE
	arg_1_0.sortTypeType = var_0_15.LEV
	arg_1_0.sortTypePos = var_0_15.LEV
	arg_1_0.blockTextNum = {}
	arg_1_0.longBlockTextNum = {}
	arg_1_0.equips = clone(arg_1_2.equips) or {
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.text = arg_1_2.name
	arg_1_0.data = arg_1_2.data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initUnequipItem()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.listItemType = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list_item_type"):getContentSize().width + 10, arg_4_0:nodeByName("list_item_type"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_item_type")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listItemType:setDelegate(handler(arg_4_0, arg_4_0.itemTypeDelegate))

	arg_4_0.listItemPos = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list_item_pos"):getContentSize().width + 10, arg_4_0:nodeByName("list_item_pos"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_item_pos")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listItemPos:setDelegate(handler(arg_4_0, arg_4_0.itemPosDelegate))

	arg_4_0.listTypeBlock = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list_type_block"):getContentSize().width + 10, arg_4_0:nodeByName("list_type_block"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_type_block")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:refreshTypeBlockList()

	arg_4_0.listTypeLongBlock = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list_type_long_block"):getContentSize().width + 10, arg_4_0:nodeByName("list_type_long_block"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list_type_long_block")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0:refreshTypeLongBlockList()
	arg_4_0:initEditBox()
	arg_4_0:setBtns()
	arg_4_0:setText()
	arg_4_0:updateItemNode()
	arg_4_0:updateList()
end

function var_0_0.setText(arg_5_0)
	for iter_5_0 = 1, 6 do
		arg_5_0:nodeByName("txt_pos_" .. iter_5_0):setString(var_0_1:translation("NUM_" .. iter_5_0))
	end

	arg_5_0:nodeByName("txt_type"):setString(var_0_1:translation("HUNQI_TEXT_1"))
	arg_5_0:nodeByName("txt_pos"):setString(var_0_1:translation("HUNQI_TEXT_2"))
	arg_5_0:nodeByName("txt_save"):setString(var_0_1:translation("HUNQI_TEXT_68"))
end

function var_0_0.setBtns(arg_6_0)
	for iter_6_0 = 1, 6 do
		local var_6_0 = display.newNode()

		var_6_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_0:setContentSize(68, 53)
		var_6_0:setTouchEnabled(true)
		var_6_0:setTouchSwallowEnabled(true)
		var_6_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "ended" and arg_6_0.posState ~= iter_6_0 then
				xyd.playButtonSound()

				arg_6_0.posState = iter_6_0

				arg_6_0:updateList()
			end

			return true
		end)
		var_6_0:addTo(arg_6_0:nodeByName("line_pos"))
		var_6_0:setPosition(arg_6_0:nodeByName("pos_" .. iter_6_0 .. "_an"):getPosition())

		local var_6_1 = display.newNode()

		var_6_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_1:setContentSize(110, 110)
		var_6_1:setTouchEnabled(true)
		var_6_1:setTouchSwallowEnabled(true)
		var_6_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "ended" then
				xyd.playButtonSound()

				if arg_6_0.showType == var_0_16.POS then
					if arg_6_0.posState ~= iter_6_0 then
						arg_6_0.posState = iter_6_0

						arg_6_0:updateList()
					end
				elseif arg_6_0.showType == var_0_16.CHOOSE_TYPE then
					if arg_6_0.posState ~= iter_6_0 then
						arg_6_0.posState = iter_6_0
					else
						arg_6_0.posState = nil
					end

					arg_6_0:updateShow()
					arg_6_0:updateBlockShowNum()
				elseif arg_6_0.showType == var_0_16.TYPE then
					if arg_6_0.posState ~= iter_6_0 then
						arg_6_0.posState = iter_6_0

						arg_6_0:updateList()
					else
						arg_6_0.posState = nil
						arg_6_0.selectIndex = nil
						arg_6_0.selectItem = nil

						arg_6_0:updateList()
					end
				end

				local var_8_0 = arg_6_0.equips

				if var_8_0[iter_6_0] ~= 0 then
					arg_6_0:performWithDelay(function()
						local var_9_0 = arg_6_0.backpack:getSpiritItemBySpiritID(var_8_0[iter_6_0])
						local var_9_1 = {
							rightBtnType = var_0_17.UNEQUIP
						}

						var_9_1.showActive = true

						local var_9_2 = {
							hideLockBtn = true,
							item1 = var_9_0,
							itemParams1 = var_9_1,
							equips = arg_6_0.equips
						}
						local var_9_3 = xyd.WindowManager.get():openWindow("hunqi_detail", var_9_2)

						if iter_6_0 < 4 then
							var_9_3:setPosition(940, xyd.STAGE_HEIGHT - var_9_3:getTipHeight() - 80)
						else
							var_9_3:setPosition(620, xyd.STAGE_HEIGHT - var_9_3:getTipHeight() - 80)
						end
					end, 0.03333333333333333)
				end
			end

			return true
		end)
		var_6_1:addTo(arg_6_0:nodeByName("node_item_" .. iter_6_0))
	end

	arg_6_0:nodeByName("btn_choose_type"):setTouchEnabled(true)
	arg_6_0:nodeByName("btn_choose_type"):setTouchSwallowEnabled(true)
	arg_6_0:nodeByName("btn_choose_type"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()

			if arg_6_0.showType == var_0_16.TYPE then
				arg_6_0.showType = var_0_16.CHOOSE_TYPE
				arg_6_0.selectIndex = nil
				arg_6_0.selectItem = nil

				arg_6_0:updateShow()
			end
		end
	end)
	arg_6_0:nodeByName("btn_type_desc"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = {
				itemParams1 = {
					isSuit = true,
					suitID = arg_6_0.typeState
				}
			}

			var_11_0.hideLockBtn = true

			local var_11_1 = xyd.WindowManager.get():openWindow("hunqi_detail", var_11_0)

			var_11_1:setPosition(330, xyd.STAGE_HEIGHT - var_11_1:getTipHeight() - 100)
		end
	end)
	xyd.nodeEventSample(arg_6_0:nodeByName("btn_sort"), {
		scale = 1
	}, function()
		xyd.playButtonSound()

		local var_12_0 = {}

		table.insert(var_12_0, var_0_15.LEV)
		table.insert(var_12_0, var_0_15.QUALITY)
		table.insert(var_12_0, var_0_15.GET_TIME)
		table.insert(var_12_0, var_0_15.HP)
		table.insert(var_12_0, var_0_15.AD)
		table.insert(var_12_0, var_0_15.AP)
		table.insert(var_12_0, var_0_15.HUJIA)
		table.insert(var_12_0, var_0_15.MOKANG)
		table.insert(var_12_0, var_0_15.BAOJI_RATE)
		table.insert(var_12_0, var_0_15.BAOJIHARM)
		table.insert(var_12_0, var_0_15.ZHUANGTAI_KANGXING)
		table.insert(var_12_0, var_0_15.ZHUANGTAI_MINGZHONG)
		table.insert(var_12_0, var_0_15.HUNQI_HP_BONUS)
		table.insert(var_12_0, var_0_15.HUNQI_AD_AP_BONUS)
		table.insert(var_12_0, var_0_15.HUNQI_JIAKANG_BONUS)

		local var_12_1 = {
			colNum = 2,
			types = var_12_0,
			callback = handler(arg_6_0, arg_6_0.sortList)
		}
		local var_12_2 = xyd.WindowManager.get():openWindow("hunqi_sort_type", var_12_1)

		var_12_2:setPosition(400, 570 - var_12_2:getTipHeight())
	end)
	arg_6_0:nodeByName("btn_type"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_6_0.showType = var_0_16.CHOOSE_TYPE
			arg_6_0.posState = nil
			arg_6_0.selectIndex = nil
			arg_6_0.selectItem = nil

			arg_6_0:updateShow()
			arg_6_0:updateBlockShowNum()
		end
	end)
	arg_6_0:nodeByName("btn_pos"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_6_0.showType = var_0_16.POS
			arg_6_0.posState = 1

			arg_6_0:updateList()
		end
	end)
	arg_6_0:nodeByName("btn_block"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_6_0.itemShow = var_0_14.TWO

			arg_6_0:updateShow()
		end
	end)
	arg_6_0:nodeByName("btn_long_block"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_6_0.itemShow = var_0_14.ONE

			arg_6_0:updateShow()
		end
	end)
	arg_6_0:nodeByName("btn_save"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_17_0 = 0

			for iter_17_0, iter_17_1 in ipairs(arg_6_0.data) do
				if iter_17_1.type_ == var_0_18.COMB_LIST then
					var_17_0 = var_17_0 + 1
				end
			end

			if var_17_0 >= var_0_10 then
				local var_17_1 = var_0_1:translation("HUNQI_TEXT_64")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_1
				})

				return
			end

			local var_17_2 = table.concat(arg_6_0.equips, "|")

			if var_17_2 == "0|0|0|0|0|0" then
				local var_17_3 = var_0_1:translation("HUNQI_TEXT_69")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_3
				})

				return
			end

			if not arg_6_0.text or arg_6_0.text == "" then
				local var_17_4 = var_0_1:translation("HUNQI_TEXT_70")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_4
				})

				return
			end

			local var_17_5 = true

			for iter_17_2, iter_17_3 in ipairs(arg_6_0.data) do
				if (not arg_6_0.idx or arg_6_0.idx ~= iter_17_2) and iter_17_3.name and arg_6_0.text == iter_17_3.name then
					var_17_5 = false

					break
				end
			end

			if not var_17_5 then
				local var_17_6 = var_0_1:translation("HUNQI_TEXT_71")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_6
				})

				return
			end

			local var_17_7 = {
				name = arg_6_0.text,
				collocation = var_17_2
			}

			if arg_6_0.idx then
				var_17_7.id = arg_6_0.data[arg_6_0.idx].id
			end

			xyd.Backend.get():request(xyd.mid.HUNQI_SAVE_COLLOCATION, var_17_7, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					for iter_18_0, iter_18_1 in ipairs(arg_6_0.equips) do
						if iter_18_1 > 0 then
							arg_6_0.backpack:addSpiritColloCount(iter_18_1, 1)
						end
					end

					arg_6_0.callback(arg_6_0.equips, arg_6_0.text, arg_18_1.id)
					arg_6_0:close()
				end
			end)
		end
	end)
end

function var_0_0.initEditBox(arg_19_0)
	arg_19_0.textInput = arg_19_0:nodeByName("txt_input")

	arg_19_0.textInput:setString(arg_19_0.text or var_0_1:translation("HUNQI_TEXT_70"))

	local var_19_0 = arg_19_0:nodeByName("input"):getContentSize()
	local var_19_1 = "windows/login/transparent.png"

	arg_19_0.editBox = ccui.EditBox:create(cc.size(var_19_0.width - 16, var_19_0.height - 8), var_19_1)

	arg_19_0:nodeByName("input"):addChild(arg_19_0.editBox)
	arg_19_0.editBox:setAnchorPoint(cc.p(0.5, 0.5))
	arg_19_0.editBox:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_19_0.editBox:registerScriptEditBoxHandler(handler(arg_19_0, arg_19_0.inputContentbox))
	arg_19_0.editBox:setInputFlag(3)
	arg_19_0.editBox:setMaxLength(10)
end

function var_0_0.inputContentbox(arg_20_0, arg_20_1)
	if arg_20_1 == "began" then
		if not arg_20_0.text or arg_20_0.text == "" then
			arg_20_0.textInput:setString("")
		else
			arg_20_0.editBox:setText(arg_20_0.textInput:getString())
		end
	elseif arg_20_1 == "return" then
		local var_20_0 = arg_20_0.editBox:getText()

		if var_20_0 == "" then
			arg_20_0.text = ""

			arg_20_0.textInput:setString(var_0_1:translation("HUNQI_TEXT_70"))
		else
			if xyd.utf8len(var_20_0) > 10 then
				var_20_0 = xyd.utf8str(var_20_0, 1, 10)
			end

			arg_20_0.text = var_20_0

			arg_20_0.textInput:setString(var_20_0)
			arg_20_0.editBox:setText("")
		end
	end
end

function var_0_0.initUnequipItem(arg_21_0)
	arg_21_0.items_ = {}
	arg_21_0.typeAllItems_ = {}
	arg_21_0.posAllItems_ = {}

	for iter_21_0 = 1, 6 do
		arg_21_0.posAllItems_[iter_21_0] = {}
	end

	for iter_21_1, iter_21_2 in pairs(arg_21_0.backpack:getSpiritItems()) do
		table.insert(arg_21_0.items_, iter_21_2)
	end

	for iter_21_3, iter_21_4 in ipairs(arg_21_0.items_) do
		local var_21_0 = iter_21_4.table_id
		local var_21_1 = var_0_4:modelId(var_21_0)
		local var_21_2 = var_0_3:pos(var_21_1)
		local var_21_3 = var_0_4:from(var_21_0)

		if not arg_21_0.typeAllItems_[var_21_3] then
			arg_21_0.typeAllItems_[var_21_3] = {}

			for iter_21_5 = 1, 6 do
				arg_21_0.typeAllItems_[var_21_3][iter_21_5] = {}
			end
		end

		table.insert(arg_21_0.typeAllItems_[var_21_3][var_21_2], iter_21_4)
	end

	for iter_21_6, iter_21_7 in ipairs(arg_21_0.items_) do
		local var_21_4 = iter_21_7.table_id
		local var_21_5 = var_0_4:modelId(var_21_4)
		local var_21_6 = var_0_3:pos(var_21_5)

		table.insert(arg_21_0.posAllItems_[var_21_6], iter_21_7)
	end
end

function var_0_0.updateItemNode(arg_22_0)
	local var_22_0 = arg_22_0.equips

	for iter_22_0 = 1, 6 do
		local var_22_1 = arg_22_0:nodeByName("node_item_" .. iter_22_0)

		if var_22_1:getChildByName("item") then
			var_22_1:removeChildByName("item")
		end

		if var_22_0[iter_22_0] and var_22_0[iter_22_0] ~= 0 then
			local var_22_2 = display.newNode()

			var_22_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_22_2:setContentSize(xyd.HunqiDefualtSize, xyd.HunqiDefualtSize)

			local var_22_3 = {
				noBorder = true,
				levShowTop = true,
				container = var_22_2,
				item = arg_22_0.backpack:getSpiritItemBySpiritID(var_22_0[iter_22_0])
			}

			xyd.setHunqiBorder(var_22_3)
			var_22_2:addTo(var_22_1)
			var_22_2:setName("item")
		end
	end

	local var_22_4 = {}

	for iter_22_1, iter_22_2 in ipairs(var_0_11) do
		var_22_4[iter_22_1] = {
			attrNum = 0,
			attrType = iter_22_2
		}

		if xyd.tables.attr:isPercent(iter_22_2) then
			var_22_4[iter_22_1].isP = true
		end

		for iter_22_3, iter_22_4 in ipairs(var_22_0) do
			if iter_22_4 ~= 0 then
				local var_22_5 = arg_22_0.backpack:getSpiritItemBySpiritID(iter_22_4)
				local var_22_6 = var_22_5.table_id
				local var_22_7 = var_0_4:from(var_22_6)
				local var_22_8 = var_0_4:modelId(var_22_6)

				if var_0_3:main(var_22_8, var_22_5.main) == iter_22_2 then
					var_22_4[iter_22_1].attrNum = var_22_4[iter_22_1].attrNum + var_22_5.main_attr_value
				end

				if var_22_5.sub then
					for iter_22_5 = 1, #var_22_5.sub do
						local var_22_9 = var_22_5.sub[iter_22_5]

						if var_0_3:sub(var_22_8, var_22_9) == iter_22_2 then
							var_22_4[iter_22_1].attrNum = var_22_4[iter_22_1].attrNum + var_22_5.sub_attr_value[iter_22_5]
						end
					end
				end
			end
		end
	end

	local var_22_10 = arg_22_0:getSpiritSuitID(var_22_0)

	for iter_22_6, iter_22_7 in ipairs(var_22_10) do
		local var_22_11 = var_0_2:attr2(iter_22_7)
		local var_22_12 = var_0_2:attr2Value(iter_22_7)

		for iter_22_8, iter_22_9 in ipairs(var_22_4) do
			if iter_22_9.attrType == var_22_11 then
				iter_22_9.attrNum = iter_22_9.attrNum + var_22_12
			end
		end
	end

	arg_22_0.bonusAttr = {}

	for iter_22_10 = #var_22_4, 1, -1 do
		local var_22_13 = var_22_4[iter_22_10]

		if var_22_13.attrType == xyd.AttributeType.HUNQI_HP_BONUS then
			arg_22_0.bonusAttr[xyd.AttributeType.HP] = var_22_13.attrNum

			table.remove(var_22_4, iter_22_10)
		elseif var_22_13.attrType == xyd.AttributeType.HUNQI_AD_AP_BONUS then
			arg_22_0.bonusAttr[xyd.AttributeType.AD] = var_22_13.attrNum
			arg_22_0.bonusAttr[xyd.AttributeType.AP] = var_22_13.attrNum

			table.remove(var_22_4, iter_22_10)
		elseif var_22_13.attrType == xyd.AttributeType.HUNQI_JIAKANG_BONUS then
			arg_22_0.bonusAttr[xyd.AttributeType.HUJIA] = var_22_13.attrNum
			arg_22_0.bonusAttr[xyd.AttributeType.MOKANG] = var_22_13.attrNum

			table.remove(var_22_4, iter_22_10)
		end
	end

	arg_22_0:nodeByName("attr_container"):removeAllChildren()

	local var_22_14 = arg_22_0:nodeByName("attr_container"):getHeight()

	for iter_22_11 = 1, math.ceil(#var_22_4 / 2) do
		local var_22_15 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/comb_editor_attr.csb")

		for iter_22_12 = 1, 2 do
			local var_22_16 = var_22_4[(iter_22_11 - 1) * 2 + iter_22_12]

			if not var_22_16 then
				var_22_15:getChildByName("txt_attr_name_" .. iter_22_12):setVisible(false)
				var_22_15:getChildByName("txt_attr_num_now_" .. iter_22_12):setVisible(false)

				break
			end

			local var_22_17

			if var_22_16.isP then
				var_22_17 = var_22_16.attrNum / xyd.DECIMAL_BASE * 100

				if var_22_17 < 10 and var_22_17 > 0 then
					var_22_17 = string.format("%.2f", var_22_17)
				else
					var_22_17 = string.format("%.f", var_22_17)
				end

				var_22_17 = var_22_17 .. "%"
			elseif arg_22_0.bonusAttr[var_22_16.attrType] then
				local var_22_18 = 1 + arg_22_0.bonusAttr[var_22_16.attrType] / xyd.DECIMAL_BASE

				var_22_17 = var_22_16.attrNum * var_22_18

				if var_22_17 < 10 and var_22_17 > 0 then
					var_22_17 = string.format("%.2f", var_22_17)
				else
					var_22_17 = string.format("%.f", var_22_17)
				end
			else
				var_22_17 = var_22_16.attrNum

				if var_22_17 < 10 and var_22_17 > 0 then
					var_22_17 = string.format("%.2f", var_22_17)
				else
					var_22_17 = string.format("%.f", var_22_17)
				end
			end

			var_22_15:getChildByName("txt_attr_name_" .. iter_22_12):setString(var_0_12[var_22_16.attrType])
			var_22_15:getChildByName("txt_attr_num_now_" .. iter_22_12):setString(var_22_17)
		end

		var_22_15:addTo(arg_22_0:nodeByName("attr_container"))
		var_22_15:setPosition(0, var_22_14 - iter_22_11 * 27)
	end
end

function var_0_0.updateList(arg_23_0)
	if arg_23_0.showType == var_0_16.TYPE then
		arg_23_0:updateTypeList()
	elseif arg_23_0.showType == var_0_16.POS then
		arg_23_0:updatePosList()
	end

	arg_23_0:updateShow()
end

function var_0_0.updateTypeList(arg_24_0)
	arg_24_0.typeItems_ = {}

	local var_24_0 = arg_24_0.typeState

	if not arg_24_0.posState then
		local var_24_1 = arg_24_0.typeAllItems_[var_24_0]

		if var_24_1 and next(var_24_1) then
			for iter_24_0, iter_24_1 in ipairs(var_24_1) do
				if iter_24_1 and next(iter_24_1) then
					for iter_24_2, iter_24_3 in ipairs(iter_24_1) do
						table.insert(arg_24_0.typeItems_, iter_24_3)
					end
				end
			end
		end
	else
		arg_24_0.typeItems_ = arg_24_0.typeAllItems_[var_24_0][arg_24_0.posState]
	end

	arg_24_0:sortItems(arg_24_0.typeItems_, arg_24_0.sortTypeType)
	arg_24_0.listItemType:reload()
end

function var_0_0.updatePosList(arg_25_0)
	arg_25_0.posItems_ = arg_25_0.posAllItems_[arg_25_0.posState]
	arg_25_0.selectIndex = nil
	arg_25_0.selectItem = nil

	arg_25_0:sortItems(arg_25_0.posItems_, arg_25_0.sortTypePos)
	arg_25_0.listItemPos:reload()
end

function var_0_0.sortItems(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = {}

	table.insert(var_26_0, arg_26_2)

	for iter_26_0 = 1, var_0_19 do
		if arg_26_2 ~= iter_26_0 then
			table.insert(var_26_0, iter_26_0)
		end
	end

	local function var_26_1(arg_27_0, arg_27_1)
		if not arg_27_0 and not arg_27_1 then
			return 3
		elseif arg_27_0 and not arg_27_1 then
			return 1
		elseif not arg_27_0 and arg_27_1 then
			return 2
		elseif arg_27_1 < arg_27_0 then
			return 1
		elseif arg_27_0 < arg_27_1 then
			return 2
		else
			return 3
		end
	end

	local function var_26_2(arg_28_0, arg_28_1, arg_28_2)
		if arg_28_2 == var_0_15.LEV then
			return var_26_1(arg_28_0.lev, arg_28_1.lev)
		elseif arg_28_2 == var_0_15.QUALITY then
			return var_26_1(arg_28_0.star, arg_28_1.star)
		elseif arg_28_2 == var_0_15.GET_TIME then
			return var_26_1(arg_28_0.spirit_id, arg_28_1.spirit_id)
		else
			local var_28_0

			if arg_28_2 == var_0_15.HP then
				var_28_0 = xyd.AttributeType.HP
			elseif arg_28_2 == var_0_15.AD then
				var_28_0 = xyd.AttributeType.AD
			elseif arg_28_2 == var_0_15.AP then
				var_28_0 = xyd.AttributeType.AP
			elseif arg_28_2 == var_0_15.HUJIA then
				var_28_0 = xyd.AttributeType.HUJIA
			elseif arg_28_2 == var_0_15.MOKANG then
				var_28_0 = xyd.AttributeType.MOKANG
			elseif arg_28_2 == var_0_15.BAOJI_RATE then
				var_28_0 = xyd.AttributeType.BAOJI_RATE
			elseif arg_28_2 == var_0_15.BAOJIHARM then
				var_28_0 = xyd.AttributeType.BAOJIHARM
			elseif arg_28_2 == var_0_15.ZHUANGTAI_KANGXING then
				var_28_0 = xyd.AttributeType.ZHUANGTAI_KANGXING
			elseif arg_28_2 == var_0_15.ZHUANGTAI_MINGZHONG then
				var_28_0 = xyd.AttributeType.ZHUANGTAI_MINGZHONG
			elseif arg_28_2 == var_0_15.HUNQI_HP_BONUS then
				var_28_0 = xyd.AttributeType.HUNQI_HP_BONUS
			elseif arg_28_2 == var_0_15.HUNQI_AD_AP_BONUS then
				var_28_0 = xyd.AttributeType.HUNQI_AD_AP_BONUS
			elseif arg_28_2 == var_0_15.HUNQI_JIAKANG_BONUS then
				var_28_0 = xyd.AttributeType.HUNQI_JIAKANG_BONUS
			end

			local var_28_1
			local var_28_2
			local var_28_3 = arg_28_0.main_attr ~= var_28_0 and 0 or arg_28_0.main_attr_value
			local var_28_4 = arg_28_1.main_attr ~= var_28_0 and 0 or arg_28_0.main_attr_value

			return var_26_1(var_28_3, var_28_4)
		end
	end

	table.sort(arg_26_1, function(arg_29_0, arg_29_1)
		for iter_29_0, iter_29_1 in ipairs(var_26_0) do
			local var_29_0 = var_26_2(arg_29_0, arg_29_1, iter_29_1)

			if var_29_0 == 1 then
				return true
			elseif var_29_0 == 2 then
				return false
			end
		end

		return false
	end)
end

function var_0_0.updateShow(arg_30_0)
	arg_30_0:nodeByName("pos_container"):setVisible(false)
	arg_30_0:nodeByName("type_container"):setVisible(false)
	arg_30_0:nodeByName("btn_type"):setVisible(false)
	arg_30_0:nodeByName("btn_pos"):setVisible(false)
	arg_30_0:nodeByName("btn_block"):setVisible(false)
	arg_30_0:nodeByName("btn_long_block"):setVisible(false)
	arg_30_0:nodeByName("btn_sort"):setVisible(false)
	arg_30_0:nodeByName("btn_choose_type"):setVisible(false)
	arg_30_0:nodeByName("btn_type_desc"):setVisible(false)
	arg_30_0.listItemType:setVisible(false)
	arg_30_0.listItemPos:setVisible(false)
	arg_30_0.listTypeBlock:setVisible(false)
	arg_30_0.listTypeLongBlock:setVisible(false)
	arg_30_0:setSelectEquipNode(arg_30_0.posState)

	if arg_30_0.showType == var_0_16.CHOOSE_TYPE then
		arg_30_0:nodeByName("type_container"):setVisible(true)
		arg_30_0:nodeByName("btn_type"):setVisible(true)
		arg_30_0:nodeByName("btn_pos"):setVisible(true)

		if arg_30_0.itemShow == var_0_14.ONE then
			arg_30_0:nodeByName("btn_block"):setVisible(true)
			arg_30_0.listTypeLongBlock:setVisible(true)
		else
			arg_30_0:nodeByName("btn_long_block"):setVisible(true)
			arg_30_0.listTypeBlock:setVisible(true)
		end

		arg_30_0:nodeByName("btn_type"):setEnabled(false)
		arg_30_0:nodeByName("btn_pos"):setEnabled(true)
	elseif arg_30_0.showType == var_0_16.POS then
		arg_30_0:nodeByName("pos_container"):setVisible(true)
		arg_30_0:nodeByName("btn_type"):setVisible(true)
		arg_30_0:nodeByName("btn_pos"):setVisible(true)
		arg_30_0:nodeByName("btn_sort"):setVisible(true)
		arg_30_0:nodeByName("btn_type"):setEnabled(true)
		arg_30_0:nodeByName("btn_pos"):setEnabled(false)
		arg_30_0.listItemPos:setVisible(true)

		for iter_30_0 = 1, 6 do
			arg_30_0:nodeByName("btn_choose"):getChildByName("pos_" .. iter_30_0):setVisible(false)
		end

		arg_30_0:nodeByName("btn_choose"):setPositionX(var_0_9[arg_30_0.posState])
		arg_30_0:nodeByName("btn_choose"):getChildByName("pos_" .. arg_30_0.posState):setVisible(true)
		arg_30_0:nodeByName("txt_choose"):setString(var_0_1:translation("NUM_" .. arg_30_0.posState))
		arg_30_0:nodeByName("txt_sort"):setString(var_0_13[arg_30_0.sortTypePos])

		local var_30_0 = xyd.getTextLen(var_0_13[arg_30_0.sortTypePos])

		if var_30_0 > 4 then
			arg_30_0:nodeByName("txt_sort"):setFontSize(math.floor(24 / var_30_0 * 4))
		else
			arg_30_0:nodeByName("txt_sort"):setFontSize(20)
		end
	elseif arg_30_0.showType == var_0_16.TYPE then
		arg_30_0:nodeByName("type_container"):setVisible(true)
		arg_30_0:nodeByName("btn_choose_type"):setVisible(true)
		arg_30_0:nodeByName("btn_type_desc"):setVisible(true)
		arg_30_0:nodeByName("btn_sort"):setVisible(true)
		arg_30_0.listItemType:setVisible(true)
		arg_30_0:nodeByName("txt_choose_type"):setString(var_0_2:name(arg_30_0.typeState))
		arg_30_0:nodeByName("txt_sort"):setString(var_0_13[arg_30_0.sortTypeType])

		local var_30_1 = xyd.getTextLen(var_0_13[arg_30_0.sortTypeType])

		if var_30_1 > 4 then
			arg_30_0:nodeByName("txt_sort"):setFontSize(math.floor(22 / var_30_1 * 4))
		else
			arg_30_0:nodeByName("txt_sort"):setFontSize(20)
		end
	end
end

function var_0_0.setSelectEquipNode(arg_31_0, arg_31_1)
	for iter_31_0 = 1, 6 do
		arg_31_0:nodeByName("node_item_" .. iter_31_0):getChildByName("choose"):setVisible(false)
	end

	if arg_31_1 then
		arg_31_0:nodeByName("node_item_" .. arg_31_1):getChildByName("choose"):setVisible(true)
	end
end

function var_0_0.getSpiritSuitID(arg_32_0, arg_32_1)
	local var_32_0 = {}
	local var_32_1 = 0
	local var_32_2 = {}

	for iter_32_0, iter_32_1 in ipairs(arg_32_1) do
		if iter_32_1 ~= 0 then
			local var_32_3 = arg_32_0.backpack:getSpiritItemBySpiritID(iter_32_1)
			local var_32_4 = xyd.tables.spiritEquip:from(var_32_3.table_id)

			if not var_32_2[var_32_4] then
				var_32_2[var_32_4] = 1
			else
				var_32_2[var_32_4] = var_32_2[var_32_4] + 1
			end
		end
	end

	for iter_32_2, iter_32_3 in pairs(var_32_2) do
		if iter_32_3 >= 2 then
			table.insert(var_32_0, iter_32_2)
		end

		if iter_32_3 >= 4 then
			var_32_1 = iter_32_2
		end
	end

	return var_32_0, var_32_1
end

function var_0_0.itemTypeDelegate(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	local var_33_0 = math.ceil(#arg_33_0.typeItems_ / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_33_2 then
		return var_33_0
	elseif cc.ui.UIListView.CELL_TAG == arg_33_2 then
		if var_33_0 < arg_33_3 then
			return nil
		end

		local var_33_1 = arg_33_0.listItemType:dequeueItem()

		if not var_33_1 then
			var_33_1 = arg_33_0.listItemType:newItem()
		else
			var_33_1:removeAllChildren(true)
		end

		local var_33_2 = display.newNode()

		arg_33_0:initCell(var_33_2, arg_33_3, var_0_16.TYPE)

		local var_33_3 = display.newNode()

		var_33_3:addChild(var_33_2)
		var_33_3:setContentSize(var_33_2:getContentSize())
		var_33_1:setItemSize(var_33_2:getContentSize().width, var_33_2:getContentSize().height)
		var_33_1:addContent(var_33_3)

		return var_33_1
	end
end

function var_0_0.itemPosDelegate(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	local var_34_0 = math.ceil(#arg_34_0.posItems_ / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_34_2 then
		return var_34_0
	elseif cc.ui.UIListView.CELL_TAG == arg_34_2 then
		if var_34_0 < arg_34_3 then
			return nil
		end

		local var_34_1 = arg_34_0.listItemPos:dequeueItem()

		if not var_34_1 then
			var_34_1 = arg_34_0.listItemPos:newItem()
		else
			var_34_1:removeAllChildren(true)
		end

		local var_34_2 = display.newNode()

		arg_34_0:initCell(var_34_2, arg_34_3, var_0_16.POS)

		local var_34_3 = display.newNode()

		var_34_3:addChild(var_34_2)
		var_34_3:setContentSize(var_34_2:getContentSize())
		var_34_1:setItemSize(var_34_2:getContentSize().width, var_34_2:getContentSize().height)
		var_34_1:addContent(var_34_3)

		return var_34_1
	end
end

function var_0_0.initCell(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	for iter_35_0 = 1, var_0_7 do
		local var_35_0 = (arg_35_2 - 1) * var_0_7 + iter_35_0
		local var_35_1

		if arg_35_3 == var_0_16.TYPE then
			var_35_1 = arg_35_0.typeItems_
		elseif arg_35_3 == var_0_16.POS then
			var_35_1 = arg_35_0.posItems_
		end

		if var_35_0 > #var_35_1 then
			break
		end

		local var_35_2 = var_35_1[var_35_0]
		local var_35_3 = display.newNode()

		var_35_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_35_3:setContentSize(var_0_8, var_0_8)

		local var_35_4 = {
			container = var_35_3,
			item = var_35_2
		}

		xyd.setHunqiBorder(var_35_4)

		if var_35_2.is_equip > 0 then
			local var_35_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/comb_mask.csb")

			var_35_5:getChildByName("txt_equip"):setString(var_0_1:translation("HUNQI_TEXT_77"))
			var_35_5:getChildByName("txt_equip"):enableOutline(cc.c4b(89, 101, 173, 255), 2)
			var_35_3:addChild(var_35_5)
		end

		var_35_3:setTouchEnabled(true)
		var_35_3:setTouchSwallowEnabled(false)
		var_35_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
			if arg_36_0.name == "began" then
				var_35_3:setScale(0.9)
			elseif arg_36_0.name == "moved" then
				if not arg_35_0.scrollViewMoved_ then
					var_35_3:setScale(1)
				end
			elseif arg_36_0.name == "ended" then
				var_35_3:setScale(1)

				if not arg_35_0.scrollViewMoved_ then
					xyd.playButtonSound()

					if arg_35_0.selectNode and not tolua.isnull(arg_35_0.selectNode) then
						arg_35_0.selectNode:removeChildByName("selected")
					end

					local var_36_0 = xyd.AssetLoader.get():loadSprite("windows/hunqi/selected.png")

					var_36_0:addTo(var_35_3, 1)
					var_36_0:setPosition(var_0_8 / 2, var_0_8 / 2)
					var_36_0:setName("selected")

					arg_35_0.selectIndex = var_35_0
					arg_35_0.selectNode = var_35_3

					arg_35_0:performWithDelay(function()
						local var_37_0 = {
							item1 = var_35_2,
							equips = arg_35_0.equips
						}

						var_37_0.hideLockBtn = true
						var_37_0.itemParams1 = {
							rightBtnType = var_0_17.EQUIP,
							relateIcon = var_35_3
						}

						local var_37_1 = xyd.tables.spiritEquip:modelId(var_35_2.table_id)
						local var_37_2 = xyd.tables.spirit:pos(var_37_1)
						local var_37_3 = arg_35_0.equips[var_37_2]

						if var_37_3 ~= 0 then
							var_37_0.item2 = arg_35_0.backpack:getSpiritItemBySpiritID(var_37_3)

							local var_37_4 = {}

							var_37_4.showActive = true
							var_37_0.itemParams2 = var_37_4
						end

						local var_37_5 = xyd.WindowManager.get():openWindow("hunqi_detail", var_37_0)

						var_37_5:setPosition(610, xyd.STAGE_HEIGHT - var_37_5:getTipHeight() - 100)
					end, 0.03333333333333333)
				end
			end

			return true
		end)

		if arg_35_0.selectIndex == var_35_0 then
			arg_35_0.selectNode = var_35_3

			local var_35_6 = xyd.AssetLoader.get():loadSprite("windows/hunqi/selected.png")

			var_35_6:addTo(var_35_3)
			var_35_6:setPosition(var_0_8 / 2, var_0_8 / 2)
			var_35_6:setName("selected")
		end

		var_35_3:addTo(arg_35_1)
		var_35_3:setPosition((iter_35_0 - 1) * (var_0_8 + 20) + var_0_8 / 2, 16 + var_0_8 / 2)
	end

	arg_35_1:setContentSize(arg_35_0:nodeByName("list_item_pos"):getWidth() + 10, var_0_8 + 16)
end

function var_0_0.onSelectSpirit(arg_38_0, arg_38_1, arg_38_2)
	arg_38_0.equips[arg_38_1] = arg_38_2

	arg_38_0:updateItemNode()
end

function var_0_0.refreshTypeBlockList(arg_39_0)
	arg_39_0.blockTextNum = {}

	arg_39_0.listTypeBlock:removeAllItems()

	local var_39_0 = table.nums(arg_39_0.typeAllItems_)
	local var_39_1 = table.keys(arg_39_0.typeAllItems_)
	local var_39_2 = math.ceil(var_39_0 / 2)

	for iter_39_0 = 1, var_39_2 do
		local var_39_3 = display.newNode()
		local var_39_4 = 500
		local var_39_5 = 127

		var_39_3:setContentSize(var_39_4, var_39_5)

		local var_39_6 = arg_39_0.listTypeBlock:newItem()

		for iter_39_1 = 1, 2 do
			local var_39_7 = (iter_39_0 - 1) * 2 + iter_39_1

			if var_39_0 < var_39_7 then
				break
			end

			local var_39_8 = var_39_1[var_39_7]
			local var_39_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/block.csb")
			local var_39_10 = var_39_9:getChildByName("container")
			local var_39_11 = xyd.SpriteLoader.new("images/hunqi/icon/" .. var_39_8 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

			xyd.displaySpriteOnContainer(var_39_11, var_39_10:getChildByName("icon"), false)
			var_39_10:getChildByName("name"):setString(var_0_2:name(var_39_8))
			var_39_10:getChildByName("desc"):setString(xyd.tables.attr:name(var_0_2:attr2(var_39_8)))
			var_39_10:getChildByName("text_num"):enableOutline(cc.c4b(155, 71, 97, 255), 2)

			local var_39_12 = 0

			if arg_39_0.posState then
				var_39_12 = #arg_39_0.typeAllItems_[var_39_8][arg_39_0.posState]
			else
				for iter_39_2 = 1, 6 do
					var_39_12 = var_39_12 + #arg_39_0.typeAllItems_[var_39_8][iter_39_2]
				end
			end

			var_39_10:getChildByName("text_num"):setString(var_39_12)
			table.insert(arg_39_0.blockTextNum, var_39_10:getChildByName("text_num"))
			var_39_9:addTo(var_39_3)
			var_39_9:setAnchorPoint(cc.p(0, 0))
			var_39_9:setPosition((iter_39_1 - 1) * 255 + 2, 2)
			var_39_9:setTouchEnabled(true)
			var_39_9:setTouchSwallowEnabled(false)
			var_39_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_40_0)
				if arg_40_0.name == "began" then
					var_39_10:setScale(0.9)
				elseif arg_40_0.name == "moved" then
					if not arg_39_0.scrollViewMoved_ then
						var_39_10:setScale(1)
					end
				elseif arg_40_0.name == "ended" then
					var_39_10:setScale(1)

					if not arg_39_0.scrollViewMoved_ then
						xyd.playButtonSound()

						arg_39_0.showType = var_0_16.TYPE
						arg_39_0.typeState = var_39_8

						arg_39_0:updateList()
					end
				end

				return true
			end)
		end

		var_39_6:addContent(var_39_3)
		var_39_6:setItemSize(var_39_4, var_39_5)
		arg_39_0.listTypeBlock:addItem(var_39_6)
	end

	arg_39_0.listTypeBlock:reload()
end

function var_0_0.refreshTypeLongBlockList(arg_41_0)
	arg_41_0.longBlockTextNum = {}

	arg_41_0.listTypeLongBlock:removeAllItems()

	local var_41_0 = table.nums(arg_41_0.typeAllItems_)
	local var_41_1 = table.keys(arg_41_0.typeAllItems_)

	for iter_41_0 = 1, var_41_0 do
		local var_41_2 = var_41_1[iter_41_0]
		local var_41_3 = display.newNode()
		local var_41_4 = arg_41_0.listTypeLongBlock:newItem()
		local var_41_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/block_long.csb")
		local var_41_6 = var_41_5:getChildByName("container")
		local var_41_7 = xyd.SpriteLoader.new("images/hunqi/icon/" .. var_41_2 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

		xyd.displaySpriteOnContainer(var_41_7, var_41_6:getChildByName("icon"), false)
		var_41_6:getChildByName("name"):enableOutline(cc.c4b(61, 61, 61, 255), 2)
		var_41_6:getChildByName("name"):setString(var_0_2:name(var_41_2))
		var_41_6:getChildByName("text_num"):enableOutline(cc.c4b(155, 71, 97, 255), 2)

		local var_41_8 = 0

		if arg_41_0.posState then
			var_41_8 = #arg_41_0.typeAllItems_[var_41_2][arg_41_0.posState]
		else
			for iter_41_1 = 1, 6 do
				var_41_8 = var_41_8 + #arg_41_0.typeAllItems_[var_41_2][iter_41_1]
			end
		end

		var_41_6:getChildByName("text_num"):setString(var_41_8)
		table.insert(arg_41_0.longBlockTextNum, var_41_6:getChildByName("text_num"))

		local var_41_9 = {
			size = 16,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c4b(106, 105, 119, 255),
			dimensions = cc.size(320, 0)
		}
		local var_41_10 = xyd.AssetLoader.get():loadLabel(var_41_9)
		local var_41_11, var_41_12 = var_0_2:attr2Value(var_41_2)

		if var_41_12 then
			var_41_11 = var_41_11 / 100 .. "%"
		end

		var_41_10:setString(xyd.tables.attr:name(var_0_2:attr2(var_41_2)) .. var_41_11)
		var_41_10:setAnchorPoint(cc.p(0, 1))
		var_41_10:addTo(var_41_6:getChildByName("node_word"))
		var_41_10:setPositionY(10)

		local var_41_13 = {
			size = 16,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c4b(106, 105, 119, 255),
			dimensions = cc.size(320, 0)
		}
		local var_41_14 = xyd.AssetLoader.get():loadLabel(var_41_13)

		var_41_14:setString(var_0_2:attr4Desc(var_41_2))
		var_41_14:setAnchorPoint(cc.p(0, 1))
		var_41_14:addTo(var_41_6:getChildByName("node_word"))
		var_41_14:setPositionY(-16)
		var_41_5:addTo(var_41_3)
		var_41_5:setAnchorPoint(cc.p(0, 0))
		var_41_5:setPosition(0, 5)
		var_41_5:setTouchEnabled(true)
		var_41_5:setTouchSwallowEnabled(false)
		var_41_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
			if arg_42_0.name == "began" then
				var_41_6:setScale(0.9)
			elseif arg_42_0.name == "moved" then
				if not arg_41_0.scrollViewMoved_ then
					var_41_6:setScale(1)
				end
			elseif arg_42_0.name == "ended" then
				var_41_6:setScale(1)

				if not arg_41_0.scrollViewMoved_ then
					xyd.playButtonSound()

					arg_41_0.showType = var_0_16.TYPE
					arg_41_0.typeState = var_41_2

					arg_41_0:updateList()
				end
			end

			return true
		end)
		var_41_3:setContentSize(var_41_6:getWidth(), var_41_6:getHeight())
		var_41_4:addContent(var_41_3)
		var_41_4:setItemSize(var_41_6:getWidth(), var_41_6:getHeight() + 5)
		arg_41_0.listTypeLongBlock:addItem(var_41_4)
	end

	arg_41_0.listTypeLongBlock:reload()
end

function var_0_0.scrollListener(arg_43_0, arg_43_1)
	if arg_43_1.name == "began" then
		arg_43_0.scrollViewMoved_ = false
		arg_43_0.prevY_ = arg_43_1.y
	elseif arg_43_1.name == "moved" and 20 <= math.abs(arg_43_1.y - arg_43_0.prevY_) then
		arg_43_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateBlockShowNum(arg_44_0)
	local var_44_0 = table.keys(arg_44_0.typeAllItems_)

	for iter_44_0, iter_44_1 in ipairs(var_44_0) do
		local var_44_1 = 0

		if arg_44_0.posState then
			var_44_1 = #arg_44_0.typeAllItems_[iter_44_1][arg_44_0.posState]
		else
			for iter_44_2 = 1, 6 do
				var_44_1 = var_44_1 + #arg_44_0.typeAllItems_[iter_44_1][iter_44_2]
			end
		end

		arg_44_0.blockTextNum[iter_44_0]:setString(var_44_1)
		arg_44_0.longBlockTextNum[iter_44_0]:setString(var_44_1)
	end
end

function var_0_0.sortList(arg_45_0, arg_45_1)
	if arg_45_0.showType == var_0_16.POS then
		arg_45_0.sortTypePos = arg_45_1

		arg_45_0:sortItems(arg_45_0.posItems_, arg_45_0.sortTypePos)
		arg_45_0.listItemPos:reload()
		arg_45_0:updateShow()
	elseif arg_45_0.showType == var_0_16.TYPE then
		arg_45_0.sortTypeType = arg_45_1

		arg_45_0:sortItems(arg_45_0.typeItems_, arg_45_0.sortTypeType)
		arg_45_0.listItemType:reload()
		arg_45_0:updateShow()
	end
end

return var_0_0
