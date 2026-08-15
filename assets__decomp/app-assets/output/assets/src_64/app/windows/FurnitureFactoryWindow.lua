local var_0_0 = class("FurnitureFactoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.dormFurnitureItem
local var_0_6 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.btnState = xyd.FurnitureType.FURNITURE
	arg_1_0.listInfo = {}
	arg_1_0.index = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setButtonClick()
	arg_2_0:layout()
end

function var_0_0.setButtonClick(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("btn_add"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if var_4_0.glue >= xyd.tables.misc.glueBuyLimit then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("GLUE_LIMIT"))
				})
			elseif var_4_0.buyGlueTimes >= xyd.tables.vip:numGlue(var_4_0.vip) then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("BUY_GLUE_VIP_NOT_ENOUGH"))
				})
			else
				local var_4_1 = var_4_0.buyGlueTimes
				local var_4_2 = xyd.tables.refreshCost:buyGlueCost(var_4_1 + 1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_3:translation("GLUE_REFRESH"), xyd.tables.misc.glueBuyNumber, var_4_2),
					string.format(var_0_3:translation("GLUE_REFRESH_CONTINUE"), var_4_1)
				}, function()
					if arg_3_0.selfPlayer.crystal < var_4_2 then
						local var_5_0 = var_0_3:translation("ZUANSHI_ABSENCE")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
							local var_6_0 = {}

							var_6_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
						end, nil, nil, arg_3_0.colorMode)
					else
						xyd.Backend.get():request(xyd.mid.BUY_GLUE, arg_3_1, function(arg_7_0, arg_7_1)
							if arg_7_0 == xyd.error.OK then
								var_4_0:setBuyGlueTimes(arg_7_1.buy_glue_times)
								arg_3_0:nodeByName("glue_num"):setString(var_4_0.glue .. "/" .. xyd.tables.misc.glueBuyLimit)

								arg_3_0.buyGlueTimes = var_4_0.buyGlueTimes
							end
						end)
					end
				end, nil, 0, arg_3_0.colorMode)
			end
		end
	end)
	arg_3_0:nodeByName("btn_furniture"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.FurnitureType.FURNITURE

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0:updateBottomContainer()
			arg_3_0:addDialog()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_decoration"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.FurnitureType.DECORATION

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0:updateBottomContainer()
			arg_3_0:addDialog()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_electronic"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.FurnitureType.ELECTRONIC

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0:updateBottomContainer()
			arg_3_0:addDialog()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_fixture"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			arg_3_0.btnState = xyd.FurnitureType.FIXTURE

			arg_3_0:changeButtonState()
			arg_3_0:updateListInfo()
			arg_3_0:updateBottomContainer()
			arg_3_0:addDialog()
			arg_3_0.list:reload()
		end
	end)
	arg_3_0:nodeByName("btn_detail"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("backpack_item_detail_window", {
				itemID = var_0_4:compose(var_0_5:paper(arg_3_0.listInfo[arg_3_0.index]), 1)
			})
		end
	end)
	arg_3_0:nodeByName("btn_compose"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			arg_3_0.selfPlayer:makeItem({
				item_id = var_0_5:paper(arg_3_0.listInfo[arg_3_0.index])
			}, function(arg_14_0)
				if arg_14_0 == xyd.error.OK then
					arg_3_0.list:refreshList()
					arg_3_0:updateBottomContainer()
				end
			end)
		end
	end)
	arg_3_0:nodeByName("btn_storage"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("furniture_storage")
		end
	end)
	arg_3_0:nodeByName("btn_make"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			if arg_3_0.selfPlayer.glue < var_0_4:glue(arg_3_0.listInfo[arg_3_0.index]) then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("GLUE_NOT_ENOUGH"))
				})
			elseif arg_3_0:materialNotEnough() then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("FURNITURE_MATERIAL_NOT_ENOUGH"))
				})
			else
				local var_16_0 = {
					item = arg_3_0.listInfo[arg_3_0.index]
				}

				xyd.WindowManager.get():openWindow("produce_confirm", var_16_0)
			end
		end
	end)
	arg_3_0:nodeByName("glue_touch"):setTouchEnabled(true)
	arg_3_0:nodeByName("glue_touch"):setTouchSwallowEnabled(false)
	arg_3_0:nodeByName("glue_touch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "ended" then
			local var_17_0 = var_0_3:translation("GLUE_TIP")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_17_0
			})
		end

		return true
	end)
