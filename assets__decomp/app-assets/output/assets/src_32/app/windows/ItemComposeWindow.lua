local var_0_0 = class("ItemComposeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.attr
local var_0_4 = 35
local var_0_5 = import("app.model.Item")
local var_0_6 = xyd.tables.translation
local var_0_7 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.item = clone(arg_1_2.item)

	if arg_1_2.isCompose == nil then
		arg_1_0.isCompose = true
	else
		arg_1_0.isCompose = arg_1_2.isCompose
	end

	arg_1_0.currentItem_ = arg_1_0.item
	arg_1_0.stack_ = {
		arg_1_0.item
	}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.maxSuperCampaign = arg_1_0.selfPlayer.super_campaign_id
	arg_1_0.maxNormalCampaign = arg_1_0.selfPlayer.normal_campaign_id
	arg_1_0.isActivityItem = arg_1_2.isActivityItem
	arg_1_0.composeNeedNum = 1
	arg_1_0.isAwakeTwiceItem = var_0_7:isAwakeTwiceItem(arg_1_0.item:getTableID()) > 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("gain_way_txt"):setString(var_0_6:translation("ITEM_DETAIL_GAIN_WAY") .. var_0_6:translation("COLON"))
	arg_2_0:nodeByName("gain_way_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	if not arg_2_0.isCompose then
		arg_2_0.isShowGainWay = true

		arg_2_0:switchItemShowWay(false)

		local var_2_0 = arg_2_0:nodeByName("item_title_layer")

		arg_2_0.touchList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_2_0:getWidth(), var_2_0:getHeight()),
			direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_2_0)

		arg_2_0.touchList_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
		arg_2_0.touchList_:reload()
		arg_2_0:nodeByName("label_title"):setString(arg_2_0.currentItem_:getName())
		arg_2_0.selfPlayer:loadWorldMap(function()
			arg_2_0:showGainWay(arg_2_0.item:getTableID())
		end)
		arg_2_0:getBtn()
	else
		arg_2_0:layout()
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:switchItemShowWay(true)

	for iter_5_0 = 1, 4 do
		local var_5_0 = arg_5_0:nodeByName("arraw" .. iter_5_0)

		for iter_5_1 = 1, iter_5_0 do
			local var_5_1 = var_5_0:getChildByName("icon" .. iter_5_1)
			local var_5_2 = display.newNode()

			var_5_2:setContentSize(var_5_1:getContentSize())
			var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_2:addTo(var_5_0)
			var_5_2:setName("icon" .. iter_5_1)
			var_5_2:setPosition(cc.p(var_5_1:getPosition()))
			var_5_1:removeSelf()
		end
	end

	arg_5_0:nodeByName("gain_way_txt"):setString(var_0_6:translation("ITEM_DETAIL_GAIN_WAY") .. var_0_6:translation("COLON"))

	local var_5_3 = arg_5_0:nodeByName("item_title_layer")

	arg_5_0.touchList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_3:getWidth(), var_5_3:getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_5_3)

	arg_5_0.touchList_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:setIcons()
	arg_5_0:update()
	arg_5_0:getBtn()
	arg_5_0:nodeByName("text_all_compose"):setString(var_0_6:translation("HERO_MAIN_TEXT_32"))
	arg_5_0:nodeByName("text_compose"):setString(var_0_6:translation("HERO_MAIN_TEXT_33"))
	arg_5_0:nodeByName("return"):setString(var_0_6:translation("HERO_MAIN_TEXT_34"))
end

