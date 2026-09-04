local var_0_0 = class("HunqiStrengthenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spirit
local var_0_3 = xyd.tables.spiritEquip
local var_0_4 = xyd.tables.spiritStrth
local var_0_5 = xyd.tables.attr
local var_0_6 = import("app.common.ui.SpriteNodeButton")
local var_0_7 = require("framework.scheduler")
local var_0_8 = {
	78,
	160,
	242,
	324,
	406,
	488
}
local var_0_9 = 4
local var_0_10 = 110
local var_0_11 = {
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
local var_0_12 = 15
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

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.item = arg_1_2.targetItem
	arg_1_0.posState = 1
	arg_1_0.selectSpiritIDs = {}
	arg_1_0.selectNodes = {}
	arg_1_0.sortType = var_0_11.LEV
	arg_1_0.exp = 0
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:initUnequipItem()
	arg_2_0:setText()
	arg_2_0:setBtns()
end

function var_0_0.initUnequipItem(arg_3_0)
	arg_3_0.items_ = arg_3_0.backpack:getSpiritItems()
	arg_3_0.unequipItem_ = {}
	arg_3_0.posItems_ = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.items_) do
		if iter_3_1.is_equip == 0 and (not iter_3_1.collo_count or iter_3_1.collo_count == 0) and iter_3_1 ~= arg_3_0.item then
			table.insert(arg_3_0.unequipItem_, iter_3_1)
		end
	end

	arg_3_0:updateList()
end

function var_0_0.updateList(arg_4_0)
	arg_4_0.posItems_ = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.unequipItem_) do
		local var_4_0 = iter_4_1.table_id
		local var_4_1 = var_0_3:modelId(var_4_0)

		if var_0_2:pos(var_4_1) == arg_4_0.posState then
			table.insert(arg_4_0.posItems_, iter_4_1)
		end
	end

	arg_4_0.selectIndex = nil
	arg_4_0.selectItem = nil

	arg_4_0:sortItems(arg_4_0.posItems_, arg_4_0.sortType)
	arg_4_0.listItemPos:reload()
end

function var_0_0.didOpen(arg_5_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.HUNQI_SORT, handler(arg_5_0, arg_5_0.sortList))
end

function var_0_0.sortList(arg_6_0, arg_6_1)
	arg_6_0.sortType = arg_6_1.type_

	arg_6_0:sortItems(arg_6_0.posItems_, arg_6_0.sortType)
	arg_6_0.listItemPos:reload()
end

