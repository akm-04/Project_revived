local var_0_0 = class("LabWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("framework.scheduler")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.members = {
		0,
		0,
		0,
		0,
		0
	}
	arg_1_0.cells = {}
	arg_1_0.rightButtons = {}
	arg_1_0.heros = clone(arg_1_0.selfPlayer.heros_)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.percentAD = 0
	arg_1_0.percentAP = 0
	arg_1_0.percentDEX = 0

	if arg_1_2.deskInfo then
		arg_1_0.deskInfo = arg_1_2.deskInfo
	end

	arg_1_0.busyHeros = arg_1_2.busyheros
end

function var_0_0.filtCanSentHeros(arg_2_0)
	for iter_2_0 = 1, #arg_2_0.busyHeros do
		for iter_2_1, iter_2_2 in ipairs(arg_2_0.heros) do
			if iter_2_2:getHeroID() == arg_2_0.busyHeros[iter_2_0] then
				local var_2_0 = true
				local var_2_1 = arg_2_0.deskInfo.magic_stone_config.formation
				local var_2_2 = xyd.splitToNumber(var_2_1, "|")

				if var_2_2 then
					for iter_2_3 = 1, #var_2_2 do
						if var_2_2[iter_2_3] == arg_2_0.busyHeros[iter_2_0] then
							var_2_0 = false
						end
					end
				end

				if var_2_0 then
					table.remove(arg_2_0.heros, iter_2_1)
				end

				break
			end
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:filtCanSentHeros()

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.heros) do
		iter_3_1.ad = iter_3_1:getTotalAttr(1)
		iter_3_1.ap = iter_3_1:getTotalAttr(2)
		iter_3_1.dex = iter_3_1:getTotalAttr(3)
	end
end

function var_0_0.registerMembers(arg_4_0)
	for iter_4_0 = 1, 5 do
		arg_4_0:nodeByName("member" .. iter_4_0 .. "_copy"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_4_0:cancelMember(arg_4_0.members[iter_4_0])
				arg_4_0:updateInfos()
			end
		end)
	end
end

function var_0_0.registerRightMenu(arg_6_0)
	arg_6_0.rightButtons[1] = arg_6_0:nodeByName("button_ad")

	arg_6_0.rightButtons[1]:setBrightStyle(ccui.BrightStyle.highlight)

	arg_6_0.rightButtons[3] = arg_6_0:nodeByName("button_dex")
	arg_6_0.rightButtons[2] = arg_6_0:nodeByName("button_ap")

	for iter_6_0 = 1, 3 do
		arg_6_0.rightButtons[iter_6_0]:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				arg_6_0:sortHeros(iter_6_0)
				arg_6_0.herolist:reload()

				for iter_7_0 = 1, 3 do
					if arg_6_0.rightButtons[iter_7_0] == arg_7_0 then
						arg_6_0.rightButtons[iter_7_0]:setBrightStyle(ccui.BrightStyle.highlight)
					else
						arg_6_0.rightButtons[iter_7_0]:setBrightStyle(ccui.BrightStyle.normal)
					end
				end
			end
		end)
	end
end

function var_0_0.registerConfirmButton(arg_8_0)
	arg_8_0:nodeByName("confirm_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				str = arg_8_0.percentAD,
				int = arg_8_0.percentAP,
				agi = arg_8_0.percentDEX
			}

			var_9_0.formation = ""

			for iter_9_0 = 1, 5 do
				if arg_8_0.members[iter_9_0] ~= 0 then
					var_9_0.formation = var_9_0.formation .. arg_8_0.heros[arg_8_0.members[iter_9_0]]:getHeroID()

					if iter_9_0 < 5 and arg_8_0.members[iter_9_0 + 1] ~= 0 then
						var_9_0.formation = var_9_0.formation .. "|"
					end
				end
			end

			arg_8_0.eventCentre:confirmTeamForMakeItem(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					arg_8_0.deskInfo.make_need_time = arg_10_1.make_need_time
					arg_8_0.deskInfo.magic_stone_config.str = arg_8_0.percentAD
					arg_8_0.deskInfo.magic_stone_config.int = arg_8_0.percentAP
					arg_8_0.deskInfo.magic_stone_config.agi = arg_8_0.percentDEX
					arg_8_0.deskInfo.magic_stone_config.formation = var_9_0.formation

					if xyd.WindowManager.get():getWindow("production_table") then
						xyd.WindowManager.get():getWindow("production_table").deskInfo = arg_8_0.deskInfo

						xyd.WindowManager.get():getWindow("production_table"):update()
					end

					xyd.WindowManager.get():closeWindow(arg_8_0)
				end
			end)
		end
	end)
