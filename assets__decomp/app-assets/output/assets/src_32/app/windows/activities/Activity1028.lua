local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
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
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("disc_txt"):setVisible(false)

	local var_2_2 = var_2_1:getChildByName("disc_container")
	local var_2_3 = var_0_1:translation("ACTIVITY_NEWYEAR_DESCRIBE")
	local var_2_4 = {
		size = 22
	}
	local var_2_5 = xyd.AssetLoader.get():loadLabel(var_2_4)

	var_2_5:setMaxLineWidth(577)

	if var_2_3 then
		var_2_5:setString(var_2_3)
	end

	var_2_5:setAnchorPoint(0, 0)
	var_2_5:setPosition(20, 10)
	var_2_5:addTo(var_2_2)

	local var_2_6 = var_2_1:getChildByName("list_container")
	local var_2_7 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 670, 330),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	var_2_7:addTo(var_2_6):onScroll(handler(arg_2_0, arg_2_0.scrollListener2))

	local var_2_8 = #xyd.tables.activityNewYear:allcount()
	local var_2_9 = {
		list = var_2_7,
		listNum = var_2_8,
		activity = arg_2_0.activity
	}

	arg_2_0:createNewYearList(var_2_9)
end

function var_0_0.createNewYearList(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.list
	local var_3_1 = arg_3_1.activity
	local var_3_2 = arg_3_1.listNum

	if arg_3_1.type then
		var_3_0:removeAllItems()
	end

	local var_3_3 = {}

	for iter_3_0 = 1, var_3_2 do
		if xyd.tables.activityNewYear:limit_type(iter_3_0) ~= xyd.NewYear.NONE then
			if xyd.tables.activityNewYear:limit_type(iter_3_0) == xyd.NewYear.PERSON then
				if xyd.tables.activityNewYear:buylimit(iter_3_0) - var_3_1.details.buy_nums[iter_3_0] ~= 0 then
					table.insert(var_3_3, iter_3_0)
				end
			elseif xyd.tables.activityNewYear:limit_type(iter_3_0) == xyd.NewYear.TEAM and xyd.tables.activityNewYear:buylimit(iter_3_0) - var_3_1.details.server_nums[iter_3_0] ~= 0 then
				table.insert(var_3_3, iter_3_0)
			end
		end
	end

	for iter_3_1 = 1, var_3_2 do
		if xyd.tables.activityNewYear:limit_type(iter_3_1) == xyd.NewYear.NONE then
			table.insert(var_3_3, iter_3_1)
		end
	end

	for iter_3_2 = 1, var_3_2 do
		if xyd.tables.activityNewYear:limit_type(iter_3_2) ~= xyd.NewYear.NONE then
			if xyd.tables.activityNewYear:limit_type(iter_3_2) == xyd.NewYear.PERSON then
				if xyd.tables.activityNewYear:buylimit(iter_3_2) - var_3_1.details.buy_nums[iter_3_2] == 0 then
					table.insert(var_3_3, iter_3_2)
				end
			elseif xyd.tables.activityNewYear:limit_type(iter_3_2) == xyd.NewYear.TEAM and xyd.tables.activityNewYear:buylimit(iter_3_2) - var_3_1.details.server_nums[iter_3_2] == 0 then
				table.insert(var_3_3, iter_3_2)
			end
		end
	end

	for iter_3_3 = 1, var_3_2 do
		if arg_3_0:checkInitItem(iter_3_3, arg_3_1) then
			local var_3_4 = var_3_0:newItem()
			local var_3_5 = display.newNode()
			local var_3_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1028/newYearItem.csb")
			local var_3_7 = var_3_6:getChildByName("container")
			local var_3_8 = var_3_7:getChildByName("yuanjia_num")
			local var_3_9 = var_3_7:getChildByName("zhekoujia_num")
			local var_3_10 = var_3_7:getChildByName("gift_container")
			local var_3_11 = tonumber(xyd.tables.activityNewYear:discount(var_3_3[iter_3_3]))
			local var_3_12 = xyd.tables.activityNewYear:icon(var_3_3[iter_3_3])
			local var_3_13 = xyd.SpriteLoader.new(var_3_12, nil, nil, xyd.DefaultImageType.ITEM_ICON)

			var_3_13:addTo(var_3_10)
			var_3_13:setPosition(50, 48)
			var_3_7:getChildByName("zhekoujia_Txt"):setString(var_0_1:translation("ORIGINAL_PRICE"))
			var_3_7:getChildByName("zhekoujia_Txt"):setString(var_0_1:translation("NEWYEAR_DISCOUNT_CHARGE"))

			local var_3_14 = display.newNode()

			var_3_14:setPosition(var_3_13:getPosition())
			var_3_14:setAnchorPoint(0.5, 0.5)
			var_3_14:setContentSize(var_3_13:getContentSize())
			var_3_14:setTouchEnabled(true)
			var_3_14:setTouchSwallowEnabled(false)
			var_3_14:addTo(var_3_10)
			var_3_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
				if arg_4_0.name == "began" then
					if not xyd.WindowManager.get():getWindow("newYear_tips") then
						local var_4_0 = xyd.tables.activityNewYear:gift_list(var_3_3[iter_3_3])
						local var_4_1 = xyd.WindowManager.get():openWindow("newYear_tips", var_4_0)
						local var_4_2 = var_3_14:convertToWorldSpace(cc.p(0, 0))

						var_4_1:setPosition(var_4_2.x + var_3_4:getContentSize().width + 7 - 550, var_4_2.y - var_3_4:getContentSize().height + 70)
					end

					return true
				elseif arg_4_0.name == "ended" then
					xyd.WindowManager.get():closeWindow("newYear_tips")
				end
			end)

			for iter_3_4 = 1, 9 do
				if iter_3_4 == var_3_11 then
					var_3_7:getChildByName("discount_" .. iter_3_4):setVisible(true)
				else
					var_3_7:getChildByName("discount_" .. iter_3_4):setVisible(false)
				end
			end

			var_3_7:getChildByName("giftname"):setString(xyd.tables.activityNewYear:name(var_3_3[iter_3_3]))

			local var_3_15 = var_3_7:getChildByName("xiangou_num")
			local var_3_16 = var_3_7:getChildByName("xiangou_text")
			local var_3_17 = var_3_7:getChildByName("vgoumai_fund_txt")
			local var_3_18 = var_3_7:getChildByName("valready_buy_gray")
			local var_3_19 = var_3_7:getChildByName("goumai_button")
			local var_3_20 = var_3_7:getChildByName("yigoumai_button")
			local var_3_21

			if xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.PERSON then
				var_3_21 = tonumber(xyd.tables.activityNewYear:buylimit(var_3_3[iter_3_3]))

				var_3_16:setString(var_0_1:translation("NEWYEAR_BUYLIMIT_PERSON"))
			elseif xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.TEAM then
				var_3_21 = tonumber(xyd.tables.activityNewYear:buylimit(var_3_3[iter_3_3]))

				var_3_16:setString(var_0_1:translation("NEWYEAR_BUYLIMIT_TEAM"))
			elseif xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.NONE then
				var_3_21 = tonumber(xyd.tables.activityNewYear:buylimit(var_3_3[iter_3_3]))

				var_3_16:setVisible(false)
				var_3_15:setVisible(false)
			end

			var_3_8:setString(tonumber(xyd.tables.activityNewYear:price(var_3_3[iter_3_3])))
			var_3_9:setString(xyd.tables.activityNewYear:discount_price(var_3_3[iter_3_3]))

			local var_3_22

			if xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.TEAM then
				var_3_22 = tonumber(var_3_1.details.server_nums[var_3_3[iter_3_3]])

				var_3_15:setString(var_3_22 .. "/" .. var_3_21)
			elseif xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.PERSON then
				var_3_22 = tonumber(var_3_1.details.buy_nums[var_3_3[iter_3_3]])

				var_3_15:setString(var_3_22 .. "/" .. var_3_21)
			elseif xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.NONE then
				var_3_22 = 0
			end

			if xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) ~= xyd.NewYear.NONE then
				if var_3_21 <= var_3_22 then
					var_3_19:setTouchEnabled(false)
					var_3_19:setVisible(false)
					var_3_17:setVisible(false)
					var_3_18:setVisible(true)
					var_3_20:setVisible(true)
				else
					var_3_18:setVisible(false)
					var_3_20:setVisible(false)
					var_3_19:setVisible(true)
					var_3_17:setVisible(true)
					var_3_19:setTouchSwallowEnabled(false)
				end
			else
				var_3_18:setVisible(false)
				var_3_20:setVisible(false)
				var_3_19:setVisible(true)
				var_3_17:setVisible(true)
				var_3_19:setTouchSwallowEnabled(true)
			end

			var_3_19:addTouchEventListener(function(arg_5_0, arg_5_1)
				if arg_5_1 == ccui.TouchEventType.ended then
					local var_5_0

					if var_3_1.table_id == xyd.Activities.NewYear then
						var_5_0 = var_3_3[iter_3_3]
					else
						var_5_0 = nil
					end

					if arg_3_0.player.crystal < xyd.tables.activityNewYear:discount_price(var_3_3[iter_3_3]) then
						local var_5_1 = string.format(var_0_1:translation("CRYSTAL_TIP"))

						xyd.WindowManager.get():openWindow("toast", {
							message = var_5_1
						})
					elseif arg_3_0.player.lev < tonumber(xyd.tables.activityNewYear:level_limit(var_3_3[iter_3_3])) then
						local var_5_2 = string.format(var_0_1:translation("LEVEL_LIMIT_TIP"))

						xyd.WindowManager.get():openWindow("toast", {
							message = var_5_2
						})
					elseif arg_3_0.scrollViewMoved2_ ~= true then
						arg_3_0.activitiesModel:getActivityReward(var_3_1.table_id, var_5_0, function(arg_6_0, arg_6_1)
							if arg_6_0 == xyd.error.OK then
								arg_3_0.player:handleRewards(arg_6_1.awards)
								arg_3_0.activitiesModel:clearRedMarkState(var_3_1.table_id, 2)

								var_3_22 = var_3_22 + 1

								if xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.TEAM then
									var_3_1.details.server_nums[var_3_3[iter_3_3]] = var_3_1.details.server_nums[var_3_3[iter_3_3]] + 1
								elseif xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) == xyd.NewYear.PERSON then
									var_3_1.details.buy_nums[var_3_3[iter_3_3]] = var_3_1.details.buy_nums[var_3_3[iter_3_3]] + 1
								end

								if xyd.tables.activityNewYear:limit_type(var_3_3[iter_3_3]) ~= xyd.NewYear.NONE then
									var_3_15:setString(var_3_22 .. "/" .. var_3_21)

									if var_3_22 >= var_3_21 then
										var_3_19:setTouchEnabled(false)
										var_3_19:setVisible(false)
										var_3_17:setVisible(false)
										var_3_18:setVisible(true)
										var_3_20:setVisible(true)
										var_3_15:setVisible(true)
									end
								end
							end
						end)
					end
				end
			end)
			var_3_6:addTo(var_3_5)
			var_3_6:setTouchEnabled(true)
			var_3_6:setAnchorPoint(cc.p(0, 0))
			var_3_6:setPosition(0, 0)
			var_3_6:setTouchSwallowEnabled(false)
			var_3_5:setContentSize(665, 148)
			var_3_4:addContent(var_3_5)
			var_3_4:setItemSize(665, 148)
			var_3_0:addItem(var_3_4)
		end
	end

	var_3_0:reload()
end

function var_0_0.scrollListener2(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved2_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved2_ = true
	end
end

function var_0_0.checkInitItem(arg_8_0, arg_8_1, arg_8_2)
	return true
end

return var_0_0
