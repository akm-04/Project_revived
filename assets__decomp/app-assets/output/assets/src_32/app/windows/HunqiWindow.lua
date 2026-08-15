local var_0_0 = class("HunqiWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.spiritSuit
local var_0_3 = xyd.tables.spirit
local var_0_4 = xyd.tables.spiritEquip
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
	xyd.AttributeType.HP,
	xyd.AttributeType.AD,
	xyd.AttributeType.AP,
	xyd.AttributeType.HUJIA,
	xyd.AttributeType.MOKANG,
	xyd.AttributeType.BAOJI_RATE,
	xyd.AttributeType.BAOJIHARM,
	xyd.AttributeType.ZHUANGTAI_KANGXING,
	xyd.AttributeType.ZHUANGTAI_MINGZHONG,
	xyd.AttributeType.HUNQI_HP_BONUS,
	xyd.AttributeType.HUNQI_AD_AP_BONUS,
	xyd.AttributeType.HUNQI_JIAKANG_BONUS
}
local var_0_12 = {
	CHOOSE_TYPE = 1,
	POS = 2,
	TYPE = 3
}
local var_0_13 = {
	TWO = 2,
	ONE = 1
}
local var_0_14 = {
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
local var_0_15 = 15
local var_0_16 = {
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
local var_0_17 = {
	EQUIP = 1,
	UNEQUIP = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.heros_ = arg_1_2.heros
	arg_1_0.current_ = arg_1_2.current
	arg_1_0.showType = var_0_12.POS
	arg_1_0.typeState = nil
	arg_1_0.posState = 1
	arg_1_0.selectIndex = nil
	arg_1_0.selectNode = nil
	arg_1_0.itemShow = var_0_13.ONE
	arg_1_0.sortTypeType = var_0_14.LEV
	arg_1_0.sortTypePos = var_0_14.LEV
	arg_1_0.blockTextNum = {}
	arg_1_0.longBlockTextNum = {}
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:initUnequipItem()
	arg_2_0:layout()
	arg_2_0:setText()
	arg_2_0:setBtns()
end

function var_0_0.initUnequipItem(arg_3_0)
	arg_3_0.items_ = arg_3_0.backpack:getSpiritItems()
	arg_3_0.unequipItem_ = {}
	arg_3_0.typeAllItems_ = {}
	arg_3_0.posAllItems_ = {}

	for iter_3_0 = 1, 6 do
		arg_3_0.posAllItems_[iter_3_0] = {}
	end

	for iter_3_1, iter_3_2 in pairs(arg_3_0.items_) do
		if iter_3_2.is_equip == 0 then
			table.insert(arg_3_0.unequipItem_, iter_3_2)
		end
	end

	for iter_3_3, iter_3_4 in ipairs(arg_3_0.unequipItem_) do
		local var_3_0 = iter_3_4.table_id
		local var_3_1 = var_0_4:modelId(var_3_0)
		local var_3_2 = var_0_3:pos(var_3_1)
		local var_3_3 = var_0_4:from(var_3_0)

		if not arg_3_0.typeAllItems_[var_3_3] then
			arg_3_0.typeAllItems_[var_3_3] = {}

			for iter_3_5 = 1, 6 do
				arg_3_0.typeAllItems_[var_3_3][iter_3_5] = {}
			end
		end

		table.insert(arg_3_0.typeAllItems_[var_3_3][var_3_2], iter_3_4)
	end

	for iter_3_6, iter_3_7 in ipairs(arg_3_0.unequipItem_) do
		local var_3_4 = iter_3_7.table_id
		local var_3_5 = var_0_4:modelId(var_3_4)
		local var_3_6 = var_0_3:pos(var_3_5)

		table.insert(arg_3_0.posAllItems_[var_3_6], iter_3_7)
	end
end

function var_0_0.didOpen(arg_4_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.HUNQI_SORT, handler(arg_4_0, arg_4_0.sortList))
end

function var_0_0.sortList(arg_5_0, arg_5_1)
	if arg_5_0.showType == var_0_12.POS then
		arg_5_0.sortTypePos = arg_5_1.type_

		arg_5_0:sortItems(arg_5_0.posItems_, arg_5_0.sortTypePos)
		arg_5_0.listItemPos:reload()
		arg_5_0:updateShow()
	elseif arg_5_0.showType == var_0_12.TYPE then
		arg_5_0.sortTypeType = arg_5_1.type_

		arg_5_0:sortItems(arg_5_0.typeItems_, arg_5_0.sortTypeType)
		arg_5_0.listItemType:reload()
		arg_5_0:updateShow()
	end
end

function var_0_0.setText(arg_6_0)
	for iter_6_0 = 1, 6 do
		arg_6_0:nodeByName("text_pos_" .. iter_6_0):setString(var_0_1:translation("NUM_" .. iter_6_0))
	end

	arg_6_0:nodeByName("text_skill_desc"):getVirtualRenderer():setLineHeight(26)
	arg_6_0:nodeByName("text_title"):setString(var_0_1:translation("HUNQI_TEXT_20"))
	arg_6_0:nodeByName("text_num"):setString(string.format(var_0_1:translation("HUNQI_TEXT_3"), arg_6_0.backpack:getSpiritNum(), xyd.tables.misc:getValue("spirit_num_limit")))
	arg_6_0:nodeByName("text_type"):setString(var_0_1:translation("HUNQI_TEXT_1"))
	arg_6_0:nodeByName("text_pos"):setString(var_0_1:translation("HUNQI_TEXT_2"))
	arg_6_0:nodeByName("text_one_key_off"):setString(var_0_1:translation("HUNQI_TEXT_4"))
	arg_6_0:nodeByName("text_campaign"):setString(var_0_1:translation("HUNQI_TEXT_78"))
	arg_6_0:nodeByName("text_num"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
	arg_6_0:nodeByName("text_name"):enableOutline(cc.c4b(59, 59, 94, 255), 2)
end

function var_0_0.setBtns(arg_7_0)
	local var_7_0 = var_0_6.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_7_0:addTo(arg_7_0)
	var_7_0:setAnchorPoint(0.5, 0.5)
	var_7_0:setPosition(44, 697)
	var_7_0:setName("return_btn")

	arg_7_0.returnBtn = var_7_0

	arg_7_0.returnBtn:addTouchEvent(function(arg_8_0)
		if arg_8_0.name == "ended" then
			xyd.WindowManager.get():closeWindow(arg_7_0)
		end
	end)
	arg_7_0:nodeByName("btn_choose_type"):setTouchEnabled(true)
	arg_7_0:nodeByName("btn_choose_type"):setTouchSwallowEnabled(true)
	arg_7_0:nodeByName("btn_choose_type"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playCloseSound()

			if arg_7_0.showType == var_0_12.TYPE then
				arg_7_0.showType = var_0_12.CHOOSE_TYPE
				arg_7_0.selectIndex = nil
				arg_7_0.selectItem = nil

				arg_7_0:updateShow()
			end
		end
	end)
	arg_7_0:nodeByName("btn_type_desc"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = {
				itemParams1 = {
					isSuit = true,
					suitID = arg_7_0.typeState
				}
			}
			local var_10_1 = xyd.WindowManager.get():openWindow("hunqi_detail", var_10_0)

			var_10_1:setPosition(330, xyd.STAGE_HEIGHT - var_10_1:getTipHeight() - 100)
		end
	end)
	arg_7_0:nodeByName("btn_sort"):setTouchEnabled(true)
	arg_7_0:nodeByName("btn_sort"):setTouchSwallowEnabled(true)
	arg_7_0:nodeByName("btn_sort"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = {}

			table.insert(var_11_0, var_0_14.LEV)
			table.insert(var_11_0, var_0_14.QUALITY)
			table.insert(var_11_0, var_0_14.GET_TIME)
			table.insert(var_11_0, var_0_14.HP)
			table.insert(var_11_0, var_0_14.AD)
			table.insert(var_11_0, var_0_14.AP)
			table.insert(var_11_0, var_0_14.HUJIA)
			table.insert(var_11_0, var_0_14.MOKANG)
			table.insert(var_11_0, var_0_14.BAOJI_RATE)
			table.insert(var_11_0, var_0_14.BAOJIHARM)
			table.insert(var_11_0, var_0_14.ZHUANGTAI_KANGXING)
			table.insert(var_11_0, var_0_14.ZHUANGTAI_MINGZHONG)
			table.insert(var_11_0, var_0_14.HUNQI_HP_BONUS)
			table.insert(var_11_0, var_0_14.HUNQI_AD_AP_BONUS)
			table.insert(var_11_0, var_0_14.HUNQI_JIAKANG_BONUS)

			local var_11_1 = {
				colNum = 2,
				types = var_11_0
			}
			local var_11_2 = xyd.WindowManager.get():openWindow("hunqi_sort_type", var_11_1)

			var_11_2:setPosition(400, 570 - var_11_2:getTipHeight())
		end
	end)
	arg_7_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = {}

			var_12_0.title_name = "SPIRIT_RULE_TITLE"
			var_12_0.rule = "SPIRIT_RULE_TEXT"
			var_12_0.style = xyd.RuleStyle.BLUE

			xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
		end
	end)
	arg_7_0:nodeByName("btn_type"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.showType = var_0_12.CHOOSE_TYPE
			arg_7_0.posState = nil
			arg_7_0.selectIndex = nil
			arg_7_0.selectItem = nil

			arg_7_0:updateShow()
			arg_7_0:updateBlockShowNum()
		end
	end)
	arg_7_0:nodeByName("btn_pos"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.showType = var_0_12.POS
			arg_7_0.posState = 1

			arg_7_0:updateList()
		end
	end)
	arg_7_0:nodeByName("btn_block"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.itemShow = var_0_13.TWO

			arg_7_0:updateShow()
		end
	end)
	arg_7_0:nodeByName("btn_long_block"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_7_0.itemShow = var_0_13.ONE

			arg_7_0:updateShow()
		end
	end)
	arg_7_0:nodeByName("btn_comb"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_17_0 = {
				hero = arg_7_0.hero
			}

			xyd.Backend.get():request(xyd.mid.HUNQI_GET_COLLOCATION_INFOS, nil, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					var_17_0.infos = arg_18_1

					xyd.WindowManager.get():openWindow("hunqi_comb", var_17_0)
				end
			end)
		end
	end)
	arg_7_0:nodeByName("btn_campaign"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_7_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_HUNQI) then
				xyd.Backend.get():request(xyd.mid.HUNQI_GET_CAMPAIGN_INFO, {}, function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("hunqi_campaign", arg_20_1)
					end
				end)
			else
				local var_19_0 = xyd.tables.functionOpen:tip(xyd.FunctionID.ID_HUNQI)

				if var_19_0 == "" then
					var_19_0 = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_0
				})
			end
		end
	end)
	arg_7_0:nodeByName("btn_one_key_off"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_21_0, arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_21_0 = {
				partner_id = arg_7_0.hero:getHeroID()
			}

			xyd.Backend.get():request(xyd.mid.HUNQI_ONE_KEY_UNEQUIP, var_21_0, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					local var_22_0 = arg_7_0.hero:getSpiritEquips()

					for iter_22_0 = 1, 6 do
						if var_22_0[iter_22_0] ~= 0 then
							local var_22_1 = arg_7_0.backpack:getSpiritItemBySpiritID(var_22_0[iter_22_0])

							arg_7_0.backpack:setSpiritItem(var_22_1.spirit_id, {
								is_equip = 0
							})
						end
					end

					arg_7_0.hero:setSpiritEquips(arg_22_1.spirit_equip)
					arg_7_0:updateAllItems()

					local var_22_2 = xyd.WindowManager.get():getWindow("hero_main")

					if var_22_2 and not tolua.isnull(var_22_2) then
						var_22_2:updateAttrScore()
						var_22_2:updateAttrLabels()
					end
				end
			end)
		end
	end)
	arg_7_0:nodeByName("btn_left"):addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(arg_23_0, arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_23_0()
				if arg_7_0.current_ > 1 then
					arg_7_0.current_ = arg_7_0.current_ - 1
				else
					arg_7_0.current_ = #arg_7_0.heros_
				end

				if not arg_7_0.heros_[arg_7_0.current_]:isCollected() then
					var_23_0()
				end
			end

			var_23_0()
			arg_7_0:updateHero()
		end
	end)
	arg_7_0:nodeByName("btn_right"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_25_0, arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_25_0()
				if arg_7_0.current_ < #arg_7_0.heros_ then
					arg_7_0.current_ = arg_7_0.current_ + 1
				else
					arg_7_0.current_ = 1
				end

				if not arg_7_0.heros_[arg_7_0.current_]:isCollected() then
					var_25_0()
				end
			end

			var_25_0()
			arg_7_0:updateHero()
		end
	end)

	for iter_7_0 = 1, 6 do
		local var_7_1 = display.newNode()

		var_7_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_1:setContentSize(68, 53)
		var_7_1:setTouchEnabled(true)
		var_7_1:setTouchSwallowEnabled(true)
		var_7_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
			if arg_27_0.name == "ended" and arg_7_0.posState ~= iter_7_0 then
				xyd.playButtonSound()

				arg_7_0.posState = iter_7_0

				arg_7_0:updateList()
			end

			return true
		end)
		var_7_1:addTo(arg_7_0:nodeByName("line_pos"))
		var_7_1:setPosition(arg_7_0:nodeByName("pos_" .. iter_7_0 .. "_an"):getPosition())

		local var_7_2 = display.newNode()

		var_7_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_2:setContentSize(110, 110)
		var_7_2:setTouchEnabled(true)
		var_7_2:setTouchSwallowEnabled(true)
		var_7_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
			if arg_28_0.name == "ended" then
				xyd.playButtonSound()

				if arg_7_0.showType == var_0_12.POS then
					if arg_7_0.posState ~= iter_7_0 then
						arg_7_0.posState = iter_7_0

						arg_7_0:updateList()
					end
				elseif arg_7_0.showType == var_0_12.CHOOSE_TYPE then
					if arg_7_0.posState ~= iter_7_0 then
						arg_7_0.posState = iter_7_0
					else
						arg_7_0.posState = nil
					end

					arg_7_0:updateShow()
					arg_7_0:updateBlockShowNum()
				elseif arg_7_0.showType == var_0_12.TYPE then
					if arg_7_0.posState ~= iter_7_0 then
						arg_7_0.posState = iter_7_0

						arg_7_0:updateList()
					else
						arg_7_0.posState = nil
						arg_7_0.selectIndex = nil
						arg_7_0.selectItem = nil

						arg_7_0:updateList()
					end
				end

				local var_28_0 = arg_7_0.heros_[arg_7_0.current_]
				local var_28_1 = var_28_0:getSpiritEquips()

				if var_28_1[iter_7_0] ~= 0 then
					arg_7_0:performWithDelay(function()
						local var_29_0 = arg_7_0.backpack:getSpiritItemBySpiritID(var_28_1[iter_7_0])
						local var_29_1 = {
							rightBtnType = var_0_17.UNEQUIP
						}

						var_29_1.showStrenthen = true
						var_29_1.showActive = true

						local var_29_2 = {
							hero = var_28_0,
							item1 = var_29_0,
							itemParams1 = var_29_1
						}
						local var_29_3 = xyd.WindowManager.get():openWindow("hunqi_detail", var_29_2)

						if iter_7_0 < 4 then
							var_29_3:setPosition(940, xyd.STAGE_HEIGHT - var_29_3:getTipHeight() - 80)
						else
							var_29_3:setPosition(620, xyd.STAGE_HEIGHT - var_29_3:getTipHeight() - 80)
						end
					end, 0.03333333333333333)
				end
			end

			return true
		end)
		var_7_2:addTo(arg_7_0:nodeByName("node_item_" .. iter_7_0))
	end