function var_0_0.update(arg_6_0)
	arg_6_0.touchList_:reload()
	arg_6_0:switchItemShowWay(true)
	arg_6_0:nodeByName("label_title"):setString(arg_6_0.currentItem_:getName())
	arg_6_0:nodeByName("label_cost"):setString(var_0_2:translation("FRAGMENT_MAKE_COST"))
	arg_6_0:nodeByName("label_cost_value"):setString(arg_6_0.currentItem_:composeMana())

	if arg_6_0.currentItem_:composeMana() > arg_6_0.selfPlayer.mana then
		arg_6_0:nodeByName("label_cost_value"):setColor(cc.c4b(255, 0, 0, 150))
	else
		arg_6_0:nodeByName("label_cost_value"):setColor(cc.c4b(254, 120, 32, 255))
	end

	arg_6_0:nodeByName("main_icon"):removeAllChildren()
	xyd.setItemBorder(arg_6_0:nodeByName("main_icon"), arg_6_0.currentItem_:getTableID())

	local var_6_0 = arg_6_0:getComposeCount()

	for iter_6_0 = 1, 4 do
		if iter_6_0 ~= var_6_0 then
			arg_6_0:nodeByName("arraw" .. iter_6_0):setVisible(false)
		else
			arg_6_0:nodeByName("arraw" .. iter_6_0):setVisible(true)
		end
	end

	arg_6_0:nodeByName("text_all_compose"):hide()
	arg_6_0:nodeByName("text_compose"):hide()

	if arg_6_0:isHasMaterial() then
		arg_6_0:nodeByName("text_compose"):show()
	elseif arg_6_0.currentItem_:isHasMaterial() then
		arg_6_0:nodeByName("text_all_compose"):show()
	else
		arg_6_0:nodeByName("text_compose"):show()
	end
end

