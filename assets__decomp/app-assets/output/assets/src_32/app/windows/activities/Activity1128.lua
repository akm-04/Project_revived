local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.fundNew

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.selectTapNum = 1
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("list")

	var_2_2:setLocalZOrder(6)

	local var_2_3 = var_2_2:getContentSize()

	var_2_2:setTouchSwallowEnabled(false)

	local var_2_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_3.width, var_2_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:layout(var_2_1, var_2_4)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	local function var_3_0(arg_4_0, arg_4_1)
		for iter_4_0 = 1, #arg_4_0 do
			local var_4_0 = arg_4_0[iter_4_0]:getChildByName("container")

			var_4_0:setAnchorPoint(0.5, 0.5)

			if iter_4_0 == arg_4_1 then
				arg_4_0[iter_4_0]:setLocalZOrder(10)
				var_4_0:getChildByName("item_bg_2"):setVisible(false)
				var_4_0:getChildByName("item_bg"):setVisible(true)
			else
				arg_4_0[iter_4_0]:setLocalZOrder(1)
				var_4_0:getChildByName("item_bg_2"):setVisible(true)
				var_4_0:getChildByName("item_bg"):setVisible(false)
			end
		end
	end

	local var_3_1 = var_0_2:ids()
	local var_3_2 = arg_3_0.activity.details.is_buy
	local var_3_3 = -10
	local var_3_4 = {}

	for iter_3_0 = 1, #var_3_1 do
		local var_3_5 = var_3_1[iter_3_0]
		local var_3_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1128/top_item.csb")
		local var_3_7 = var_3_6:getChildByName("container")

		var_3_6:addTo(arg_3_1:getChildByName("pig_container"))
		var_3_6:setPosition(cc.p(var_3_3, 0))

		var_3_3 = var_3_3 + var_3_7:getContentSize().width + 2

		var_3_6:setName("top_item_" .. iter_3_0)
		arg_3_0:updateTopItem(var_3_7, var_3_5)

		local var_3_8 = var_0_2:cost(var_3_5)

		var_3_7:getChildByName("btn_buy"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.began then
				arg_5_0:setScale(0.9)
			elseif arg_5_1 == ccui.TouchEventType.moved then
				arg_5_0:setScale(1)
			elseif arg_5_1 == ccui.TouchEventType.ended then
				arg_5_0:setScale(1)

				if var_0_2:vipReq(var_3_5) > arg_3_0.player.vip then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_FUND_NO_VIP")
					})

					return
				end

				local var_5_0 = var_0_2:name(var_3_5)
				local var_5_1 = string.format(var_0_1:translation("ACTIVITY_FUND_NEW_BUY"), var_3_8, var_5_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
					if arg_3_0.player.crystal < var_3_8 then
						local var_6_0 = var_0_1:translation("ZUANSHI_ABSENCE")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
							xyd.WindowManager.get():openWindow("vip_recharge")
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					else
						local var_6_1 = {
							fund_id = var_3_5
						}

						xyd.Backend.get():request(xyd.mid.BUY_FUND_NEW, var_6_1, function(arg_8_0, arg_8_1)
							if arg_8_0 == xyd.error.OK and arg_5_0 and not tolua.isnull(arg_5_0) then
								arg_5_0:setBright(false)
								arg_5_0:setTouchEnabled(false)
								arg_5_0:getChildByName("has_buy"):setVisible(true)
								arg_5_0:getChildByName("cost"):setVisible(false)

								arg_3_0.activity.details.is_buy[var_3_5] = 1
								arg_3_0.selectTapNum = var_3_5

								arg_3_0:createAwardList(arg_3_2, var_0_2:items(var_3_5))
							end
						end)
					end
				end, nil, 0, xyd.ColorMode.ACTIVITY)
			end
		end)

		if var_3_2[iter_3_0] == 1 then
			var_3_7:getChildByName("btn_buy"):setBright(false)
			var_3_7:getChildByName("btn_buy"):setTouchEnabled(false)
			var_3_7:getChildByName("btn_buy"):getChildByName("cost"):setVisible(false)
			var_3_7:getChildByName("btn_buy"):getChildByName("has_buy"):setVisible(true)
		else
			var_3_7:getChildByName("btn_buy"):setBright(true)
			var_3_7:getChildByName("btn_buy"):setTouchEnabled(true)
			var_3_7:getChildByName("btn_buy"):getChildByName("cost"):setVisible(true)
			var_3_7:getChildByName("btn_buy"):getChildByName("has_buy"):setVisible(false)
		end

		table.insert(var_3_4, var_3_6)
		var_3_6:setTouchEnabled(true)
		var_3_6:setTouchSwallowEnabled(false)
		var_3_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				return true
			elseif arg_9_0.name == "ended" then
				arg_3_0.selectTapNum = var_3_5

				var_3_0(var_3_4, arg_3_0.selectTapNum)
				arg_3_0:createAwardList(arg_3_2, var_0_2:items(var_3_5))
			end
		end)
	end

	arg_3_0.selectTapNum = 1

	var_3_0(var_3_4, arg_3_0.selectTapNum)
	arg_3_0:createAwardList(arg_3_2, var_0_2:items(1))
end