end

function var_0_0.registerRuleButton(arg_11_0)
	arg_11_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("text_rule", {
				title_name = "EVENT_CENTRE_TABLE_RULE_TITLE",
				rule = "EVENT_CENTRE_TABLE_RULE",
				split = "|"
			})
		end
	end)
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	arg_13_0:sortHeros(1)

	local var_13_0 = arg_13_0.deskInfo.magic_stone_config.formation
	local var_13_1 = xyd.splitToNumber(var_13_0, "|")

	if var_13_1 then
		for iter_13_0 = 1, #var_13_1 do
			for iter_13_1 = 1, #arg_13_0.heros do
				if arg_13_0.heros[iter_13_1]:getHeroID() == var_13_1[iter_13_0] then
					arg_13_0.members[iter_13_0] = iter_13_1

					arg_13_0:nodeByName("member" .. iter_13_0 .. "_copy"):removeAllChildren()
					xyd.setAvatarBorderWithLevelAndHp(arg_13_0.heros[iter_13_1], arg_13_0:nodeByName("member" .. iter_13_0 .. "_copy"))
					arg_13_0:nodeByName("member" .. iter_13_0 .. "_copy"):setVisible(true)
				end
			end
		end
	end

	arg_13_0:layout()
	arg_13_0.herolist:setDelegate(handler(arg_13_0, arg_13_0.heroListDelegate))
	arg_13_0.herolist:reload()
end

function var_0_0.registerListeners(arg_14_0)
	arg_14_0:registerMembers()
	arg_14_0:registerConfirmButton()
	arg_14_0:registerRuleButton()
	arg_14_0:registerRightMenu()
end

function var_0_0.initHeroList(arg_15_0, ...)
	arg_15_0.herolist = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, 600, 350),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_15_0:nodeByName("hero_list")):align(display.BOTTOM_CENTER, 0, 0):onScroll(handler(arg_15_0, arg_15_0.heroScrollListener)):pos(0, 0)
end