function var_0_0.setIcons(arg_7_0)
	local var_7_0 = arg_7_0.currentItem_:getCompose()
	local var_7_1 = arg_7_0.currentItem_:getComposeNum()

	if var_7_0[1] == 0 then
		return
	end

	local var_7_2 = false

	if arg_7_0.isAwakeTwiceItem and #arg_7_0.stack_ == 1 then
		var_7_2 = true

		local var_7_3 = var_7_0
		local var_7_4 = var_7_1

		var_7_0 = {
			var_0_7:awakeCompose(arg_7_0.item:getTableID())
		}
		var_7_1 = {
			1
		}

		for iter_7_0, iter_7_1 in ipairs(var_7_3) do
			table.insert(var_7_0, iter_7_1)
			table.insert(var_7_1, var_7_4[iter_7_0])
		end
	end

	local var_7_5 = #var_7_0
	local var_7_6 = arg_7_0:nodeByName("arraw" .. var_7_5)

	for iter_7_2 = 1, var_7_5 do
		local var_7_7 = var_7_6:getChildByName("icon" .. iter_7_2)

		var_7_7:removeAllChildren()

		local var_7_8 = display.newNode()

		var_7_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_8:setPosition(var_7_7:getWidth() / 2, var_7_7:getHeight() / 2)
		var_7_8:setContentSize(var_7_7:getWidth(), var_7_7:getHeight())
		var_7_8:addTo(var_7_7)

		local var_7_9 = var_7_0[iter_7_2]

		xyd.setItemBorder(var_7_7, var_7_9)

		local var_7_10 = var_7_6:getChildByName("label_owned" .. iter_7_2)
		local var_7_11 = var_7_6:getChildByName("label_required" .. iter_7_2)
		local var_7_12 = arg_7_0.backpack:getItemNumByID(var_7_9)

		if var_7_2 and iter_7_2 == 1 then
			var_7_12 = arg_7_0.backpack:getItemNumByID(arg_7_0.item:getTableID()) > 0 and 0 or 1
		end

		if var_7_12 == 1 and iter_7_2 > 1 and var_7_0[iter_7_2 - 1] == var_7_9 then
			var_7_10:setString("0")
		else
			var_7_10:setString(var_7_12)
		end

		var_7_11:setString("/" .. var_7_1[iter_7_2])

		if var_7_12 < var_7_1[iter_7_2] then
			var_7_10:setTextColor(cc.c4b(220, 4, 8, 255))
		else
			var_7_10:setTextColor(cc.c4b(51, 48, 43, 255))
		end

		var_7_11:setTextColor(cc.c4b(51, 48, 43, 255))

		arg_7_0.composeNeedNum = var_7_1[iter_7_2]

		var_7_8:setTouchEnabled(true)
		var_7_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				var_7_7:setScale(0.9)

				arg_7_0.prevX_ = arg_8_0.x
				arg_7_0.prevY_ = arg_8_0.y
				arg_7_0.startClick_ = true
			elseif arg_8_0.name == "moved" then
				if math.abs(arg_8_0.y - arg_7_0.prevY_) > 5 or math.abs(arg_8_0.x - arg_7_0.prevX_) > 5 then
					var_7_7:setScale(1)

					arg_7_0.startClick_ = false
				end
			elseif arg_8_0.name == "ended" and arg_7_0.startClick_ then
				var_7_7:setScale(1)

				if var_7_2 and iter_7_2 == 1 then
					return
				end

				local var_8_0 = var_0_5.new()

				var_8_0:populate({
					table_id = var_7_9
				})

				local var_8_1 = var_8_0:getCompose()

				if next(var_8_1) and var_8_1[1] > 0 then
					arg_7_0.isShowGainWay = false

					table.insert(arg_7_0.stack_, var_8_0)

					arg_7_0.currentItem_ = var_8_0

					arg_7_0:setIcons()
					arg_7_0:update()
				else
					arg_7_0.isShowGainWay = true

					table.insert(arg_7_0.stack_, var_8_0)

					arg_7_0.currentItem_ = var_8_0

					arg_7_0.touchList_:reload()
					arg_7_0.selfPlayer:loadWorldMap(function()
						arg_7_0:showGainWay(var_7_9)
					end)
				end
			end

			return true
		end)
	end
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevX_ = arg_10_1.x
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" then
		local var_10_0 = 20

		if var_10_0 <= math.abs(arg_10_1.x - arg_10_0.prevX_) or var_10_0 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
			arg_10_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.showGainWay(arg_11_0, arg_11_1)
	arg_11_0:switchItemShowWay(false)
	arg_11_0:nodeByName("label_title"):setString(arg_11_0.currentItem_:getName())

	if not arg_11_0.gainListView_ then
		arg_11_0.gainListView_ = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, arg_11_0:nodeByName("gain_container"):getWidth(), arg_11_0:nodeByName("gain_container"):getHeight()),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_11_0:nodeByName("gain_container")):onScroll(handler(arg_11_0, arg_11_0.scrollListener))
	else
		arg_11_0.gainListView_:removeAllItems()
	end

	local var_11_0 = var_0_7:map(arg_11_1)

	if var_0_7:isAwakenPiece(arg_11_1) == 1 and type(var_11_0) == "table" then
		local var_11_1 = var_11_0[1]

		for iter_11_0 = 1, #var_11_0 do
			local var_11_2 = 0

			if arg_11_0.selfPlayer.worldMaps_[var_11_0[iter_11_0]] then
				var_11_2 = arg_11_0.selfPlayer.worldMaps_[var_11_0[iter_11_0]].star or 0
			end

			if var_11_1 <= var_11_0[iter_11_0] and var_11_2 == 3 then
				var_11_1 = var_11_0[iter_11_0]
			end
		end

		var_11_0 = {
			var_11_1
		}
	end

	for iter_11_1 = #var_11_0, 1, -1 do
		if var_11_0[iter_11_1] == 0 then
			table.remove(var_11_0, iter_11_1)
		end
	end

	for iter_11_2 = 1, #var_11_0 do
		local var_11_3 = display.newNode()
		local var_11_4 = arg_11_0.gainListView_:newItem()
		local var_11_5 = import("app.windows.GainWayItem").new()
		local var_11_6 = xyd.tables.campaign:relateCampaign(var_11_0[iter_11_2])
		local var_11_7 = xyd.tables.campaign:campaignType(var_11_0[iter_11_2])
		local var_11_8

		if var_11_7 - 1 == xyd.CampaignType.SUPER and not arg_11_0.isActivityItem then
			var_11_8 = xyd.tables.campaign:icon(var_11_6)
		else
			var_11_8 = xyd.tables.campaign:icon(var_11_0[iter_11_2])
		end

		if not var_11_8 then
			return
		end

		local var_11_9 = {
			campaignName = xyd.tables.campaign:campaignName(var_11_0[iter_11_2]),
			chapter = xyd.tables.campaign:chapter(var_11_0[iter_11_2]),
			icon = var_11_8,
			campaignType = var_11_7,
			campaignID = var_11_0[iter_11_2],
			isActivityItem = arg_11_0.isActivityItem
		}

		if var_11_7 == xyd.CampaignType.PET and xyd.tables.campaign:getFloorType(var_11_0[iter_11_2]) == 2 then
			var_11_9.petFloor = xyd.tables.campaign:getFloor(var_11_0[iter_11_2])
		end

		var_11_5:setParams(var_11_9)
		var_11_5:setPosition(0, 0)
		var_11_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_5:ignoreAnchorPointForPosition(false)
		var_11_5:addTo(var_11_3)
		var_11_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				var_11_5.contentView_:nodeByName("gain_way_node"):setScale(0.9)
			end

			if arg_12_0.name == "moved" and arg_11_0.scrollViewMoved_ then
				var_11_5.contentView_:nodeByName("gain_way_node"):setScale(1)
			end

			if arg_12_0.name == "ended" and not arg_11_0.scrollViewMoved_ then
				var_11_5.contentView_:nodeByName("gain_way_node"):setScale(1)

				if not arg_11_0.isActivityItem then
					if var_11_7 == 3 and arg_11_0.maxSuperCampaign >= var_11_0[iter_11_2] or var_11_7 == 2 and arg_11_0.maxNormalCampaign >= var_11_0[iter_11_2] then
						arg_11_0.guild:loadGuildMap(function(arg_13_0)
							local var_13_0 = {
								isStoneCampaign = true,
								chapter = xyd.tables.campaign:chapter(var_11_0[iter_11_2]),
								campaignID = var_11_0[iter_11_2],
								campaignType = xyd.tables.campaign:campaignType(var_11_0[iter_11_2]) - 1,
								itemComposeID = arg_11_1,
								needItemComposeNum = arg_11_0.composeNeedNum
							}

							xyd.WindowManager.get():openWindow("map_window", var_13_0)
						end)
					elseif var_11_7 == xyd.CampaignType.PET then
						if xyd.WindowManager.get():getWindow("pet_campaign") then
							xyd.WindowManager.get():closeWindow("pet_campaign")
						end

						local var_12_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

						var_12_0:getCampaignInfo(function(arg_14_0)
							if arg_14_0 == xyd.error.OK then
								var_12_0:setStateBaseOnCampaignID(var_11_0[iter_11_2])

								if var_12_0.openSuper then
									xyd.WindowManager.get():openWindow("pet_campaign", {
										now_floor = var_11_9.petFloor
									})
								else
									xyd.WindowManager.get():openWindow("pet_campaign")
								end
							end
						end)
					elseif var_11_7 == xyd.CampaignType.CLOUD_LADDER or var_11_7 == xyd.CampaignType.CLOUD_ROAD or var_11_7 == xyd.CampaignType.CLOUD_TEMPLE then
						if arg_11_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) == true then
							xyd.WindowManager.get():openWindow("cloud_city")
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_6:translation("CHAPTER_NOT_AVAILABLE")
						})
					end
				else
					arg_11_0:activityItemGainWay(xyd.tables.campaign:campaignType(var_11_0[iter_11_2]) - 1, arg_11_1)
				end
			end

			return true
		end)
		var_11_4:addContent(var_11_3)
		var_11_3:setContentSize(434, 117)
		var_11_4:setItemSize(434, 122)
		arg_11_0.gainListView_:addItem(var_11_4)
	end

	local var_11_10 = xyd.tables.item:gainType(arg_11_1)

	for iter_11_3 = 1, #var_11_10 do
		id = var_11_10[iter_11_3]

		if id ~= 0 then
			local var_11_11 = arg_11_0.gainListView_:newItem()
			local var_11_12 = arg_11_0:creatWayContent(id)

			var_11_11:addContent(var_11_12)
			var_11_12:setContentSize(434, 117)
			var_11_11:setItemSize(434, 122)
			arg_11_0.gainListView_:addItem(var_11_11)
		end
	end

	arg_11_0.gainListView_:reload()