function var_0_0.sortItems(arg_7_0, arg_7_1, arg_7_2)
	arg_7_0:nodeByName("text_sort"):setString(var_0_13[arg_7_2])

	local var_7_0 = {}

	table.insert(var_7_0, arg_7_2)

	for iter_7_0 = 1, var_0_12 do
		if arg_7_2 ~= iter_7_0 then
			table.insert(var_7_0, iter_7_0)
		end
	end

	local function var_7_1(arg_8_0, arg_8_1)
		if not arg_8_0 and not arg_8_1 then
			return 3
		elseif arg_8_0 and not arg_8_1 then
			return 1
		elseif not arg_8_0 and arg_8_1 then
			return 2
		elseif arg_8_1 < arg_8_0 then
			return 1
		elseif arg_8_0 < arg_8_1 then
			return 2
		else
			return 3
		end
	end

	local function var_7_2(arg_9_0, arg_9_1, arg_9_2)
		if arg_9_2 == var_0_11.LEV then
			return var_7_1(arg_9_0.lev, arg_9_1.lev)
		elseif arg_9_2 == var_0_11.QUALITY then
			return var_7_1(arg_9_0.star, arg_9_1.star)
		elseif arg_9_2 == var_0_11.GET_TIME then
			return var_7_1(arg_9_0.spirit_id, arg_9_1.spirit_id)
		else
			local var_9_0

			if arg_9_2 == var_0_11.HP then
				var_9_0 = xyd.AttributeType.HP
			elseif arg_9_2 == var_0_11.AD then
				var_9_0 = xyd.AttributeType.AD
			elseif arg_9_2 == var_0_11.AP then
				var_9_0 = xyd.AttributeType.AP
			elseif arg_9_2 == var_0_11.HUJIA then
				var_9_0 = xyd.AttributeType.HUJIA
			elseif arg_9_2 == var_0_11.MOKANG then
				var_9_0 = xyd.AttributeType.MOKANG
			elseif arg_9_2 == var_0_11.BAOJI_RATE then
				var_9_0 = xyd.AttributeType.BAOJI_RATE
			elseif arg_9_2 == var_0_11.BAOJIHARM then
				var_9_0 = xyd.AttributeType.BAOJIHARM
			elseif arg_9_2 == var_0_11.ZHUANGTAI_KANGXING then
				var_9_0 = xyd.AttributeType.ZHUANGTAI_KANGXING
			elseif arg_9_2 == var_0_11.ZHUANGTAI_MINGZHONG then
				var_9_0 = xyd.AttributeType.ZHUANGTAI_MINGZHONG
			elseif arg_9_2 == var_0_11.HUNQI_HP_BONUS then
				var_9_0 = xyd.AttributeType.HUNQI_HP_BONUS
			elseif arg_9_2 == var_0_11.HUNQI_AD_AP_BONUS then
				var_9_0 = xyd.AttributeType.HUNQI_AD_AP_BONUS
			elseif arg_9_2 == var_0_11.HUNQI_JIAKANG_BONUS then
				var_9_0 = xyd.AttributeType.HUNQI_JIAKANG_BONUS
			end

			local var_9_1
			local var_9_2
			local var_9_3 = arg_9_0.main_attr ~= var_9_0 and 0 or arg_9_0.main_attr_value
			local var_9_4 = arg_9_1.main_attr ~= var_9_0 and 0 or arg_9_0.main_attr_value

			return var_7_1(var_9_3, var_9_4)
		end
	end

	table.sort(arg_7_1, function(arg_10_0, arg_10_1)
		local var_10_0 = arg_10_0.table_id
		local var_10_1 = xyd.tables.spiritEquip:from(var_10_0)
		local var_10_2 = arg_10_1.table_id
		local var_10_3 = xyd.tables.spiritEquip:from(var_10_2)

		if var_10_1 == xyd.HunqiExpSuitID and var_10_3 ~= xyd.HunqiExpSuitID then
			return true
		elseif var_10_1 ~= xyd.HunqiExpSuitID and var_10_3 == xyd.HunqiExpSuitID then
			return false
		end

		for iter_10_0, iter_10_1 in ipairs(var_7_0) do
			local var_10_4 = var_7_2(arg_10_0, arg_10_1, iter_10_1)

			if var_10_4 == 1 then
				return true
			elseif var_10_4 == 2 then
				return false
			end
		end

		return false
	end)
end