function var_0_0.updateTopItem(arg_10_0, arg_10_1, arg_10_2)
	for iter_10_0 = 1, 3 do
		if iter_10_0 ~= arg_10_2 then
			arg_10_1:getChildByName("word_fanli_" .. iter_10_0):setVisible(false)
			arg_10_1:getChildByName("word_jijin_" .. iter_10_0):setVisible(false)
			arg_10_1:getChildByName("img_pig_" .. iter_10_0):setVisible(false)
		end
	end

	local var_10_0 = var_0_2:vipReq(arg_10_2)
	local var_10_1 = string.format(var_0_1:translation("ACTIVITY_FUND_NEW_DESC_2"), var_10_0)
	local var_10_2 = string.format(var_0_1:translation("CRYSTAL"))

	arg_10_1:getChildByName("text_desc"):setString(var_10_1)
	arg_10_1:getChildByName("btn_buy"):getChildByName("cost"):setString(var_0_2:cost(arg_10_2) .. var_10_2)

	local var_10_3 = string.format(var_0_1:translation("ACTIVITY_COMMON_TEXT5"))

	arg_10_1:getChildByName("btn_buy"):getChildByName("has_buy"):setString(var_10_3)
end

function var_0_0.createAwardList(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_0.activity

	arg_11_1:removeAllItems()

	for iter_11_0 = 1, #arg_11_2 do
		if arg_11_0:checkInitItem(iter_11_0, params) then
			local var_11_1 = arg_11_1:newItem()
			local var_11_2 = display.newNode()
			local var_11_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1128/concent_item.csb")
			local var_11_4 = var_11_3:getChildByName("container")

			arg_11_0:createConcentItem(var_11_0, var_11_4, arg_11_2[iter_11_0], iter_11_0)
			var_11_3:addTo(var_11_2)
			var_11_3:setTouchEnabled(true)
			var_11_3:setAnchorPoint(cc.p(0, 0))
			var_11_3:setPosition(0, 0)
			var_11_3:setTouchSwallowEnabled(false)

			local var_11_5 = var_11_4:getContentSize()

			var_11_2:setContentSize(arg_11_1.viewRect_.width, var_11_5.height + 5)
			var_11_1:addContent(var_11_2)
			var_11_1:setItemSize(arg_11_1.viewRect_.width, var_11_5.height + 5)
			arg_11_1:addItem(var_11_1)
		end
	end

	arg_11_1:reload()
end

function var_0_0.createConcentItem(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4)
	local function var_12_0(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
		if arg_13_2[arg_12_0.selectTapNum] == 0 or arg_13_4 > arg_12_0.player.lev then
			arg_13_0:getChildByName("btn_get"):setBright(false)
			arg_13_0:getChildByName("btn_get"):setTouchEnabled(false)
			arg_13_0:getChildByName("has_get"):setVisible(false)
			arg_13_1:getChildByName("word_get"):setVisible(false)
		elseif arg_13_3[arg_12_4] == 1 then
			arg_13_0:getChildByName("btn_get"):setVisible(false)
			arg_13_0:getChildByName("has_get"):setVisible(true)
		else
			arg_13_1:getChildByName("word_get_gray"):setVisible(false)
			arg_13_0:getChildByName("has_get"):setVisible(false)
		end
	end

	local var_12_1 = arg_12_0.activity.details
	local var_12_2 = var_12_1.is_buy
	local var_12_3 = var_12_1["is_awards_" .. arg_12_0.selectTapNum] or {}
	local var_12_4 = arg_12_3[1]
	local var_12_5 = arg_12_3[2]
	local var_12_6 = arg_12_2:getChildByName("reward")

	xyd.setItemBorder(var_12_6, -1, false, false, var_12_5)
	arg_12_2:getChildByName("text_title"):setString(var_12_4 .. var_0_1:translation("ACTIVITY_1166_TEXT1"))
	arg_12_2:getChildByName("text_title"):enableOutline(cc.c4b(212, 51, 85, 255), 2)

	local var_12_7 = string.format(var_0_1:translation("ACTIVITY_FUND_NEW_DESC_3"), var_12_4, var_12_5)

	arg_12_2:getChildByName("text_desc"):setString(var_12_7)

	local var_12_8 = arg_12_2:getChildByName("btn_get")

	var_12_8:addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_14_0:setScale(0.9)
		elseif arg_14_1 == ccui.TouchEventType.moved then
			arg_14_0:setScale(1)
		elseif arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = rewardID

			arg_12_0.activitiesModel:getActivityReward2(arg_12_1.table_id, arg_12_0.selectTapNum, arg_12_4, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK and arg_14_0 and not tolua.isnull(arg_14_0) then
					if arg_15_1 and arg_15_1.awards then
						arg_12_0.player:handleRewards(arg_15_1.awards)
					end

					var_12_3[arg_12_4] = 1

					var_12_0(arg_12_2, var_12_8, var_12_2, var_12_3, var_12_4)
				end
			end)
		end
	end)
	var_12_0(arg_12_2, var_12_8, var_12_2, var_12_3, var_12_4)
end

function var_0_0.checkInitItem(arg_16_0, arg_16_1, arg_16_2)
	return true
end

return var_0_0