end

function var_0_0.creatWayContent(arg_15_0, arg_15_1)
	local var_15_0 = xyd.tables.heroGetWayTable
	local var_15_1 = display.newNode()
	local var_15_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/gain_way_item.csb")
	local var_15_3 = var_15_2:getChildByName("gain_way_node")

	var_15_3:getChildByName("super_txt"):setVisible(false)
	var_15_3:getChildByName("left_times"):setVisible(false)

	local var_15_4 = var_15_0:getIcon(arg_15_1)
	local var_15_5 = xyd.AssetLoader:get():loadSprite(var_15_4)

	var_15_5:setAnchorPoint(cc.p(0.5, 0.5))

	local var_15_6 = var_15_3:getChildByName("campaign_icon"):getContentSize().width / 2

	var_15_5:addTo(var_15_3:getChildByName("campaign_icon"))
	var_15_5:setPosition(cc.p(var_15_6, var_15_6))
	var_15_5:setScale(0.7)
	var_15_3:getChildByName("campaign_num"):setString(var_15_0:getName(arg_15_1))
	var_15_3:getChildByName("campaign_name"):setString(var_15_0:getDesc(arg_15_1))
	var_15_2:addTo(var_15_1)
	var_15_2:setAnchorPoint(cc.p(0, 0))
	var_15_2:setName("source")
	var_15_2:setTouchEnabled(true)
	var_15_2:setTouchSwallowEnabled(false)
	var_15_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			var_15_3:setScale(0.9)

			return true
		elseif arg_16_0.name == "moved" and arg_15_0.scrollViewMoved_ then
			var_15_3:setScale(1)
		elseif arg_16_0.name == "ended" and not arg_15_0.scrollViewMoved_ then
			var_15_3:setScale(1)
			xyd.navigateToHeroGetWay(arg_15_1)
		end
	end)

	return var_15_1