function var_0_0.setText(arg_11_0)
	for iter_11_0 = 1, 6 do
		arg_11_0:nodeByName("text_pos_" .. iter_11_0):setString(var_0_1:translation("NUM_" .. iter_11_0))
	end

	arg_11_0:nodeByName("text_title"):setString(var_0_1:translation("HUNQI_TEXT_20"))
	arg_11_0:nodeByName("text_num"):setString(string.format(var_0_1:translation("HUNQI_TEXT_3"), arg_11_0.backpack:getSpiritNum(), xyd.tables.misc:getValue("spirit_num_limit")))
	arg_11_0:nodeByName("text_sthrengthen_desc"):setString(var_0_1:translation("HUNQI_TEXT_9"))
	arg_11_0:nodeByName("text_cost"):setString(var_0_1:translation("HUNQI_TEXT_10"))
	arg_11_0:nodeByName("text_sthrengthen"):setString(var_0_1:translation("HUNQI_TEXT_5"))
	arg_11_0:nodeByName("text_strengthen_level"):setString(var_0_1:translation("HUNQI_TEXT_8"))
	arg_11_0:nodeByName("text_num"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
	arg_11_0:nodeByName("text_strengthen_level"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
	arg_11_0:nodeByName("text_cost"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
	arg_11_0:nodeByName("cost"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
end

function var_0_0.setBtns(arg_12_0)
	local var_12_0 = var_0_6.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_12_0:addTo(arg_12_0)
	var_12_0:setAnchorPoint(0.5, 0.5)
	var_12_0:setPosition(44, 697)
	var_12_0:setName("return_btn")

	arg_12_0.returnBtn = var_12_0

	arg_12_0.returnBtn:addTouchEvent(function(arg_13_0)
		if arg_13_0.name == "ended" then
			xyd.playCloseSound()
			xyd.WindowManager.get():closeWindow(arg_12_0)
		end
	end)
	arg_12_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_14_0 = {}

			var_14_0.title_name = "SPIRIT_RULE_TITLE"
			var_14_0.rule = "SPIRIT_RULE_TEXT"
			var_14_0.style = xyd.RuleStyle.YELLOW

			xyd.WindowManager.get():openWindow("new_text_rule", var_14_0)
		end
	end)
	arg_12_0:nodeByName("btn_strengthen"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if #arg_12_0.selectSpiritIDs == 0 then
				return
			end

			if arg_12_0.exp * xyd.tables.misc:getValue("spirit_strth_gold_rate") > arg_12_0.selfPlayer.mana then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)

				local function var_15_0()
					local var_16_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_12_0.selfPlayer:isFuncOpen(var_16_0) then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_16_1 = xyd.tables.functionOpen:level(var_16_0)
						local var_16_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_16_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_16_2
						})
					end
				end

				local var_15_1 = {
					rcallBefore = 0,
					txt = var_0_1:translation("JINBI_ABSENCE"),
					rcallback = var_15_0
				}

				xyd.WindowManager.get():openWindow("common_alert", var_15_1)

				return
			end

			local var_15_2 = var_0_1:translation("HUNQI_TEXT_48")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_2, function()
				local var_17_0 = {
					spirit_id = arg_12_0.item.spirit_id,
					spirit_ids = arg_12_0.selectSpiritIDs
				}

				xyd.Backend.get():request(xyd.mid.HUNQI_ENHANCE, var_17_0, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						local var_18_0 = clone(arg_12_0.item)

						arg_12_0.backpack:removeSpiritItems(arg_12_0.selectSpiritIDs)
						arg_12_0.backpack:setSpiritItem(arg_12_0.item.spirit_id, {
							item = arg_18_1
						})
						arg_12_0:nodeByName("text_num"):setString(string.format(var_0_1:translation("HUNQI_TEXT_3"), arg_12_0.backpack:getSpiritNum(), xyd.tables.misc:getValue("spirit_num_limit")))

						arg_12_0.selectSpiritIDs = {}
						arg_12_0.selectNodes = {}
						arg_12_0.item = arg_18_1
						arg_12_0.exp = 0

						arg_12_0:initAttr()
						arg_12_0:updateExpShow()
						arg_12_0:initUnequipItem()

						local var_18_1 = xyd.WindowManager.get():getWindow("hunqi")

						if var_18_1 then
							var_18_1:updateAllItems()
						end

						if arg_12_0.item.lev > var_18_0.lev then
							xyd.WindowManager.get():openWindow("hunqi_strengthen_result", {
								oldItem = var_18_0,
								newItem = arg_12_0.item
							})
						end
					end
				end)
			end, nil, 0, xyd.ColorMode.BLUE)
		end
	end)
	arg_12_0:nodeByName("btn_sort"):setTouchEnabled(true)
	arg_12_0:nodeByName("btn_sort"):setTouchSwallowEnabled(true)
	arg_12_0:nodeByName("btn_sort"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = {}

			table.insert(var_19_0, var_0_11.LEV)
			table.insert(var_19_0, var_0_11.QUALITY)
			table.insert(var_19_0, var_0_11.GET_TIME)

			local var_19_1 = {
				colNum = 1,
				types = var_19_0
			}
			local var_19_2 = xyd.WindowManager.get():openWindow("hunqi_sort_type", var_19_1)

			var_19_2:setPosition(427, 570 - var_19_2:getTipHeight())
		end
	end)

	for iter_12_0 = 1, 6 do
		local var_12_1 = display.newNode()

		var_12_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_12_1:setContentSize(68, 53)
		var_12_1:setTouchEnabled(true)
		var_12_1:setTouchSwallowEnabled(true)
		var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "ended" and arg_12_0.posState ~= iter_12_0 then
				xyd.playButtonSound()

				arg_12_0.posState = iter_12_0

				arg_12_0:updateShow()
				arg_12_0:updateList()
			end

			return true
		end)
		var_12_1:addTo(arg_12_0:nodeByName("line_pos"))
		var_12_1:setPosition(arg_12_0:nodeByName("pos_" .. iter_12_0 .. "_an"):getPosition())
	end