end

function var_0_0.layout(arg_30_0)
	arg_30_0.listItemType = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_30_0:nodeByName("list_item_type"):getContentSize().width + 10, arg_30_0:nodeByName("list_item_type"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_30_0:nodeByName("list_item_type")):onScroll(handler(arg_30_0, arg_30_0.scrollListener))

	arg_30_0.listItemType:setDelegate(handler(arg_30_0, arg_30_0.itemTypeDelegate))

	arg_30_0.listItemPos = cc.ui.UIListView.new({
		async = true,
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_30_0:nodeByName("list_item_pos"):getContentSize().width + 10, arg_30_0:nodeByName("list_item_pos"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_30_0:nodeByName("list_item_pos")):onScroll(handler(arg_30_0, arg_30_0.scrollListener))

	arg_30_0.listItemPos:setDelegate(handler(arg_30_0, arg_30_0.itemPosDelegate))

	arg_30_0.listTypeBlock = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_30_0:nodeByName("list_type_block"):getContentSize().width + 20, arg_30_0:nodeByName("list_type_block"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_30_0:nodeByName("list_type_block")):onScroll(handler(arg_30_0, arg_30_0.scrollListener))

	arg_30_0:refreshTypeBlockList()

	arg_30_0.listTypeLongBlock = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, arg_30_0:nodeByName("list_type_long_block"):getContentSize().width + 20, arg_30_0:nodeByName("list_type_long_block"):getContentSize().height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_30_0:nodeByName("list_type_long_block")):onScroll(handler(arg_30_0, arg_30_0.scrollListener))

	arg_30_0:refreshTypeLongBlockList()

	local var_30_0 = xyd.createEffect("skeletons/ui_effect/hunqi/hunqibeijing")

	var_30_0:addTo(arg_30_0:nodeByName("xingzhen"))
	var_30_0:setPosition(arg_30_0:nodeByName("xingzhen"):getWidth() / 2 - 5, arg_30_0:nodeByName("xingzhen"):getHeight() / 2 + 3)
	var_30_0:play(nil, true, nil, "texiao01")

	local var_30_1 = xyd.createEffect("skeletons/ui_effect/hunqi/zhengtibeijing")

	var_30_1:addTo(arg_30_0:nodeByName("bg"))
	var_30_1:setPosition(640, 360)
	var_30_1:play(nil, true, nil, "animation")

	arg_30_0.showType = var_0_12.POS
	arg_30_0.posState = 1

	arg_30_0:updateHero()
	arg_30_0:updateList()
end

function var_0_0.updateHero(arg_31_0)
	if arg_31_0.hero ~= arg_31_0.heros_[arg_31_0.current_] then
		arg_31_0.oldSuit2 = nil
		arg_31_0.oldSuit4 = nil
	end

	arg_31_0.hero = arg_31_0.heros_[arg_31_0.current_]

	local var_31_0 = arg_31_0:nodeByName("avatar")

	var_31_0:removeAllChildren()
	xyd.setAvatarBorderNewUI(arg_31_0.hero, var_31_0)
	arg_31_0:nodeByName("text_name"):setString(arg_31_0.hero:getName())

	local var_31_1 = arg_31_0.hero:getSpiritEquips()

	for iter_31_0 = 1, 6 do
		local var_31_2 = arg_31_0:nodeByName("node_item_" .. iter_31_0)

		if var_31_2:getChildByName("item") then
			var_31_2:removeChildByName("item")
		end

		if var_31_1[iter_31_0] ~= 0 then
			local var_31_3 = display.newNode()

			var_31_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_31_3:setContentSize(xyd.HunqiDefualtSize, xyd.HunqiDefualtSize)

			local var_31_4 = {
				noBorder = true,
				levShowTop = true,
				container = var_31_3,
				item = arg_31_0.backpack:getSpiritItemBySpiritID(var_31_1[iter_31_0])
			}

			xyd.setHunqiBorder(var_31_4)
			var_31_3:addTo(var_31_2)
			var_31_3:setName("item")
		end
	end

	local var_31_5 = arg_31_0:nodeByName("skill_item_container")

	var_31_5:removeAllChildren()

	local var_31_6 = {}

	for iter_31_1, iter_31_2 in ipairs(var_0_11) do
		var_31_6[iter_31_1] = {
			attrNum = 0,
			attrType = iter_31_2
		}

		if xyd.tables.attr:isPercent(iter_31_2) then
			var_31_6[iter_31_1].isP = true
		end

		for iter_31_3, iter_31_4 in ipairs(var_31_1) do
			if iter_31_4 ~= 0 then
				local var_31_7 = arg_31_0.backpack:getSpiritItemBySpiritID(iter_31_4)
				local var_31_8 = var_31_7.table_id
				local var_31_9 = var_0_4:from(var_31_8)
				local var_31_10 = var_0_4:modelId(var_31_8)

				if var_0_3:main(var_31_10, var_31_7.main) == iter_31_2 then
					var_31_6[iter_31_1].attrNum = var_31_6[iter_31_1].attrNum + var_31_7.main_attr_value
				end

				if var_31_7.sub then
					for iter_31_5 = 1, #var_31_7.sub do
						local var_31_11 = var_31_7.sub[iter_31_5]

						if var_0_3:sub(var_31_10, var_31_11) == iter_31_2 then
							var_31_6[iter_31_1].attrNum = var_31_6[iter_31_1].attrNum + var_31_7.sub_attr_value[iter_31_5]
						end
					end
				end
			end
		end
	end

	local var_31_12 = arg_31_0.hero:getSpiritSuitID()

	for iter_31_6, iter_31_7 in ipairs(var_31_12) do
		local var_31_13 = var_0_2:attr2(iter_31_7)
		local var_31_14 = var_0_2:attr2Value(iter_31_7)

		for iter_31_8, iter_31_9 in ipairs(var_31_6) do
			if iter_31_9.attrType == var_31_13 then
				iter_31_9.attrNum = iter_31_9.attrNum + var_31_14
			end
		end
	end

	arg_31_0.bonusAttr = {}

	for iter_31_10 = #var_31_6, 1, -1 do
		local var_31_15 = var_31_6[iter_31_10]

		if var_31_15.attrType == xyd.AttributeType.HUNQI_HP_BONUS then
			arg_31_0.bonusAttr[xyd.AttributeType.HP] = var_31_15.attrNum

			table.remove(var_31_6, iter_31_10)
		elseif var_31_15.attrType == xyd.AttributeType.HUNQI_AD_AP_BONUS then
			arg_31_0.bonusAttr[xyd.AttributeType.AD] = var_31_15.attrNum
			arg_31_0.bonusAttr[xyd.AttributeType.AP] = var_31_15.attrNum

			table.remove(var_31_6, iter_31_10)
		elseif var_31_15.attrType == xyd.AttributeType.HUNQI_JIAKANG_BONUS then
			arg_31_0.bonusAttr[xyd.AttributeType.HUJIA] = var_31_15.attrNum
			arg_31_0.bonusAttr[xyd.AttributeType.MOKANG] = var_31_15.attrNum

			table.remove(var_31_6, iter_31_10)
		end
	end

	local var_31_16 = var_31_5:getHeight()

	for iter_31_11, iter_31_12 in ipairs(var_31_6) do
		local var_31_17 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/attr_item.csb")
		local var_31_18 = var_31_17:getChildByName("container")
		local var_31_19

		if iter_31_12.isP then
			var_31_19 = iter_31_12.attrNum / xyd.DECIMAL_BASE * 100

			if var_31_19 < 10 and var_31_19 > 0 then
				var_31_19 = string.format("%.2f", var_31_19)
			else
				var_31_19 = string.format("%.f", var_31_19)
			end

			var_31_19 = var_31_19 .. "%"
		elseif arg_31_0.bonusAttr[iter_31_12.attrType] then
			local var_31_20 = 1 + arg_31_0.bonusAttr[iter_31_12.attrType] / xyd.DECIMAL_BASE

			var_31_19 = iter_31_12.attrNum * var_31_20

			if var_31_19 < 10 and var_31_19 > 0 then
				var_31_19 = string.format("%.2f", var_31_19)
			else
				var_31_19 = string.format("%.f", var_31_19)
			end
		else
			var_31_19 = iter_31_12.attrNum

			if var_31_19 < 10 and var_31_19 > 0 then
				var_31_19 = string.format("%.2f", var_31_19)
			else
				var_31_19 = string.format("%.f", var_31_19)
			end
		end

		var_31_18:getChildByName("name"):setString(xyd.tables.attr:name(iter_31_12.attrType))
		var_31_18:getChildByName("attr"):setString("+" .. var_31_19)
		var_31_17:addTo(var_31_5)

		local var_31_21 = 0
		local var_31_22 = 0

		if iter_31_11 % 2 == 0 then
			var_31_21 = var_31_18:getWidth()
		end

		local var_31_23 = math.floor((iter_31_11 + 1) / 2) * var_31_18:getHeight()

		var_31_17:setPosition(var_31_21, var_31_16 - var_31_23)
	end

	local var_31_24, var_31_25 = arg_31_0.hero:getSpiritSuitID()

	if var_31_25 ~= 0 then
		arg_31_0:nodeByName("icon_skill"):setVisible(true)
		arg_31_0:nodeByName("text_skill_desc"):setVisible(true)
		arg_31_0:nodeByName("text_skill_desc"):setString(var_0_2:attr4Desc(var_31_25))
	else
		arg_31_0:nodeByName("icon_skill"):setVisible(false)
		arg_31_0:nodeByName("text_skill_desc"):setVisible(false)
	end

	if arg_31_0.oldSuit2 then
		if var_31_24 and next(var_31_24) then
			for iter_31_13, iter_31_14 in ipairs(var_31_24) do
				local var_31_26 = true

				if arg_31_0.oldSuit2 and next(arg_31_0.oldSuit2) then
					for iter_31_15, iter_31_16 in ipairs(arg_31_0.oldSuit2) do
						if iter_31_14 == iter_31_16 then
							var_31_26 = false

							break
						end
					end
				end

				if var_31_26 then
					arg_31_0:runSuitEffect(iter_31_14)

					break
				end
			end
		end

		if var_31_25 ~= 0 and arg_31_0.oldSuit4 ~= var_31_25 then
			arg_31_0:runSuitEffect(var_31_25)
		end
	end

	arg_31_0.oldSuit2 = var_31_24
	arg_31_0.oldSuit4 = var_31_25
end

function var_0_0.runSuitEffect(arg_32_0, arg_32_1)
	local var_32_0 = arg_32_0.hero:getSpiritEquips()

	for iter_32_0 = 1, 6 do
		local var_32_1 = var_32_0[iter_32_0]

		if var_32_1 ~= 0 then
			local var_32_2 = arg_32_0.backpack:getSpiritItemBySpiritID(var_32_1)

			if var_0_4:from(var_32_2.table_id) == arg_32_1 then
				local var_32_3 = arg_32_0:nodeByName("xingzhen")
				local var_32_4 = var_32_3:getChildByName("effct" .. iter_32_0)

				if not var_32_4 then
					var_32_4 = xyd.createEffect("skeletons/ui_effect/hunqi/zhuangbeilan")

					var_32_4:addTo(var_32_3, 10)
					var_32_4:setPosition(var_32_3:getWidth() / 2, var_32_3:getHeight() / 2)
					var_32_4:setName("effect" .. iter_32_0)
				end

				var_32_4:play(nil, false, nil, "texiao0" .. iter_32_0)
			end
		end
	end

	local var_32_5 = arg_32_0:nodeByName("xingzhen")
	local var_32_6 = var_32_5:getChildByName("effct_word")

	if not var_32_6 then
		var_32_6 = xyd.createEffect("skeletons/ui_effect/hunqi/taozhuangjihuo")

		var_32_6:addTo(arg_32_0, 10)
		var_32_6:setPosition(var_32_5:getPosition())
		var_32_6:setName("effct_word")
	end

	var_32_6:setVisible(true)
	var_32_6:play(function()
		var_32_6:setVisible(false)
	end, false, nil, "texiao01")
end

function var_0_0.updateShow(arg_34_0)
	arg_34_0:nodeByName("pos_container"):setVisible(false)
	arg_34_0:nodeByName("type_container"):setVisible(false)
	arg_34_0:nodeByName("btn_type"):setVisible(false)
	arg_34_0:nodeByName("btn_pos"):setVisible(false)
	arg_34_0:nodeByName("btn_block"):setVisible(false)
	arg_34_0:nodeByName("btn_long_block"):setVisible(false)
	arg_34_0:nodeByName("btn_sort"):setVisible(false)
	arg_34_0:nodeByName("btn_choose_type"):setVisible(false)
	arg_34_0:nodeByName("btn_type_desc"):setVisible(false)
	arg_34_0.listItemType:setVisible(false)
	arg_34_0.listItemPos:setVisible(false)
	arg_34_0.listTypeBlock:setVisible(false)
	arg_34_0.listTypeLongBlock:setVisible(false)
	arg_34_0:setSelectEquipNode(arg_34_0.posState)

	if arg_34_0.showType == var_0_12.CHOOSE_TYPE then
		arg_34_0:nodeByName("type_container"):setVisible(true)
		arg_34_0:nodeByName("btn_type"):setVisible(true)
		arg_34_0:nodeByName("btn_pos"):setVisible(true)

		if arg_34_0.itemShow == var_0_13.ONE then
			arg_34_0:nodeByName("btn_block"):setVisible(true)
			arg_34_0.listTypeLongBlock:setVisible(true)
		else
			arg_34_0:nodeByName("btn_long_block"):setVisible(true)
			arg_34_0.listTypeBlock:setVisible(true)
		end

		arg_34_0:nodeByName("btn_type"):setEnabled(false)
		arg_34_0:nodeByName("btn_pos"):setEnabled(true)
	elseif arg_34_0.showType == var_0_12.POS then
		arg_34_0:nodeByName("pos_container"):setVisible(true)
		arg_34_0:nodeByName("btn_type"):setVisible(true)
		arg_34_0:nodeByName("btn_pos"):setVisible(true)
		arg_34_0:nodeByName("btn_sort"):setVisible(true)
		arg_34_0:nodeByName("btn_type"):setEnabled(true)
		arg_34_0:nodeByName("btn_pos"):setEnabled(false)
		arg_34_0.listItemPos:setVisible(true)

		for iter_34_0 = 1, 6 do
			arg_34_0:nodeByName("btn_choose"):getChildByName("pos_" .. iter_34_0):setVisible(false)
		end

		arg_34_0:nodeByName("btn_choose"):setPositionX(var_0_8[arg_34_0.posState])
		arg_34_0:nodeByName("btn_choose"):getChildByName("pos_" .. arg_34_0.posState):setVisible(true)
		arg_34_0:nodeByName("text_choose"):setString(var_0_1:translation("NUM_" .. arg_34_0.posState))
		arg_34_0:nodeByName("text_sort"):setString(var_0_16[arg_34_0.sortTypePos])

		local var_34_0 = xyd.getTextLen(var_0_16[arg_34_0.sortTypePos])

		if var_34_0 > 4 then
			arg_34_0:nodeByName("text_sort"):setFontSize(math.floor(24 / var_34_0 * 4))
		else
			arg_34_0:nodeByName("text_sort"):setFontSize(20)
		end
	elseif arg_34_0.showType == var_0_12.TYPE then
		arg_34_0:nodeByName("type_container"):setVisible(true)
		arg_34_0:nodeByName("btn_choose_type"):setVisible(true)
		arg_34_0:nodeByName("btn_type_desc"):setVisible(true)
		arg_34_0:nodeByName("btn_sort"):setVisible(true)
		arg_34_0.listItemType:setVisible(true)
		arg_34_0:nodeByName("text_choose_type"):setString(var_0_2:name(arg_34_0.typeState))
		arg_34_0:nodeByName("text_sort"):setString(var_0_16[arg_34_0.sortTypeType])

		local var_34_1 = xyd.getTextLen(var_0_16[arg_34_0.sortTypeType])

		if var_34_1 > 4 then
			arg_34_0:nodeByName("text_sort"):setFontSize(math.floor(22 / var_34_1 * 4))
		else
			arg_34_0:nodeByName("text_sort"):setFontSize(20)
		end
	end
end

function var_0_0.scrollListener(arg_35_0, arg_35_1)
	if arg_35_1.name == "began" then
		arg_35_0.scrollViewMoved_ = false
		arg_35_0.prevY_ = arg_35_1.y
	elseif arg_35_1.name == "moved" and 20 <= math.abs(arg_35_1.y - arg_35_0.prevY_) then
		arg_35_0.scrollViewMoved_ = true
	end
end

function var_0_0.itemTypeDelegate(arg_36_0, arg_36_1, arg_36_2, arg_36_3)
	local var_36_0 = math.ceil(#arg_36_0.typeItems_ / var_0_9)

	if cc.ui.UIListView.COUNT_TAG == arg_36_2 then
		return var_36_0
	elseif cc.ui.UIListView.CELL_TAG == arg_36_2 then
		if var_36_0 < arg_36_3 then
			return nil
		end

		local var_36_1 = arg_36_0.listItemType:dequeueItem()

		if not var_36_1 then
			var_36_1 = arg_36_0.listItemType:newItem()
		else
			var_36_1:removeAllChildren(true)
		end

		local var_36_2 = display.newNode()

		arg_36_0:initCell(var_36_2, arg_36_3, var_0_12.TYPE)

		local var_36_3 = display.newNode()

		var_36_3:addChild(var_36_2)
		var_36_3:setContentSize(var_36_2:getContentSize())
		var_36_1:setItemSize(var_36_2:getContentSize().width, var_36_2:getContentSize().height)
		var_36_1:addContent(var_36_3)

		return var_36_1
	end
end

function var_0_0.itemPosDelegate(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	local var_37_0 = math.ceil(#arg_37_0.posItems_ / var_0_9)

	if cc.ui.UIListView.COUNT_TAG == arg_37_2 then
		return var_37_0
	elseif cc.ui.UIListView.CELL_TAG == arg_37_2 then
		if var_37_0 < arg_37_3 then
			return nil
		end

		local var_37_1 = arg_37_0.listItemPos:dequeueItem()

		if not var_37_1 then
			var_37_1 = arg_37_0.listItemPos:newItem()
		else
			var_37_1:removeAllChildren(true)
		end

		local var_37_2 = display.newNode()

		arg_37_0:initCell(var_37_2, arg_37_3, var_0_12.POS)

		local var_37_3 = display.newNode()

		var_37_3:addChild(var_37_2)
		var_37_3:setContentSize(var_37_2:getContentSize())
		var_37_1:setItemSize(var_37_2:getContentSize().width, var_37_2:getContentSize().height)
		var_37_1:addContent(var_37_3)

		return var_37_1
	end
end

function var_0_0.initCell(arg_38_0, arg_38_1, arg_38_2, arg_38_3)
	for iter_38_0 = 1, var_0_9 do
		local var_38_0 = (arg_38_2 - 1) * var_0_9 + iter_38_0
		local var_38_1

		if arg_38_3 == var_0_12.TYPE then
			var_38_1 = arg_38_0.typeItems_
		elseif arg_38_3 == var_0_12.POS then
			var_38_1 = arg_38_0.posItems_
		end

		if var_38_0 > #var_38_1 then
			break
		end

		local var_38_2 = var_38_1[var_38_0]
		local var_38_3 = display.newNode()

		var_38_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_38_3:setContentSize(var_0_10, var_0_10)

		local var_38_4 = {
			container = var_38_3,
			item = var_38_2
		}

		xyd.setHunqiBorder(var_38_4)
		var_38_3:setTouchEnabled(true)
		var_38_3:setTouchSwallowEnabled(false)
		var_38_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
			if arg_39_0.name == "began" then
				var_38_3:setScale(0.9)
			elseif arg_39_0.name == "moved" then
				if not arg_38_0.scrollViewMoved_ then
					var_38_3:setScale(1)
				end
			elseif arg_39_0.name == "ended" then
				var_38_3:setScale(1)

				if not arg_38_0.scrollViewMoved_ then
					xyd.playButtonSound()

					if arg_38_0.selectNode and not tolua.isnull(arg_38_0.selectNode) then
						arg_38_0.selectNode:removeChildByName("selected")
					end

					local var_39_0 = xyd.AssetLoader.get():loadSprite("windows/hunqi/selected.png")

					var_39_0:addTo(var_38_3, 1)
					var_39_0:setPosition(var_0_10 / 2, var_0_10 / 2)
					var_39_0:setName("selected")

					arg_38_0.selectIndex = var_38_0
					arg_38_0.selectNode = var_38_3

					arg_38_0:performWithDelay(function()
						local var_40_0 = {
							item1 = var_38_2
						}
						local var_40_1 = {}

						var_40_1.showStrenthen = true
						var_40_1.rightBtnType = var_0_17.EQUIP
						var_40_1.relateIcon = var_38_3
						var_40_0.itemParams1 = var_40_1

						local var_40_2 = arg_38_0.heros_[arg_38_0.current_]

						var_40_0.hero = var_40_2

						local var_40_3 = xyd.tables.spiritEquip:modelId(var_38_2.table_id)
						local var_40_4 = xyd.tables.spirit:pos(var_40_3)
						local var_40_5 = var_40_2:getSpiritEquips()[var_40_4]

						if var_40_5 ~= 0 then
							var_40_0.item2 = arg_38_0.backpack:getSpiritItemBySpiritID(var_40_5)

							local var_40_6 = {}

							var_40_6.showStrenthen = true
							var_40_6.showActive = true
							var_40_0.itemParams2 = var_40_6
						end

						local var_40_7 = xyd.WindowManager.get():openWindow("hunqi_detail", var_40_0)

						var_40_7:setPosition(610, xyd.STAGE_HEIGHT - var_40_7:getTipHeight() - 100)
					end, 0.03333333333333333)
				end
			end

			return true
		end)

		if arg_38_0.selectIndex == var_38_0 then
			arg_38_0.selectNode = var_38_3

			local var_38_5 = xyd.AssetLoader.get():loadSprite("windows/hunqi/selected.png")

			var_38_5:addTo(var_38_3)
			var_38_5:setPosition(var_0_10 / 2, var_0_10 / 2)
			var_38_5:setName("selected")
		end

		var_38_3:addTo(arg_38_1)
		var_38_3:setPosition((iter_38_0 - 1) * (var_0_10 + 20) + var_0_10 / 2, 16 + var_0_10 / 2)
	end

	arg_38_1:setContentSize(arg_38_0:nodeByName("list_item_pos"):getWidth() + 10, var_0_10 + 16)
end

function var_0_0.refreshTypeBlockList(arg_41_0)
	arg_41_0.blockTextNum = {}

	arg_41_0.listTypeBlock:removeAllItems()

	local var_41_0 = table.nums(arg_41_0.typeAllItems_)
	local var_41_1 = table.keys(arg_41_0.typeAllItems_)
	local var_41_2 = math.ceil(var_41_0 / 2)

	for iter_41_0 = 1, var_41_2 do
		local var_41_3 = display.newNode()
		local var_41_4 = 500
		local var_41_5 = 127

		var_41_3:setContentSize(var_41_4, var_41_5)

		local var_41_6 = arg_41_0.listTypeBlock:newItem()

		for iter_41_1 = 1, 2 do
			local var_41_7 = (iter_41_0 - 1) * 2 + iter_41_1

			if var_41_0 < var_41_7 then
				break
			end

			local var_41_8 = var_41_1[var_41_7]
			local var_41_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/block.csb")
			local var_41_10 = var_41_9:getChildByName("container")
			local var_41_11 = xyd.SpriteLoader.new("images/hunqi/icon/" .. var_41_8 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

			xyd.displaySpriteOnContainer(var_41_11, var_41_10:getChildByName("icon"), false)
			var_41_10:getChildByName("name"):setString(var_0_2:name(var_41_8))
			var_41_10:getChildByName("desc"):setString(xyd.tables.attr:name(var_0_2:attr2(var_41_8)))
			var_41_10:getChildByName("text_num"):enableOutline(cc.c4b(155, 71, 97, 255), 2)

			local var_41_12 = 0

			if arg_41_0.posState then
				var_41_12 = #arg_41_0.typeAllItems_[var_41_8][arg_41_0.posState]
			else
				for iter_41_2 = 1, 6 do
					var_41_12 = var_41_12 + #arg_41_0.typeAllItems_[var_41_8][iter_41_2]
				end
			end

			var_41_10:getChildByName("text_num"):setString(var_41_12)
			table.insert(arg_41_0.blockTextNum, var_41_10:getChildByName("text_num"))
			var_41_9:addTo(var_41_3)
			var_41_9:setAnchorPoint(cc.p(0, 0))
			var_41_9:setPosition((iter_41_1 - 1) * 255 + 2, 2)
			var_41_9:setTouchEnabled(true)
			var_41_9:setTouchSwallowEnabled(false)
			var_41_9:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
				if arg_42_0.name == "began" then
					var_41_10:setScale(0.9)
				elseif arg_42_0.name == "moved" then
					if not arg_41_0.scrollViewMoved_ then
						var_41_10:setScale(1)
					end
				elseif arg_42_0.name == "ended" then
					var_41_10:setScale(1)

					if not arg_41_0.scrollViewMoved_ then
						xyd.playButtonSound()

						arg_41_0.showType = var_0_12.TYPE
						arg_41_0.typeState = var_41_8

						arg_41_0:updateList()
					end
				end

				return true
			end)
		end

		var_41_6:addContent(var_41_3)
		var_41_6:setItemSize(var_41_4, var_41_5)
		arg_41_0.listTypeBlock:addItem(var_41_6)
	end

	arg_41_0.listTypeBlock:reload()
end

function var_0_0.setSelectEquipNode(arg_43_0, arg_43_1)
	for iter_43_0 = 1, 6 do
		arg_43_0:nodeByName("node_item_" .. iter_43_0):getChildByName("choose"):setVisible(false)
	end

	if arg_43_1 then
		arg_43_0:nodeByName("node_item_" .. arg_43_1):getChildByName("choose"):setVisible(true)
	end
end

function var_0_0.refreshTypeLongBlockList(arg_44_0)
	arg_44_0.longBlockTextNum = {}

	arg_44_0.listTypeLongBlock:removeAllItems()

	local var_44_0 = table.nums(arg_44_0.typeAllItems_)
	local var_44_1 = table.keys(arg_44_0.typeAllItems_)

	for iter_44_0 = 1, var_44_0 do
		local var_44_2 = var_44_1[iter_44_0]
		local var_44_3 = display.newNode()
		local var_44_4 = arg_44_0.listTypeLongBlock:newItem()
		local var_44_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hunqi/block_long.csb")
		local var_44_6 = var_44_5:getChildByName("container")
		local var_44_7 = xyd.SpriteLoader.new("images/hunqi/icon/" .. var_44_2 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

		xyd.displaySpriteOnContainer(var_44_7, var_44_6:getChildByName("icon"), false)
		var_44_6:getChildByName("name"):enableOutline(cc.c4b(61, 61, 61, 255), 1)
		var_44_6:getChildByName("name"):setString(var_0_2:name(var_44_2))
		var_44_6:getChildByName("text_num"):enableOutline(cc.c4b(155, 71, 97, 255), 2)

		local var_44_8 = 0

		if arg_44_0.posState then
			var_44_8 = #arg_44_0.typeAllItems_[var_44_2][arg_44_0.posState]
		else
			for iter_44_1 = 1, 6 do
				var_44_8 = var_44_8 + #arg_44_0.typeAllItems_[var_44_2][iter_44_1]
			end
		end

		var_44_6:getChildByName("text_num"):setString(var_44_8)
		table.insert(arg_44_0.longBlockTextNum, var_44_6:getChildByName("text_num"))

		local var_44_9 = {
			size = 16,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c4b(106, 105, 119, 255),
			dimensions = cc.size(320, 0)
		}
		local var_44_10 = xyd.AssetLoader.get():loadLabel(var_44_9)
		local var_44_11, var_44_12 = var_0_2:attr2Value(var_44_2)

		if var_44_12 then
			var_44_11 = var_44_11 / 100 .. "%"
		end

		var_44_10:setString(xyd.tables.attr:name(var_0_2:attr2(var_44_2)) .. var_44_11)
		var_44_10:setAnchorPoint(cc.p(0, 1))
		var_44_10:addTo(var_44_6:getChildByName("node_word"))
		var_44_10:setPositionY(10)

		local var_44_13 = {
			size = 16,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c4b(106, 105, 119, 255),
			dimensions = cc.size(320, 0)
		}
		local var_44_14 = xyd.AssetLoader.get():loadLabel(var_44_13)

		var_44_14:setString(var_0_2:attr4Desc(var_44_2))
		var_44_14:setAnchorPoint(cc.p(0, 1))
		var_44_14:addTo(var_44_6:getChildByName("node_word"))
		var_44_14:setPositionY(-16)
		var_44_5:addTo(var_44_3)
		var_44_5:setAnchorPoint(cc.p(0, 0))
		var_44_5:setPosition(0, 5)
		var_44_5:setTouchEnabled(true)
		var_44_5:setTouchSwallowEnabled(false)
		var_44_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
			if arg_45_0.name == "began" then
				var_44_6:setScale(0.9)
			elseif arg_45_0.name == "moved" then
				if not arg_44_0.scrollViewMoved_ then
					var_44_6:setScale(1)
				end
			elseif arg_45_0.name == "ended" then
				var_44_6:setScale(1)

				if not arg_44_0.scrollViewMoved_ then
					xyd.playButtonSound()

					arg_44_0.showType = var_0_12.TYPE
					arg_44_0.typeState = var_44_2

					arg_44_0:updateList()
				end
			end

			return true
		end)
		var_44_3:setContentSize(var_44_6:getWidth(), var_44_6:getHeight())
		var_44_4:addContent(var_44_3)
		var_44_4:setItemSize(var_44_6:getWidth(), var_44_6:getHeight() + 5)
		arg_44_0.listTypeLongBlock:addItem(var_44_4)
	end

	arg_44_0.listTypeLongBlock:reload()
end

function var_0_0.updateList(arg_46_0)
	if arg_46_0.showType == var_0_12.TYPE then
		arg_46_0:updateTypeList()
	elseif arg_46_0.showType == var_0_12.POS then
		arg_46_0:updatePosList()
	end

	arg_46_0:updateShow()
end

function var_0_0.updatePosList(arg_47_0)
	arg_47_0.posItems_ = arg_47_0.posAllItems_[arg_47_0.posState]
	arg_47_0.selectIndex = nil
	arg_47_0.selectItem = nil

	arg_47_0:sortItems(arg_47_0.posItems_, arg_47_0.sortTypePos)
	arg_47_0.listItemPos:reload()
end

function var_0_0.updateTypeList(arg_48_0)
	arg_48_0.typeItems_ = {}

	local var_48_0 = arg_48_0.typeState

	if not arg_48_0.posState then
		local var_48_1 = arg_48_0.typeAllItems_[var_48_0]

		if var_48_1 and next(var_48_1) then
			for iter_48_0, iter_48_1 in ipairs(var_48_1) do
				if iter_48_1 and next(iter_48_1) then
					for iter_48_2, iter_48_3 in ipairs(iter_48_1) do
						table.insert(arg_48_0.typeItems_, iter_48_3)
					end
				end
			end
		end
	else
		arg_48_0.typeItems_ = arg_48_0.typeAllItems_[var_48_0][arg_48_0.posState]
	end

	arg_48_0:sortItems(arg_48_0.typeItems_, arg_48_0.sortTypeType)
	arg_48_0.listItemType:reload()
end

function var_0_0.sortItems(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = {}

	table.insert(var_49_0, arg_49_2)

	for iter_49_0 = 1, var_0_15 do
		if arg_49_2 ~= iter_49_0 then
			table.insert(var_49_0, iter_49_0)
		end
	end

	local function var_49_1(arg_50_0, arg_50_1)
		if not arg_50_0 and not arg_50_1 then
			return 3
		elseif arg_50_0 and not arg_50_1 then
			return 1
		elseif not arg_50_0 and arg_50_1 then
			return 2
		elseif arg_50_1 < arg_50_0 then
			return 1
		elseif arg_50_0 < arg_50_1 then
			return 2
		else
			return 3
		end
	end

	local function var_49_2(arg_51_0, arg_51_1, arg_51_2)
		if arg_51_2 == var_0_14.LEV then
			return var_49_1(arg_51_0.lev, arg_51_1.lev)
		elseif arg_51_2 == var_0_14.QUALITY then
			return var_49_1(arg_51_0.star, arg_51_1.star)
		elseif arg_51_2 == var_0_14.GET_TIME then
			return var_49_1(arg_51_0.spirit_id, arg_51_1.spirit_id)
		else
			local var_51_0

			if arg_51_2 == var_0_14.HP then
				var_51_0 = xyd.AttributeType.HP
			elseif arg_51_2 == var_0_14.AD then
				var_51_0 = xyd.AttributeType.AD
			elseif arg_51_2 == var_0_14.AP then
				var_51_0 = xyd.AttributeType.AP
			elseif arg_51_2 == var_0_14.HUJIA then
				var_51_0 = xyd.AttributeType.HUJIA
			elseif arg_51_2 == var_0_14.MOKANG then
				var_51_0 = xyd.AttributeType.MOKANG
			elseif arg_51_2 == var_0_14.BAOJI_RATE then
				var_51_0 = xyd.AttributeType.BAOJI_RATE
			elseif arg_51_2 == var_0_14.BAOJIHARM then
				var_51_0 = xyd.AttributeType.BAOJIHARM
			elseif arg_51_2 == var_0_14.ZHUANGTAI_KANGXING then
				var_51_0 = xyd.AttributeType.ZHUANGTAI_KANGXING
			elseif arg_51_2 == var_0_14.ZHUANGTAI_MINGZHONG then
				var_51_0 = xyd.AttributeType.ZHUANGTAI_MINGZHONG
			elseif arg_51_2 == var_0_14.HUNQI_HP_BONUS then
				var_51_0 = xyd.AttributeType.HUNQI_HP_BONUS
			elseif arg_51_2 == var_0_14.HUNQI_AD_AP_BONUS then
				var_51_0 = xyd.AttributeType.HUNQI_AD_AP_BONUS
			elseif arg_51_2 == var_0_14.HUNQI_JIAKANG_BONUS then
				var_51_0 = xyd.AttributeType.HUNQI_JIAKANG_BONUS
			end

			local var_51_1
			local var_51_2
			local var_51_3 = arg_51_0.main_attr ~= var_51_0 and 0 or arg_51_0.main_attr_value
			local var_51_4 = arg_51_1.main_attr ~= var_51_0 and 0 or arg_51_0.main_attr_value

			return var_49_1(var_51_3, var_51_4)
		end
	end

	table.sort(arg_49_1, function(arg_52_0, arg_52_1)
		for iter_52_0, iter_52_1 in ipairs(var_49_0) do
			local var_52_0 = var_49_2(arg_52_0, arg_52_1, iter_52_1)

			if var_52_0 == 1 then
				return true
			elseif var_52_0 == 2 then
				return false
			end
		end

		return false
	end)
end

function var_0_0.updateAllItems(arg_53_0)
	arg_53_0:initUnequipItem()
	arg_53_0:updateList()
	arg_53_0:updateHero()
	arg_53_0:refreshTypeBlockList()
	arg_53_0:refreshTypeLongBlockList()
	arg_53_0:nodeByName("text_num"):setString(string.format(var_0_1:translation("HUNQI_TEXT_3"), arg_53_0.backpack:getSpiritNum(), xyd.tables.misc:getValue("spirit_num_limit")))
end

function var_0_0.updateBlockShowNum(arg_54_0)
	local var_54_0 = table.keys(arg_54_0.typeAllItems_)

	for iter_54_0, iter_54_1 in ipairs(var_54_0) do
		local var_54_1 = 0

		if arg_54_0.posState then
			var_54_1 = #arg_54_0.typeAllItems_[iter_54_1][arg_54_0.posState]
		else
			for iter_54_2 = 1, 6 do
				var_54_1 = var_54_1 + #arg_54_0.typeAllItems_[iter_54_1][iter_54_2]
			end
		end

		arg_54_0.blockTextNum[iter_54_0]:setString(var_54_1)
		arg_54_0.longBlockTextNum[iter_54_0]:setString(var_54_1)
	end
end

return var_0_0