end

function var_0_0.activityItemGainWay(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0
	local var_17_1

	if arg_17_1 == xyd.CampaignType.SUPER then
		local var_17_2 = arg_17_0.maxSuperCampaign
		local var_17_3 = arg_17_0.selfPlayer.super_chapter_id
		local var_17_4 = {
			chapter_type = arg_17_1
		}

		xyd.WindowManager.get():openWindow("map_window", var_17_4)
	elseif arg_17_1 == xyd.CampaignType.NORMAL then
		local var_17_5 = arg_17_0.maxNormalCampaign
		local var_17_6 = arg_17_0.selfPlayer.normal_chapter_id
		local var_17_7 = {
			chapter_type = arg_17_1
		}

		xyd.WindowManager.get():openWindow("map_window", var_17_7)
	elseif arg_17_1 == xyd.CampaignType.MARCH then
		local var_17_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

		if var_17_8.mapInfo == nil then
			var_17_8:loadMarchInfo({}, function(arg_18_0)
				if arg_18_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("march")
				end
			end)
		else
			xyd.WindowManager.get():openWindow("march")
		end
	elseif arg_17_1 == xyd.CampaignType.ARENA then
		xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_19_0, arg_19_1)
			if arg_19_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("arena")
			end
		end)
	elseif arg_17_1 == xyd.CampaignType.SUPER_ARENA then
		xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA):loadPeakArena(function(arg_20_0)
			if arg_20_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("peak_arena")
			end
		end)
	elseif arg_17_1 == xyd.CampaignType.WU or arg_17_1 == xyd.CampaignType.SHU or arg_17_1 == xyd.CampaignType.WEI then
		xyd.WindowManager.get():openWindow("trial")
	elseif arg_17_1 == xyd.CampaignType.WUMIAN or arg_17_1 == xyd.CampaignType.MOMIAN then
		xyd.WindowManager.get():openWindow("time_trial")
	end