end

function var_0_0.layout(arg_21_0)
	local var_21_0 = {
		colorMode = xyd.ColorMode.BLUE,
		notShowParams = {
			[xyd.EconomicType.ENERGY] = true
		}
	}
	local var_21_1 = import("app.common.ui.EcoSidebar").new(xyd.WidgetName.ecoSidebar, var_21_0)

	var_21_1:addTo(arg_21_0:nodeByName("background"))
	var_21_1:setAnchorPoint(0, 0)
	var_21_1:setPosition(556, 674)
	var_21_1:setName("eco_sidebar")

	arg_21_0.children_.eco_sidebar = var_21_1
	arg_21_0.listItemPos = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_21_0:nodeByName("list_item_pos"):getContentSize().width + 20, arg_21_0:nodeByName("list_item_pos"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_21_0:nodeByName("list_item_pos")):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	arg_21_0.listItemPos:setDelegate(handler(arg_21_0, arg_21_0.itemPosDelegate))

	local var_21_2 = var_0_3:from(arg_21_0.item.table_id)

	xyd.SpriteLoader.new("images/hunqi/icon/" .. var_21_2 .. "_big.png", nil, nil, xyd.DefaultImageType.QUESTION_MARK):addTo(arg_21_0:nodeByName("node_icon"))
	arg_21_0:updateShow()
	arg_21_0:initAttr()
	arg_21_0:updateExpShow()
end

function var_0_0.updateShow(arg_22_0)
	for iter_22_0 = 1, 6 do
		arg_22_0:nodeByName("btn_choose"):getChildByName("pos_" .. iter_22_0):setVisible(false)
	end

	arg_22_0:nodeByName("btn_choose"):setPositionX(var_0_8[arg_22_0.posState])
	arg_22_0:nodeByName("btn_choose"):getChildByName("pos_" .. arg_22_0.posState):setVisible(true)
	arg_22_0:nodeByName("text_choose"):setString(var_0_1:translation("NUM_" .. arg_22_0.posState))
end