end

function var_0_0.materialNotEnough(arg_18_0)
	local var_18_0 = var_0_4:compose(arg_18_0.listInfo[arg_18_0.index])
	local var_18_1 = var_0_4:composeNum(arg_18_0.listInfo[arg_18_0.index])

	for iter_18_0, iter_18_1 in pairs(var_18_0) do
		if arg_18_0.selfPlayer:getBackpack():getItemNumByID(iter_18_1) < var_18_1[iter_18_0] then
			return true
		end
	end

	return false
end

function var_0_0.didOpen(arg_19_0, arg_19_1)
	return
end

function var_0_0.didClose(arg_20_0, arg_20_1)
	var_0_0.super:didClose(arg_20_1)
end

function var_0_0.layout(arg_21_0)
	arg_21_0:nodeByName("glue_num"):setString(arg_21_0.selfPlayer.glue .. "/" .. xyd.tables.misc.glueBuyLimit)

	local var_21_0 = arg_21_0:nodeByName("item_list")
	local var_21_1 = var_21_0:getContentSize()

	arg_21_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_21_1.width, var_21_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_21_0):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	arg_21_0.list:setDelegate(handler(arg_21_0, arg_21_0.delegate))
	arg_21_0:setButtonClick()
	arg_21_0:changeButtonState()
	arg_21_0:updateListInfo()
	arg_21_0:updateBottomContainer()
	arg_21_0:addDialog()
	arg_21_0.list:reload()
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevX_ = arg_22_1.x
		arg_22_0.prevY_ = arg_22_1.y
	elseif arg_22_1.name == "moved" then
		local var_22_0 = 3

		if var_22_0 <= math.abs(arg_22_1.y - arg_22_0.prevY_) or var_22_0 <= math.abs(arg_22_1.x - arg_22_0.prevX_) then
			arg_22_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.changeButtonState(arg_23_0)
	if arg_23_0.btnState == xyd.FurnitureType.FURNITURE then
		arg_23_0:nodeByName("btn_furniture"):setTouchEnabled(false)
		arg_23_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_23_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_23_0.btnState == xyd.FurnitureType.DECORATION then
		arg_23_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_decoration"):setTouchEnabled(false)
		arg_23_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_23_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_23_0.btnState == xyd.FurnitureType.ELECTRONIC then
		arg_23_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_electronic"):setTouchEnabled(false)
		arg_23_0:nodeByName("btn_fixture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_23_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_23_0.btnState == xyd.FurnitureType.FIXTURE then
		arg_23_0:nodeByName("btn_furniture"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_decoration"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_electronic"):setTouchEnabled(true)
		arg_23_0:nodeByName("btn_fixture"):setTouchEnabled(false)
		arg_23_0:nodeByName("btn_furniture"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_decoration"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_electronic"):setBrightStyle(ccui.BrightStyle.normal)
		arg_23_0:nodeByName("btn_fixture"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	arg_23_0.index = 1
end

function var_0_0.updateListInfo(arg_24_0)
	arg_24_0.listInfo = {}

	local var_24_0 = var_0_5:getIds()

	for iter_24_0, iter_24_1 in pairs(var_24_0) do
		if var_0_5:subtype(iter_24_1) == arg_24_0.btnState and var_0_5:paper(iter_24_1) ~= 0 and var_0_4:level(var_0_5:paper(iter_24_1)) <= arg_24_0.selfPlayer.lev then
			table.insert(arg_24_0.listInfo, iter_24_1)
		end
	end

	table.sort(arg_24_0.listInfo, function(arg_25_0, arg_25_1)
		if arg_25_0 == nil or arg_25_1 == nil then
			return false
		end

		if arg_24_0.selfPlayer:getBackpack():getItemNumByID(var_0_4:compose(var_0_5:paper(arg_25_1), 1)) >= var_0_4:composeNum(var_0_5:paper(arg_25_1), 1) then
			return false
		end

		if arg_24_0.selfPlayer:getBackpack():getItemNumByID(var_0_4:compose(var_0_5:paper(arg_25_0), 1)) >= var_0_4:composeNum(var_0_5:paper(arg_25_0), 1) then
			return true
		end

		return var_0_4:level(var_0_5:paper(arg_25_0)) < var_0_4:level(var_0_5:paper(arg_25_1))
	end)
end

function var_0_0.delegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return (math.ceil(#arg_26_0.listInfo / var_0_6))
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_0 = arg_26_0.list:dequeueItem()

		if not var_26_0 then
			var_26_0 = arg_26_0.list:newItem()
		else
			var_26_0:removeAllChildren(true)
		end

		local var_26_1 = 720
		local var_26_2 = 135

		var_26_0:setItemSize(var_26_1, var_26_2)

		local var_26_3 = display.newNode()

		var_26_3:setContentSize(var_26_1, 110)
		arg_26_0:initCell(var_26_3, arg_26_3)
		var_26_0:addContent(var_26_3)

		return var_26_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_26_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_27_0, arg_27_1, arg_27_2)
	for iter_27_0 = 1, var_0_6 do
		local var_27_0 = (arg_27_2 - 1) * var_0_6 + iter_27_0

		if var_27_0 > #arg_27_0.listInfo then
			break
		end

		local var_27_1 = display.newNode()

		var_27_1:setContentSize(110, 110)
		var_27_1:setPosition(145 * iter_27_0 - 70, 55)
		var_27_1:setAnchorPoint(0.5, 0.5)
		arg_27_1:addChild(var_27_1)
		var_27_1:setTouchEnabled(true)
		var_27_1:setTouchSwallowEnabled(false)

		if arg_27_0.selfPlayer:getBackpack():getItemNumByID(var_0_5:paper(arg_27_0.listInfo[var_27_0])) > 0 then
			xyd.setItemBorder(var_27_1, var_0_5:paper(arg_27_0.listInfo[var_27_0]))
		else
			xyd.setItemBorder(var_27_1, var_0_5:paper(arg_27_0.listInfo[var_27_0]), nil, true)

			local var_27_2

			if arg_27_0.selfPlayer:getBackpack():getItemNumByID(var_0_4:compose(var_0_5:paper(arg_27_0.listInfo[var_27_0]), 1)) >= var_0_4:composeNum(var_0_5:paper(arg_27_0.listInfo[var_27_0]), 1) then
				var_27_2 = {
					text = var_0_3:translation("CAN_MAKE_FURNITURE"),
					color = cc.c4b(255, 226, 53, 255)
				}
			else
				var_27_2 = {
					text = var_0_3:translation("NOT_HAVE_FURNITURE")
				}
			end

			local var_27_3 = xyd.AssetLoader:get():loadLabel(var_27_2)

			var_27_1:addChild(var_27_3)
			var_27_3:setAnchorPoint(cc.p(0.5, 0.5))
			var_27_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_27_3:setPosition(55, 85)
		end

		var_27_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
			if arg_28_0.name == "began" then
				var_27_1:setScale(0.9)

				return true
			elseif arg_28_0.name == "ended" then
				var_27_1:setScale(1)

				if not arg_27_0.scrollViewMoved_ then
					arg_27_0.index = var_27_0

					arg_27_0:updateBottomContainer()
					arg_27_0:addDialog()
				end
			end
		end)
	end
end

function var_0_0.updateBottomContainer(arg_29_0)
	if arg_29_0.selfPlayer:getBackpack():getItemNumByID(var_0_5:paper(arg_29_0.listInfo[arg_29_0.index])) > 0 then
		arg_29_0:nodeByName("compose_container"):setVisible(true)
		arg_29_0:nodeByName("piece_container"):setVisible(false)
		arg_29_0:nodeByName("material"):removeAllChildren()
		arg_29_0:nodeByName("compose_item"):removeAllChildren()
		xyd.setItemBorder(arg_29_0:nodeByName("compose_item"), arg_29_0.listInfo[arg_29_0.index])

		local var_29_0 = {}
		local var_29_1 = arg_29_0:nodeByName("compose_item"):getContentSize().height
		local var_29_2 = display.newNode()

		var_29_2:setContentSize(var_29_1, var_29_1)
		var_29_2:addTo(arg_29_0:nodeByName("compose_item"))
		var_29_2:setAnchorPoint(cc.p(0, 0))

		var_29_0.id = arg_29_0.listInfo[arg_29_0.index]
		var_29_0.lev = xyd.tables.item:level(arg_29_0.listInfo[arg_29_0.index])

		if xyd.tables.item:type(arg_29_0.listInfo[arg_29_0.index]) == -1 then
			var_29_0.tipsType = 0
			var_29_0.desc1 = xyd.tables.hero:getDes(arg_29_0.listInfo[arg_29_0.index])
		elseif specialItem then
			var_29_0.tipsType = 1
			var_29_0.id = -3
		else
			var_29_0.tipsType = 1
			var_29_0.desc1 = xyd.tables.item:desc1(arg_29_0.listInfo[arg_29_0.index])
			var_29_0.desc2 = xyd.tables.item:desc2(arg_29_0.listInfo[arg_29_0.index])
		end

		var_29_0.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_29_0.listInfo[arg_29_0.index])
		var_29_0.name = xyd.tables.item:name(arg_29_0.listInfo[arg_29_0.index])

		arg_29_0:addTips(var_29_2, var_29_0)
		arg_29_0:rewardLayer(arg_29_0:nodeByName("material"))
	else
		arg_29_0:nodeByName("compose_container"):setVisible(false)
		arg_29_0:nodeByName("piece_container"):setVisible(true)

		local var_29_3 = arg_29_0.selfPlayer:getBackpack():getItemNumByID(var_0_4:compose(var_0_5:paper(arg_29_0.listInfo[arg_29_0.index]), 1))
		local var_29_4 = var_0_4:composeNum(var_0_5:paper(arg_29_0.listInfo[arg_29_0.index]), 1)

		if var_29_4 <= var_29_3 then
			arg_29_0:nodeByName("pieceBar"):setPercent(100)
			arg_29_0:nodeByName("btn_detail"):setVisible(false)
			arg_29_0:nodeByName("btn_compose"):setVisible(true)
		else
			arg_29_0:nodeByName("pieceBar"):setPercent(var_29_3 / var_29_4 * 100)
			arg_29_0:nodeByName("btn_detail"):setVisible(true)
			arg_29_0:nodeByName("btn_compose"):setVisible(false)
		end

		arg_29_0:nodeByName("piece_num"):setString(var_29_3 .. "/" .. var_29_4)
		arg_29_0:nodeByName("piece_item"):removeAllChildren()
		xyd.setItemBorder(arg_29_0:nodeByName("piece_item"), var_0_4:compose(var_0_5:paper(arg_29_0.listInfo[arg_29_0.index]), 1))
	end
end

function var_0_0.addDialog(arg_30_0)
	local var_30_0 = arg_30_0:nodeByName("tips")

	var_30_0:removeAllChildren()

	local var_30_1 = {
		touchPosition = cc.p(0, 0),
		touchAreaSize = {
			width = 0,
			height = 0
		},
		times = {}
	}
	local var_30_2 = {}

	table.insert(var_30_2, string.format(var_0_3:translation("FURNITURE_COMPOSE_INFOMATION"), var_0_4:name(var_0_5:paper(arg_30_0.listInfo[arg_30_0.index])), var_0_4:name(arg_30_0.listInfo[arg_30_0.index]), var_0_5:comfort(arg_30_0.listInfo[arg_30_0.index]), var_0_4:glue(arg_30_0.listInfo[arg_30_0.index])))
	table.insert(var_30_1.times, 100)

	var_30_1.msgs = var_30_2
	arg_30_0.speakCellContent = import("app.windows.SpeakCell").new(var_30_1)

	arg_30_0.speakCellContent:addTo(var_30_0)
	arg_30_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_30_0.speakCellContent:setPosition(0, 0)
	arg_30_0.speakCellContent:onclick()
end

function var_0_0.rewardLayer(arg_31_0, arg_31_1)
	local var_31_0 = var_0_4:compose(arg_31_0.listInfo[arg_31_0.index])

	if #var_31_0 == 1 and var_31_0[1] == 0 then
		var_31_0 = {}
	end

	local var_31_1 = var_0_4:composeNum(arg_31_0.listInfo[arg_31_0.index])
	local var_31_2 = #var_31_1
	local var_31_3 = arg_31_1:getContentSize().height
	local var_31_4 = var_31_3 / 4 - 1
	local var_31_5 = 0

	if var_31_2 == 1 then
		var_31_5 = arg_31_1:getContentSize().width - var_31_2 * var_31_3
	else
		var_31_5 = (arg_31_1:getContentSize().width - var_31_2 * var_31_3 - (var_31_2 - 1) * var_31_4) / 2
	end

	local var_31_6 = #var_31_0

	for iter_31_0 = 1, #var_31_0 do
		if iter_31_0 > 1 then
			local var_31_7 = xyd.AssetLoader:get():loadSprite("windows/furniture_factory/plus2.png")

			var_31_7:addTo(arg_31_1)
			var_31_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_31_7:setPosition(var_31_5 + (iter_31_0 - 1) * (var_31_3 + var_31_4), var_31_3 / 2)
		end

		local var_31_8 = display.newNode()

		var_31_8:setContentSize(var_31_3, var_31_3)

		local var_31_9 = xyd.tables.item:type(var_31_0[iter_31_0])

		xyd.setItemBorder(var_31_8, var_31_0[iter_31_0], false, false, var_31_1[iter_31_0])
		var_31_8:addTo(arg_31_1)
		var_31_8:setAnchorPoint(cc.p(0, 0))

		if iter_31_0 > 1 then
			var_31_8:setPosition(var_31_5 + (iter_31_0 - 1) * (var_31_3 + var_31_4) + (iter_31_0 - 1) * 29, 0)
		else
			var_31_8:setPosition(var_31_5 + (iter_31_0 - 1) * (var_31_3 + var_31_4), 0)
		end

		local var_31_10 = {
			id = var_31_0[iter_31_0],
			lev = xyd.tables.item:level(var_31_0[iter_31_0])
		}

		if xyd.tables.item:type(var_31_0[iter_31_0]) == -1 then
			var_31_10.tipsType = 0
			var_31_10.desc1 = xyd.tables.hero:getDes(var_31_0[iter_31_0])
		elseif specialItem then
			var_31_10.tipsType = 1
			var_31_10.id = -3
		else
			var_31_10.tipsType = 1
			var_31_10.desc1 = xyd.tables.item:desc1(var_31_0[iter_31_0])
			var_31_10.desc2 = xyd.tables.item:desc2(var_31_0[iter_31_0])
		end

		var_31_10.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_31_0[iter_31_0])
		var_31_10.name = xyd.tables.item:name(var_31_0[iter_31_0])

		arg_31_0:addTips(var_31_8, var_31_10)
	end

	local var_31_11 = xyd.tables.gift:crystal(giftCode)

	if var_31_11 and var_31_11 > 0 then
		local var_31_12 = display.newNode()

		var_31_12:setContentSize(var_31_3, var_31_3)
		xyd.setItemBorder(var_31_12, -1, false, false, var_31_11)
		var_31_12:addTo(arg_31_1)
		var_31_12:setAnchorPoint(cc.p(0, 0))
		var_31_12:setPosition(var_31_6 * (var_31_3 + var_31_4), 0)

		local var_31_13 = {}

		var_31_13.id = -1
		var_31_13.tipsType = 1

		arg_31_0:addTips(var_31_12, var_31_13)

		var_31_6 = var_31_6 + 1
	end

	local var_31_14 = xyd.tables.gift:mana(giftCode)

	if var_31_14 and var_31_14 > 0 then
		local var_31_15 = display.newNode()

		var_31_15:setContentSize(var_31_3, var_31_3)
		xyd.setItemBorder(var_31_15, -2, false, false, var_31_14)
		var_31_15:addTo(arg_31_1)
		var_31_15:setAnchorPoint(cc.p(0, 0))
		var_31_15:setPosition(var_31_6 * (var_31_3 + var_31_4), 0)

		local var_31_16 = {}

		var_31_16.id = -2
		var_31_16.tipsType = 1

		arg_31_0:addTips(var_31_15, var_31_16)

		local var_31_17 = var_31_6 + 1
	end

	return arg_31_1
end

return var_0_0