end

function var_0_0.switchItemShowWay(arg_21_0, arg_21_1)
	for iter_21_0 = 1, 4 do
		arg_21_0:nodeByName("arraw" .. iter_21_0):setVisible(arg_21_1)
	end

	arg_21_0:nodeByName("main_icon"):setVisible(arg_21_1)
	arg_21_0:nodeByName("compose_wordbg"):setVisible(arg_21_1)
	arg_21_0:nodeByName("text_all_compose"):setVisible(arg_21_1)
	arg_21_0:nodeByName("text_compose"):setVisible(arg_21_1)
	arg_21_0:nodeByName("gain_way_txt"):setVisible(not arg_21_1)
	arg_21_0:nodeByName("title_bg"):setVisible(not arg_21_1)
	arg_21_0:nodeByName("gain_container"):setVisible(not arg_21_1)
	arg_21_0:nodeByName("line"):setVisible(not arg_21_1)
	arg_21_0:nodeByName("return"):setVisible(not arg_21_1)

	arg_21_0.isGainWay_ = not arg_21_1
end

function var_0_0.isHasMaterial(arg_22_0)
	local var_22_0 = arg_22_0.currentItem_:getCompose()

	if not next(var_22_0) or var_22_0[1] == 0 then
		return false
	end

	local var_22_1 = {}

	for iter_22_0, iter_22_1 in ipairs(var_22_0) do
		var_22_1[iter_22_1] = var_22_1[iter_22_1] or arg_22_0.backpack:getItemNumByID(iter_22_1)

		if arg_22_0.currentItem_:getComposeNum(iter_22_0) > var_22_1[iter_22_1] then
			return false
		else
			var_22_1[iter_22_1] = var_22_1[iter_22_1] - arg_22_0.currentItem_:getComposeNum(iter_22_0)
		end
	end

	return true
end

function var_0_0.recursionCompose(arg_23_0)
	arg_23_0.currentItem_ = arg_23_0:getStackItem()

	arg_23_0.btn_:setTouchEnabled(false)

	if arg_23_0.currentItem_ == nil then
		return
	end

	if arg_23_0:isHasMaterial() then
		arg_23_0:update()
		arg_23_0:setIcons()
		arg_23_0:makeItem(function()
			if arg_23_0.currentItem_ ~= arg_23_0.currentComposeItem_ then
				arg_23_0:popItem()
				arg_23_0:recursionCompose()
			end
		end)
	elseif arg_23_0:pushItem() then
		arg_23_0:update()
		arg_23_0:setIcons()
		arg_23_0:recursionCompose()
	end
end

function var_0_0.popItem(arg_25_0)
	table.remove(arg_25_0.stack_)
end

function var_0_0.pushItem(arg_26_0)
	local var_26_0 = arg_26_0.currentItem_:getCompose()

	if not next(var_26_0) or var_26_0[1] == 0 then
		return false
	end

	local var_26_1 = {}

	for iter_26_0, iter_26_1 in ipairs(arg_26_0.currentItem_:getCompose()) do
		var_26_1[iter_26_1] = var_26_1[iter_26_1] or arg_26_0.backpack:getItemNumByID(iter_26_1)

		if arg_26_0.currentItem_:getComposeNum(iter_26_0) > var_26_1[iter_26_1] then
			local var_26_2 = var_0_5.new()

			var_26_2:populate({
				table_id = iter_26_1
			})
			table.insert(arg_26_0.stack_, var_26_2)

			return true
		else
			var_26_1[iter_26_1] = var_26_1[iter_26_1] - arg_26_0.currentItem_:getComposeNum(iter_26_0)
		end
	end

	return false
end