function var_0_0.updateInfos(arg_16_0)
	arg_16_0.percentAD = 0
	arg_16_0.percentAP = 0
	arg_16_0.percentDEX = 0

	for iter_16_0 = 1, 5 do
		if arg_16_0.members[iter_16_0] ~= 0 then
			arg_16_0.percentAD = arg_16_0.percentAD + arg_16_0.heros[arg_16_0.members[iter_16_0]].ad
			arg_16_0.percentDEX = arg_16_0.percentDEX + arg_16_0.heros[arg_16_0.members[iter_16_0]].dex
			arg_16_0.percentAP = arg_16_0.percentAP + arg_16_0.heros[arg_16_0.members[iter_16_0]].ap
		end
	end

	arg_16_0:nodeByName("hp_ad"):setPercent(arg_16_0.percentAD / 200)
	arg_16_0:nodeByName("hp_ap"):setPercent(arg_16_0.percentAP / 200)
	arg_16_0:nodeByName("hp_dex"):setPercent(arg_16_0.percentDEX / 200)

	if arg_16_0.members[1] == 0 or arg_16_0.deskInfo.making_item and arg_16_0.deskInfo.making_item == 0 then
		arg_16_0:nodeByName("item_icon"):setVisible(false)
		arg_16_0:nodeByName("item_num"):setVisible(false)
		arg_16_0:nodeByName("magic_stone_num"):setVisible(false)
		arg_16_0:nodeByName("time_txt"):setVisible(false)
		arg_16_0:nodeByName("magic_stone_icon"):setVisible(false)
		arg_16_0:nodeByName("clock"):setVisible(false)
	else
		arg_16_0:nodeByName("item_icon"):setVisible(true)
		xyd.setItemBorder(arg_16_0:nodeByName("item_icon"), var_0_5:compose(arg_16_0.deskInfo.making_item, 1))
		arg_16_0:nodeByName("item_num"):setVisible(true)

		local var_16_0 = tonumber(xyd.tables.misc.event_centre_stone_strength)
		local var_16_1 = tonumber(xyd.tables.misc.event_centre_stone_strength_conrrection)
		local var_16_2 = math.floor(var_16_0 * arg_16_0.percentAD * arg_16_0.percentAD + var_16_1 * arg_16_0.percentAD + 0.5)
		local var_16_3 = math.ceil(var_16_0 * arg_16_0.percentAD * arg_16_0.percentAD + var_16_1 * arg_16_0.percentAD)

		arg_16_0:nodeByName("item_num"):setString(string.format(var_0_1:translation("LAB_ITEM_NUM"), var_16_2, var_16_3))
		arg_16_0:nodeByName("magic_stone_icon"):setVisible(true)
		arg_16_0:nodeByName("magic_stone_num"):setVisible(true)

		local var_16_4 = tonumber(xyd.tables.misc.event_centre_stone_intelligence_upper)
		local var_16_5 = tonumber(xyd.tables.misc.event_centre_stone_intelligence_upper_conrrection)
		local var_16_6 = tonumber(xyd.tables.misc.event_centre_stone_intelligence_low)
		local var_16_7 = tonumber(xyd.tables.misc.event_centre_stone_intelligence_low_conrrection)
		local var_16_8 = math.ceil(var_16_4 * arg_16_0.percentAP * arg_16_0.percentAP + var_16_5 * arg_16_0.percentAP)
		local var_16_9 = math.ceil(var_16_6 * arg_16_0.percentAP * arg_16_0.percentAP + var_16_7 * arg_16_0.percentAP)

		arg_16_0:nodeByName("magic_stone_num"):setString(string.format(var_0_1:translation("LAB_ITEM_NUM"), var_16_9, var_16_8))
		arg_16_0:nodeByName("clock"):setVisible(true)
		arg_16_0:nodeByName("time_txt"):setVisible(true)

		local var_16_10 = tonumber(xyd.tables.misc.event_centre_stone_agility)
		local var_16_11 = tonumber(xyd.tables.misc.event_centre_stone_agility_conrrection)

		arg_16_0:nodeByName("time_txt"):setString(string.format(var_0_1:translation("LAB_TIME_TXT"), (math.ceil(var_16_10 * arg_16_0.percentDEX * arg_16_0.percentDEX + var_16_11 * arg_16_0.percentDEX))))
	end
end