function var_0_0.updateExpShow(arg_23_0)
	arg_23_0:nodeByName("level_1"):setString(arg_23_0.item.lev)
	arg_23_0:nodeByName("node_progress"):removeAllChildren()
	arg_23_0:nodeByName("cost"):setString(var_0_1:translation("COLON") .. arg_23_0.exp * xyd.tables.misc:getValue("spirit_strth_gold_rate"))

	local var_23_0, var_23_1 = var_0_4:currentLevAndExp(arg_23_0.item.star, arg_23_0.item.exp)
	local var_23_2 = (var_23_1 + arg_23_0.exp) / var_0_4:exp(arg_23_0.item.star, arg_23_0.item.lev + 1)

	if var_23_2 >= 1 then
		var_23_2 = 1
	end

	arg_23_0:nodeByName("progress"):setPercent(var_23_2 * 100)
	arg_23_0:nodeByName("text_sthrengthen_desc"):setVisible(false)

	if arg_23_0.exp == 0 then
		local var_23_3 = var_23_1 .. "/" .. var_0_4:exp(arg_23_0.item.star, arg_23_0.item.lev + 1)
		local var_23_4 = xyd.createMultiColorTxt(var_23_3, cc.c3b(255, 255, 255), 16, nil, cc.c4b(59, 59, 94, 255))

		var_23_4:setAnchorPoint(cc.p(0.5, 0, 5))
		var_23_4:addTo(arg_23_0:nodeByName("node_progress"))
		var_23_4:setPositionY(-10)
		arg_23_0:nodeByName("arrow3"):setVisible(false)
		arg_23_0:nodeByName("level_2"):setString("")
		arg_23_0.mainAttrItem:getChildByName("arrow3"):setVisible(false)
		arg_23_0.mainAttrItem:getChildByName("new_attr"):setString("")
	else
		local var_23_5 = var_0_4:currentLevAndExp(arg_23_0.item.star, arg_23_0.item.exp + arg_23_0.exp)
		local var_23_6 = string.format(var_0_1:translation("HUNQI_TEXT_34"), var_23_1, arg_23_0.exp, var_0_4:exp(arg_23_0.item.star, arg_23_0.item.lev + 1))
		local var_23_7 = xyd.createMultiColorTxt(var_23_6, cc.c3b(255, 255, 255), 16, nil, cc.c4b(59, 59, 94, 255))

		var_23_7:setAnchorPoint(cc.p(0.5, 0, 5))
		var_23_7:addTo(arg_23_0:nodeByName("node_progress"))
		var_23_7:setPositionY(-10)
		arg_23_0:nodeByName("arrow3"):setVisible(true)
		arg_23_0:nodeByName("level_2"):setString(var_23_5)
		arg_23_0.mainAttrItem:getChildByName("arrow3"):setVisible(true)

		local var_23_8 = arg_23_0.item.table_id
		local var_23_9 = var_0_3:modelId(var_23_8)
		local var_23_10 = var_0_2:mainTotalValue(var_23_9, arg_23_0.item.main, var_23_5)

		if var_0_2:mainIsP(var_23_9, arg_23_0.item.main) ~= 0 then
			var_23_10 = var_23_10 / xyd.DECIMAL_BASE * 100
			var_23_10 = var_23_10 .. "%"
		end

		arg_23_0.mainAttrItem:getChildByName("new_attr"):setString("+" .. var_23_10)

		if var_23_0 < var_23_5 then
			local var_23_11

			for iter_23_0 = 1, 3 do
				if (var_23_0 + iter_23_0) % 3 == 0 then
					var_23_11 = var_23_0 + iter_23_0

					break
				end
			end

			if var_23_11 and var_23_11 <= var_23_5 then
				arg_23_0:nodeByName("text_sthrengthen_desc"):setVisible(true)
			end
		end
	end
end