function var_0_0.getStackItem(arg_27_0)
	if #arg_27_0.stack_ > 0 then
		return arg_27_0.stack_[#arg_27_0.stack_]
	end

	local var_27_0 = arg_27_0.item:getCompose()

	if not next(var_27_0) or var_27_0[1] == 0 then
		return
	end

	table.insert(arg_27_0.stack_, arg_27_0.item)

	return arg_27_0:getStackItem()
end

function var_0_0.showAnimation(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_0:getComposeCount()
	local var_28_1 = arg_28_0:nodeByName("arraw" .. var_28_0)

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.currentItem_:getCompose()) do
		if arg_28_0.isAwakeTwiceItem and #arg_28_0.stack_ == 1 then
			iter_28_0 = iter_28_0 + 1
		end

		local var_28_2 = var_28_1:getChildByName("icon" .. iter_28_0)
		local var_28_3 = display.newNode()

		var_28_3:setContentSize(var_28_1:getChildByName("icon1"):getContentSize())
		var_28_3:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setItemBorder(var_28_3, iter_28_1)
		var_28_3:setPosition(cc.p(var_28_2:getPosition()))
		var_28_3:addTo(var_28_1)

		local var_28_4 = cc.MoveTo:create(0.7, cc.p(0, -80))

		if iter_28_0 == var_28_0 then
			var_28_3:runActionOnce(var_28_4, true, arg_28_1, 0.1)
		else
			var_28_3:runActionOnce(var_28_4, true, nil, 0.1)
		end
	end
end

function var_0_0.makeItem(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_0:getComposeCount()
	local var_29_1 = arg_29_0:nodeByName("arraw" .. var_29_0)

	var_29_1:show()

	for iter_29_0, iter_29_1 in ipairs(arg_29_0.currentItem_:getCompose()) do
		if arg_29_0.isAwakeTwiceItem and #arg_29_0.stack_ == 1 then
			iter_29_0 = iter_29_0 + 1
		end

		local var_29_2 = var_29_1:getChildByName("icon" .. iter_29_0)

		var_29_2:removeAllChildren()
		xyd.setItemBorder(var_29_2, iter_29_1)
	end

	local var_29_3 = xyd.tables.sound:getSound("hero_combine_equip")

	audio.playSound(var_29_3, false)

	if arg_29_0.currentItem_:composeMana() > arg_29_0.selfPlayer.mana then
		xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
			var_0_2:translation("JINBI_ABSENCE")
		}, function()
			local var_30_0 = xyd.FunctionID.ID_GOLD_HAND

			if arg_29_0.selfPlayer:isFuncOpen(var_30_0) == true then
				xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
			else
				local var_30_1 = xyd.tables.functionOpen:level(var_30_0)
				local var_30_2 = string.format(var_0_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_30_1)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_30_2
				})
			end
		end)
	else
		arg_29_0.selfPlayer:makeItem({
			item_id = arg_29_0.currentItem_:getTableID()
		}, function(arg_31_0)
			if arg_31_0 == xyd.error.OK then
				if not arg_29_0 or tolua.isnull(arg_29_0) then
					return
				end

				arg_29_0:dispatchEvent({
					name = xyd.event.ITEM_CHANGED
				})
				arg_29_0:showAnimation(function()
					arg_29_0:update()
					arg_29_0:setIcons()

					if arg_29_0.currentItem_ == arg_29_0.currentComposeItem_ then
						arg_29_0.btn_:setTouchEnabled(true)
					end

					if arg_29_1 then
						arg_29_1()
					end
				end)
			end
		end)
	end
end

function var_0_0.getBtn(arg_33_0)
	if not arg_33_0.btn_ then
		arg_33_0.btn_ = arg_33_0:nodeByName("button")

		arg_33_0.btn_:addTouchEventListener(function(arg_34_0, arg_34_1)
			xyd.buttonScaleAnim(arg_33_0.btn_, arg_34_1)

			if arg_34_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_33_0.isAwakeTwiceItem and arg_33_0.backpack:getItemNumByID(arg_33_0.item:getTableID()) > 0 then
					return
				end

				if arg_33_0:isHasMaterial() then
					arg_33_0:makeItem()
				elseif arg_33_0.currentItem_:isHasMaterial() then
					arg_33_0.currentComposeItem_ = arg_33_0.currentItem_

					arg_33_0:recursionCompose()
				elseif arg_33_0.isGainWay_ then
					if not arg_33_0.isCompose then
						xyd.WindowManager.get():closeWindow(xyd.WindowName.itemComposeWnd)
					else
						arg_33_0.gainListView_:removeAllItems()
						table.remove(arg_33_0.stack_, #arg_33_0.stack_)

						arg_33_0.currentItem_ = arg_33_0.stack_[#arg_33_0.stack_]

						arg_33_0.touchList_:reload()
						arg_33_0:update()
						arg_33_0:setIcons()
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("COMPOSE_ABSENCE")
					})
				end
			end
		end)
	end

	return arg_33_0.btn_