function var_0_0.heroListDelegate(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	local var_17_0 = math.ceil(#arg_17_0.heros / 5)

	if cc.ui.UIListView.COUNT_TAG == arg_17_2 then
		return math.ceil(#arg_17_0.heros / 5)
	elseif cc.ui.UIListView.CELL_TAG == arg_17_2 then
		local var_17_1
		local var_17_2
		local var_17_3
		local var_17_4 = arg_17_0.herolist:dequeueItem()

		if not var_17_4 then
			var_17_4 = arg_17_0.herolist:newItem()
		else
			var_17_4:removeAllChildren()
		end

		local var_17_5 = display.newNode()

		var_17_5:setTouchSwallowEnabled(false)

		for iter_17_0 = 1, 5 do
			local var_17_6 = (arg_17_3 - 1) * 5 + iter_17_0

			if var_17_6 > #arg_17_0.heros then
				break
			end

			local var_17_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar_ecb_pro.csb")

			arg_17_0.cells[var_17_6] = var_17_7

			var_17_7:setTouchSwallowEnabled(false)

			local var_17_8 = var_17_7:getChildByName("background")

			var_17_7:addTo(var_17_5)
			var_17_7:setPosition((iter_17_0 - 1) * var_17_8:getChildByName("avatar"):getWidth(), 0)
			xyd.setAvatarBorder(arg_17_0.heros[var_17_6], var_17_8:getChildByName("avatar"))

			local var_17_9 = var_17_8:getChildByName("chosen")
			local var_17_10 = var_17_8:getChildByName("recommended")

			var_17_9:setLocalZOrder(100)
			var_17_9:setVisible(false)

			local var_17_11 = var_17_8:getChildByName("avatar_mask")

			var_17_11:setLocalZOrder(2)
			var_17_11:setVisible(false)
			var_17_8:setScale(0.8)
			var_17_8:getChildByName("lv_txt"):setString(arg_17_0.heros[var_17_6]:getLevel())

			local var_17_12 = var_17_8:getChildByName("hp_bg1"):getChildByName("hp_ad")
			local var_17_13 = var_17_8:getChildByName("hp_bg2"):getChildByName("hp_dex")
			local var_17_14 = var_17_8:getChildByName("hp_bg3"):getChildByName("hp_ap")

			var_17_12:setScaleX(0.7345679012345679)
			var_17_12:setScaleY(0.2727272727272727)
			var_17_12:setPercent(arg_17_0.heros[var_17_6].ad / 40)
			var_17_13:setScaleX(0.7345679012345679)
			var_17_13:setScaleY(0.2727272727272727)
			var_17_13:setPercent(arg_17_0.heros[var_17_6].dex / 40)
			var_17_14:setScaleX(0.7345679012345679)
			var_17_14:setScaleY(0.2727272727272727)
			var_17_14:setPercent(arg_17_0.heros[var_17_6].ap / 40)

			for iter_17_1 = 1, 5 do
				if arg_17_0.heros[var_17_6] == arg_17_0.heros[arg_17_0.members[iter_17_1]] then
					var_17_8:getChildByName("chosen"):setVisible(true)
					var_17_8:getChildByName("avatar_mask"):setVisible(true)
				end
			end

			var_17_7:setTouchEnabled(true)
			var_17_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
				if arg_18_0.name == "began" then
					var_17_8:setScale(0.7)

					return true
				elseif arg_18_0.name == "ended" then
					var_17_8:setScale(0.8)

					if not arg_17_0.scrollViewMoved_ then
						if not var_17_8:getChildByName("chosen"):isVisible() and arg_17_0.members[5] == 0 then
							var_17_8:getChildByName("chosen"):setVisible(true)
							var_17_8:getChildByName("avatar_mask"):setVisible(true)

							for iter_18_0 = 1, 5 do
								if arg_17_0.members[iter_18_0] == 0 then
									arg_17_0:nodeByName("member" .. iter_18_0 .. "_copy"):removeAllChildren()
									xyd.setAvatarBorderWithLevelAndHp(arg_17_0.heros[var_17_6], arg_17_0:nodeByName("member" .. iter_18_0 .. "_copy"))
									arg_17_0:nodeByName("member" .. iter_18_0 .. "_copy"):setVisible(true)

									arg_17_0.members[iter_18_0] = var_17_6

									break
								end
							end

							arg_17_0:updateInfos()
						else
							for iter_18_1 = 1, 5 do
								if arg_17_0.members[iter_18_1] == var_17_6 then
									arg_17_0:cancelMember(var_17_6)
									arg_17_0:updateInfos()
								end
							end
						end
					end
				end

				return true
			end)
		end

		var_17_5:setAnchorPoint(cc.p(0, 0))
		var_17_5:setPosition(0, 0)
		var_17_5:setContentSize(540, 135)
		var_17_4:addContent(var_17_5)
		var_17_4:setItemSize(540, 135)

		return var_17_4
	end
end

function var_0_0.heroScrollListener(arg_19_0, arg_19_1)
	if arg_19_1.name == "began" then
		arg_19_0.scrollViewMoved_ = false
		arg_19_0.prevY_ = arg_19_1.y
	elseif arg_19_1.name == "moved" and 10 <= math.abs(arg_19_1.y - arg_19_0.prevY_) then
		arg_19_0.scrollViewMoved_ = true
	end
end

function var_0_0.cancelMember(arg_20_0, arg_20_1)
	if not tolua.isnull(arg_20_0.cells[arg_20_1]) then
		arg_20_0.cells[arg_20_1]:getChildByName("background"):getChildByName("chosen"):setVisible(false)
		arg_20_0.cells[arg_20_1]:getChildByName("background"):getChildByName("avatar_mask"):setVisible(false)
	end

	for iter_20_0 = 1, 5 do
		if arg_20_0.members[iter_20_0] == arg_20_1 then
			arg_20_0.members[iter_20_0] = 0
		end
	end

	for iter_20_1 = 1, 5 do
		if arg_20_0.members[iter_20_1] == 0 and iter_20_1 ~= 5 then
			if arg_20_0.members[iter_20_1 + 1] ~= 0 then
				arg_20_0.members[iter_20_1] = arg_20_0.members[iter_20_1 + 1]

				arg_20_0:nodeByName("member" .. iter_20_1 .. "_copy"):removeAllChildren()
				xyd.setAvatarBorderWithLevelAndHp(arg_20_0.heros[arg_20_0.members[iter_20_1]], arg_20_0:nodeByName("member" .. iter_20_1 .. "_copy"))
				arg_20_0:nodeByName("member" .. iter_20_1 .. "_copy"):setVisible(true)
				arg_20_0:nodeByName("member" .. iter_20_1 + 1 .. "_copy"):setVisible(false)

				arg_20_0.members[iter_20_1 + 1] = 0
			elseif arg_20_0.members[iter_20_1 + 1] == 0 then
				arg_20_0:nodeByName("member" .. iter_20_1 .. "_copy"):setVisible(false)

				break
			end
		end
	end

	arg_20_0:nodeByName("member5_copy"):setVisible(false)
end

function var_0_0.updateItems(arg_21_0, ...)
	return
end

function var_0_0.sortHeros(arg_22_0, arg_22_1)
	local var_22_0 = {}

	for iter_22_0 = 1, 5 do
		if arg_22_0.members[iter_22_0] ~= 0 then
			var_22_0[iter_22_0] = arg_22_0.heros[arg_22_0.members[iter_22_0]]
		end
	end

	table.sort(arg_22_0.heros, function(arg_23_0, arg_23_1)
		if arg_22_1 == 1 then
			return arg_23_0.ad > arg_23_1.ad
		elseif arg_22_1 == 2 then
			return arg_23_0.ap > arg_23_1.ap
		elseif arg_22_1 == 3 then
			return arg_23_0.dex > arg_23_1.dex
		end
	end)

	for iter_22_1 = 1, #var_22_0 do
		arg_22_0.members[iter_22_1] = table.indexof(arg_22_0.heros, var_22_0[iter_22_1])
	end
end

function var_0_0.layout(arg_24_0)
	arg_24_0:nodeByName("ad_label"):setString(var_0_1:translation("TUJIAN_BUTTON_TEXT6"))
	arg_24_0:nodeByName("dex_label"):setString(var_0_1:translation("TUJIAN_BUTTON_TEXT7"))
	arg_24_0:nodeByName("ap_label"):setString(var_0_1:translation("TUJIAN_BUTTON_TEXT8"))
	arg_24_0:nodeByName("title_left"):setString(var_0_1:translation("LAB_TITLE_LEFT"))
	arg_24_0:nodeByName("title_right"):setString(var_0_1:translation("LAB_TITLE_RIGHT"))
	arg_24_0:updateInfos()
	arg_24_0:initHeroList()
	arg_24_0:registerListeners()
end

return var_0_0