function var_0_0.initAttr(arg_24_0)
	arg_24_0:nodeByName("skill_item_container"):removeAllChildren()

	local var_24_0 = {}
	local var_24_1 = {}

	for iter_24_0 = 1, xyd.AttributeType.TOTAL_ATTR_NUM do
		local var_24_2 = arg_24_0.item
		local var_24_3 = var_24_2.table_id
		local var_24_4 = var_0_3:from(var_24_3)
		local var_24_5 = var_0_3:modelId(var_24_3)

		if var_0_2:main(var_24_5, var_24_2.main) == iter_24_0 then
			local var_24_6
			local var_24_7

			if var_0_2:mainIsP(var_24_5, var_24_2.main) ~= 0 then
				var_24_6 = var_24_2.main_attr_value / xyd.DECIMAL_BASE
				var_24_7 = true
			else
				var_24_6 = var_24_2.main_attr_value
			end

			var_24_0 = {
				attrType = iter_24_0,
				attrNum = var_24_6,
				isP = var_24_7
			}
		end

		if var_24_2.sub then
			for iter_24_1 = 1, #var_24_2.sub do
				local var_24_8 = var_24_2.sub[iter_24_1]

				if var_0_2:sub(var_24_5, var_24_8) == iter_24_0 then
					local var_24_9

					if var_0_2:subIsP(var_24_5, var_24_8) ~= 0 then
						var_24_9 = var_24_2.sub_attr_value[iter_24_1] / xyd.DECIMAL_BASE
					else
						var_24_9 = var_24_2.sub_attr_value[iter_24_1]
					end

					if #var_24_1 > 0 and var_24_1[#var_24_1].attrType == iter_24_0 then
						var_24_1[#var_24_1].attrNum = var_24_1[#var_24_1].attrNum + var_24_9
					else
						local var_24_10 = {
							attrType = iter_24_0,
							attrNum = var_24_9
						}

						if var_0_2:subIsP(var_24_5, var_24_8) ~= 0 then
							var_24_10.isP = true
						end

						table.insert(var_24_1, var_24_10)
					end
				end
			end
		end
	end

	local var_24_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/attr_item_main.csb")

	arg_24_0.mainAttrItem = var_24_11:getChildByName("container")

	arg_24_0:initAttrItem(var_24_11, var_24_0, 1)

	for iter_24_2, iter_24_3 in ipairs(var_24_1) do
		local var_24_12 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/attr_item.csb")

		arg_24_0:initAttrItem(var_24_12, iter_24_3, iter_24_2 + 2)
	end
end

function var_0_0.initAttrItem(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	local var_25_0 = arg_25_0:nodeByName("skill_item_container")
	local var_25_1 = var_25_0:getHeight()
	local var_25_2 = arg_25_1:getChildByName("container")
	local var_25_3

	if arg_25_2.isP then
		var_25_3 = arg_25_2.attrNum * 100
		var_25_3 = var_25_3 .. "%"
	else
		var_25_3 = arg_25_2.attrNum
	end

	var_25_2:getChildByName("name"):setString(xyd.tables.attr:name(arg_25_2.attrType))
	var_25_2:getChildByName("attr"):setString("+" .. var_25_3)
	arg_25_1:addTo(var_25_0)

	local var_25_4 = 0
	local var_25_5 = 0

	if arg_25_3 % 2 == 0 then
		var_25_4 = var_25_2:getWidth()
	end

	local var_25_6 = math.floor((arg_25_3 + 1) / 2) * var_25_2:getHeight()

	arg_25_1:setPosition(var_25_4, var_25_1 - var_25_6)
end

function var_0_0.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevY_ = arg_26_1.y
	elseif arg_26_1.name == "moved" and 20 <= math.abs(arg_26_1.y - arg_26_0.prevY_) then
		arg_26_0.scrollViewMoved_ = true
	end
end

function var_0_0.itemPosDelegate(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	local var_27_0 = math.ceil(#arg_27_0.posItems_ / var_0_9)

	if cc.ui.UIListView.COUNT_TAG == arg_27_2 then
		return var_27_0
	elseif cc.ui.UIListView.CELL_TAG == arg_27_2 then
		if var_27_0 < arg_27_3 then
			return nil
		end

		local var_27_1 = arg_27_0.listItemPos:dequeueItem()

		if not var_27_1 then
			var_27_1 = arg_27_0.listItemPos:newItem()
		else
			var_27_1:removeAllChildren(true)
		end

		local var_27_2 = display.newNode()

		arg_27_0:initCell(var_27_2, arg_27_3)

		local var_27_3 = display.newNode()

		var_27_3:addChild(var_27_2)
		var_27_3:setContentSize(var_27_2:getContentSize())
		var_27_1:setItemSize(var_27_2:getContentSize().width, var_27_2:getContentSize().height)
		var_27_1:addContent(var_27_3)

		return var_27_1
	end
end

function var_0_0.initCell(arg_28_0, arg_28_1, arg_28_2)
	for iter_28_0 = 1, var_0_9 do
		local var_28_0 = (arg_28_2 - 1) * var_0_9 + iter_28_0

		if var_28_0 > #arg_28_0.posItems_ then
			break
		end

		local var_28_1 = arg_28_0.posItems_[var_28_0]
		local var_28_2 = display.newNode()

		var_28_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_28_2:setContentSize(var_0_10, var_0_10)

		local var_28_3 = {
			container = var_28_2,
			item = var_28_1
		}

		xyd.setHunqiBorder(var_28_3)
		var_28_2:setTouchEnabled(true)
		var_28_2:setTouchSwallowEnabled(false)
		var_28_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
			if arg_29_0.name == "began" then
				var_28_2:setScale(0.9)
			elseif arg_29_0.name == "moved" then
				if not arg_28_0.scrollViewMoved_ then
					var_28_2:setScale(1)
				end
			elseif arg_29_0.name == "ended" then
				var_28_2:setScale(1)

				if not arg_28_0.scrollViewMoved_ then
					xyd.playButtonSound()

					if var_28_1.is_lock ~= 0 then
						local var_29_0 = var_0_1:translation("HUNQI_TEXT_33")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_29_0
						})

						return
					end

					local var_29_1 = xyd.getKeyByValue(arg_28_0.selectSpiritIDs, var_28_1.spirit_id)

					if not var_29_1 then
						arg_28_0:addExpItem(var_28_1, var_28_2)
					else
						arg_28_0:removeExpItem(var_28_1, var_29_1)
					end

					arg_28_0:performWithDelay(function()
						local var_30_0 = xyd.WindowManager.get():openWindow("hunqi_detail", {
							item1 = var_28_1
						})

						var_30_0:setPosition(610, xyd.STAGE_HEIGHT - var_30_0:getTipHeight() - 100)
					end, 0.03333333333333333)
				end
			end

			return true
		end)

		local var_28_4 = xyd.getKeyByValue(arg_28_0.selectSpiritIDs, var_28_1.spirit_id)

		if var_28_4 then
			local var_28_5 = xyd.AssetLoader.get():loadSprite("windows/common/check.png")

			var_28_5:addTo(var_28_2)
			var_28_5:setAnchorPoint(cc.p(1, 1))
			var_28_5:setPosition(var_0_10 - 4, var_0_10 - 8)
			var_28_5:setName("choose")

			arg_28_0.selectNodes[var_28_4] = var_28_2
		end

		var_28_2:addTo(arg_28_1)
		var_28_2:setPosition((iter_28_0 - 1) * (var_0_10 + 20) + var_0_10 / 2, 16 + var_0_10 / 2)
	end

	arg_28_1:setContentSize(arg_28_0:nodeByName("list_item_pos"):getWidth() + 10, var_0_10 + 16)
end

function var_0_0.addExpItem(arg_31_0, arg_31_1, arg_31_2)
	if arg_31_0.item.exp + arg_31_0.exp >= var_0_4:maxExp(arg_31_0.item.star, xyd.HunqiMaxLev) then
		local var_31_0 = var_0_1:translation("HUNQI_TEXT_35")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_31_0
		})

		return
	end

	local var_31_1 = xyd.AssetLoader.get():loadSprite("windows/common/check.png")

	var_31_1:addTo(arg_31_2)
	var_31_1:setAnchorPoint(cc.p(1, 1))
	var_31_1:setPosition(var_0_10 - 4, var_0_10 - 8)
	var_31_1:setName("choose")
	table.insert(arg_31_0.selectSpiritIDs, arg_31_1.spirit_id)
	table.insert(arg_31_0.selectNodes, arg_31_2)

	local var_31_2 = arg_31_1.table_id
	local var_31_3 = var_0_3:modelId(var_31_2)

	arg_31_0.exp = arg_31_0.exp + var_0_2:exp(var_31_3) + arg_31_1.exp * xyd.tables.misc:getValue("spirit_strth_exp_rate")

	arg_31_0:updateExpShow()
end

function var_0_0.removeExpItem(arg_32_0, arg_32_1, arg_32_2)
	arg_32_0.selectNodes[arg_32_2]:removeChildByName("choose")
	table.remove(arg_32_0.selectSpiritIDs, arg_32_2)
	table.remove(arg_32_0.selectNodes, arg_32_2)

	local var_32_0 = arg_32_1.table_id
	local var_32_1 = var_0_3:modelId(var_32_0)

	arg_32_0.exp = arg_32_0.exp - var_0_2:exp(var_32_1) - arg_32_1.exp * xyd.tables.misc:getValue("spirit_strth_exp_rate")

	arg_32_0:updateExpShow()
end

return var_0_0