end

function var_0_0.delegate(arg_35_0, arg_35_1, arg_35_2, arg_35_3)
	if cc.ui.UIListView.COUNT_TAG == arg_35_2 then
		return #arg_35_0.stack_
	elseif cc.ui.UIListView.CELL_TAG == arg_35_2 then
		local var_35_0
		local var_35_1
		local var_35_2 = arg_35_0.touchList_:dequeueItem()

		if not var_35_2 then
			var_35_2 = arg_35_0.touchList_:newItem()
		else
			var_35_2:removeAllChildren()
		end

		local var_35_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/compose/item_tittle.csb")

		if arg_35_3 == #arg_35_0.stack_ then
			var_35_3:getChildByName("current_item_back"):setVisible(true)
			var_35_3:getChildByName("arrow"):setVisible(false)
		else
			var_35_3:getChildByName("current_item_back"):setVisible(false)
			var_35_3:getChildByName("arrow"):setVisible(true)
		end

		var_35_3:setContentSize(var_35_3:getChildByName("background"):getContentSize())
		xyd.setItemBorder(var_35_3:getChildByName("icon"), arg_35_0.stack_[arg_35_3]:getTableID())
		arg_35_0:initCell(var_35_3, arg_35_3)
		var_35_3:setAnchorPoint(cc.p(0, 0))
		var_35_3:setPosition(cc.p(0, 0))
		var_35_2:setItemSize(var_35_3:getWidth() + 10, var_35_3:getHeight())
		var_35_2:addContent(var_35_3)

		return var_35_2
	end
end

function var_0_0.initCell(arg_36_0, arg_36_1, arg_36_2)
	arg_36_1:setTouchEnabled(true)
	arg_36_1:setTouchSwallowEnabled(false)
	arg_36_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
		if arg_37_0.name == "began" then
			arg_36_1:getChildByName("icon"):setScale(0.9)

			arg_36_0.prevX_ = arg_37_0.x
			arg_36_0.prevY_ = arg_37_0.y
			arg_36_0.startClick_ = true
		elseif arg_37_0.name == "moved" then
			if math.abs(arg_37_0.y - arg_36_0.prevY_) > 5 or math.abs(arg_37_0.x - arg_36_0.prevX_) > 5 then
				arg_36_1:getChildByName("icon"):setScale(1)

				arg_36_0.startClick_ = false
			end
		elseif arg_37_0.name == "ended" and arg_36_0.startClick_ then
			arg_36_1:getChildByName("icon"):setScale(1)

			local var_37_0 = arg_36_0.stack_[arg_36_2]

			for iter_37_0 = #arg_36_0.stack_, arg_36_2 + 1, -1 do
				table.remove(arg_36_0.stack_, iter_37_0)
			end

			arg_36_0.currentItem_ = arg_36_0.stack_[arg_36_2]

			local var_37_1 = arg_36_0.stack_[arg_36_2]:getCompose()

			if next(var_37_1) and var_37_1[1] > 0 then
				arg_36_0:setIcons()
				arg_36_0:update()
			end
		end

		return true
	end)
end

function var_0_0.getComposeCount(arg_38_0)
	local var_38_0 = #arg_38_0.currentItem_:getCompose()

	if arg_38_0.isAwakeTwiceItem and #arg_38_0.stack_ == 1 then
		var_38_0 = var_38_0 + 1
	end

	return var_38_0
end

return var_0_0
