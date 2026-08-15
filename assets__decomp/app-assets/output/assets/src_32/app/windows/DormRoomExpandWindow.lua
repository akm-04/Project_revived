local var_0_0 = class("DormRoomExpandWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.houseDetail = arg_1_0.dorm.houseDetail
	arg_1_0.houseInfo = arg_1_0.dorm.houseInfo
	arg_1_0.expandLev = arg_1_0.houseInfo.expand_lev + 1
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.SELL_DORM_KEY_EVENT, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:nodeByName("own_txt2"):setString(arg_2_0.backpack:getItemNumByID(xyd.tables.misc.expandCostItem))
			arg_2_0:updateBtnState()
		end
	end)
end

function var_0_0.updateBtnState(arg_4_0)
	local var_4_0 = xyd.tables.dormExpand:costItems(arg_4_0.expandLev)
	local var_4_1 = xyd.tables.dormExpand:costNums(arg_4_0.expandLev)
	local var_4_2 = true

	for iter_4_0 = 1, 2 do
		local var_4_3 = var_4_0[iter_4_0]

		if var_4_1[iter_4_0] > arg_4_0.backpack:getItemNumByID(var_4_3) then
			var_4_2 = false

			arg_4_0:nodeByName("own_txt" .. iter_4_0):setColor(cc.c3b(255, 0, 0))
		else
			arg_4_0:nodeByName("own_txt" .. iter_4_0):setColor(cc.c3b(255, 98, 102))
		end
	end

	if var_4_2 then
		arg_4_0:nodeByName("sure_btn"):setBright(true)
		arg_4_0:nodeByName("sure_btn"):setTouchEnabled(true)
		arg_4_0:nodeByName("txt_confirm_gray"):setVisible(false)
		arg_4_0:nodeByName("sure_text"):setVisible(true)
	else
		arg_4_0:nodeByName("sure_btn"):setBright(false)
		arg_4_0:nodeByName("sure_btn"):setTouchEnabled(false)
		arg_4_0:nodeByName("txt_confirm_gray"):setVisible(true)
		arg_4_0:nodeByName("sure_text"):setVisible(false)
	end
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = xyd.tables.dormExpand:costItems(arg_6_0.expandLev)
	local var_6_1 = xyd.tables.dormExpand:costNums(arg_6_0.expandLev)
	local var_6_2 = string.format(var_0_1:translation("DORM_ROOM_EXPAND_TEXT1"), var_6_1[2], xyd.tables.item:name(var_6_0[1]))
	local var_6_3 = string.format(var_0_1:translation("DORM_ROOM_EXPAND_TEXT2"), 4 - arg_6_0.expandLev)

	arg_6_0:nodeByName("tip_txt1"):setString(var_6_2 .. var_6_3)
	arg_6_0:nodeByName("get_text2"):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT3"))
	arg_6_0:nodeByName("get_text1"):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT3"))

	for iter_6_0 = 1, 2 do
		local var_6_4 = var_6_0[iter_6_0]
		local var_6_5 = var_6_1[iter_6_0]

		xyd.setItemAndAddTips(arg_6_0:nodeByName("icon_container" .. iter_6_0), var_6_4, var_6_5)
		arg_6_0:nodeByName("cost_text" .. iter_6_0):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT4"))
		arg_6_0:nodeByName("own_text" .. iter_6_0):setString(var_0_1:translation("DORM_ROOM_EXPAND_TEXT6"))
		arg_6_0:nodeByName("cost_txt" .. iter_6_0):setString(var_6_5)
		arg_6_0:nodeByName("own_txt" .. iter_6_0):setString(arg_6_0.backpack:getItemNumByID(var_6_4))
	end

	arg_6_0:updateBtnState()
	arg_6_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_7_0)
	local var_7_0 = xyd.tables.misc.expandGetWay
	local var_7_1 = xyd.tables.heroGetWayTable

	for iter_7_0 = 1, 4 do
		local var_7_2 = var_7_0[iter_7_0]

		arg_7_0:nodeByName("item_container" .. iter_7_0):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.navigateToHeroGetWay(var_7_2)
			end
		end)
		arg_7_0:nodeByName("item_container" .. iter_7_0):getChildByName("name_txt"):setString(var_7_1:getName(var_7_2))

		local var_7_3 = xyd.AssetLoader.get():loadSprite(var_7_1:getIcon(var_7_2))

		arg_7_0:nodeByName("item_container" .. iter_7_0):getChildByName("icon"):setSpriteFrame(var_7_3:getSpriteFrame())
	end

	arg_7_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = {
				house_id = arg_7_0.houseDetail.house_id
			}

			arg_7_0.dorm:startExpandHouse(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					if arg_7_0.callback then
						arg_7_0.callback()
					end

					local var_10_0 = xyd.tables.dormExpand:costItems(arg_7_0.expandLev)
					local var_10_1 = xyd.tables.dormExpand:costNums(arg_7_0.expandLev)

					for iter_10_0 = 1, 2 do
						local var_10_2 = {
							itemID = var_10_0[iter_10_0],
							itemNum = var_10_1[iter_10_0]
						}

						arg_7_0.backpack:removeItem(var_10_2)
					end

					xyd.WindowManager.get():closeWindow(arg_7_0)
				end
			end)
		end
	end)
end

return var_0_0
