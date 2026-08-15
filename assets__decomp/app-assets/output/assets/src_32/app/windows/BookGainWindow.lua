local var_0_0 = class("BookGainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.getWayTable = xyd.tables.heroGetWayTable
	arg_1_0.campaigns = arg_1_0.selfPlayer.worldMaps_
	arg_1_0.maxChapter = arg_1_0.selfPlayer.super_chapter_id
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.getWayTable = xyd.tables.heroGetWayTable
	arg_1_0.campaigns = arg_1_0.selfPlayer.worldMaps_
	arg_1_0.maxChapter = arg_1_0.selfPlayer.super_chapter_id
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 20 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("list"):getWidth(), arg_3_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.updateStoneCampaign(arg_5_0)
	arg_5_0.listView_:removeAllItems()

	if arg_5_0.campaignID and #arg_5_0.campaignID > 0 then
		for iter_5_0 = 1, #arg_5_0.campaignID do
			local var_5_0 = display.newNode()
			local var_5_1 = arg_5_0.listView_:newItem()
			local var_5_2 = import("app.windows.StoneCampaignItem").new()
			local var_5_3 = xyd.tables.campaign:relateCampaign(arg_5_0.campaignID[iter_5_0])
			local var_5_4 = {
				campaignName = xyd.tables.campaign:campaignName(var_5_3),
				chapter = xyd.tables.campaign:chapter(var_5_3),
				campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]),
				icon = xyd.tables.campaign:icon(var_5_3),
				campaignID = arg_5_0.campaignID[iter_5_0]
			}

			var_5_2:setParams(var_5_4)
			var_5_2:setPosition(0, 0)
			var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_2:ignoreAnchorPointForPosition(false)
			var_5_2:addTo(var_5_0)

			local var_5_5 = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0])

			var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					var_5_2.contentView_:nodeByName("background"):setScale(0.9)
				end

				if arg_6_0.name == "moved" and arg_5_0.scrollViewMoved_ then
					var_5_2.contentView_:nodeByName("background"):setScale(1)
				end

				if arg_6_0.name == "ended" and not arg_5_0.scrollViewMoved_ then
					var_5_2.contentView_:nodeByName("background"):setScale(1)

					if arg_5_0.maxChapter >= xyd.tables.campaign:chapter(var_5_3) then
						arg_5_0.guild:loadGuildMap(function(arg_7_0)
							if arg_7_0 == xyd.error.OK then
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_7_0 = {}

								var_7_0.isStoneCampaign = true
								var_7_0.chapter = xyd.tables.campaign:chapter(var_5_3)
								var_7_0.campaignID = arg_5_0.campaignID[iter_5_0]
								var_7_0.campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]) - 1
								var_7_0.itemComposeID = arg_5_0.itemComposeID

								if var_7_0.campaignType == 23 then
									var_7_0.campaignType = 24
								end

								xyd.WindowManager.get():openWindow("map_window", var_7_0)
							else
								if xyd.WindowManager.get():getWindow("map_window") then
									xyd.WindowManager.get():closeWindow("map_window")
								end

								local var_7_1 = {
									isStoneCampaign = true,
									chapter = xyd.tables.campaign:chapter(var_5_3),
									campaignID = arg_5_0.campaignID[iter_5_0],
									campaignType = xyd.tables.campaign:campaignType(arg_5_0.campaignID[iter_5_0]) - 1,
									itemComposeID = arg_5_0.itemComposeID
								}

								xyd.WindowManager.get():openWindow("map_window", var_7_1)
							end
						end)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("CHAPTER_NOT_AVAILABLE")
						})
					end
				end

				return true
			end)
			var_5_1:addContent(var_5_0)
			var_5_0:setContentSize(402, 118)
			var_5_1:setItemSize(402, 125)
			arg_5_0.listView_:addItem(var_5_1)
		end
	end

	local var_5_6 = xyd.tables.item:gainType(arg_5_0.id)

	for iter_5_1 = 1, #var_5_6 do
		id = var_5_6[iter_5_1]

		if id ~= 0 then
			local var_5_7 = arg_5_0.listView_:newItem()
			local var_5_8 = arg_5_0:creatWayContent(id)

			var_5_7:addContent(var_5_8)
			var_5_8:setContentSize(402, 118)
			var_5_7:setItemSize(402, 125)
			arg_5_0.listView_:addItem(var_5_7)
		end
	end

	if (not arg_5_0.campaignID or #arg_5_0.campaignID <= 0) and var_5_6[1] == 0 then
		local var_5_9 = {
			size = 24,
			color = cc.c3b(13, 66, 128)
		}
		local var_5_10 = xyd.AssetLoader.get():loadLabel(var_5_9)

		var_5_10:setString(var_0_1:translation("BOOK_PIECE_NOT_GET"))

		local var_5_11 = arg_5_0:nodeByName("list"):getContentSize().width
		local var_5_12 = arg_5_0:nodeByName("list"):getContentSize().height
		local var_5_13, var_5_14 = arg_5_0:nodeByName("list"):getPosition()

		var_5_10:setAnchorPoint(cc.p(0.5, 0.5))
		var_5_10:addTo(arg_5_0:nodeByName("background"))
		var_5_10:setPosition(var_5_13 + var_5_11 / 2, var_5_14 + var_5_12 * 0.6)
	end

	arg_5_0.listView_:reload()
end

function var_0_0.creatWayContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/stone_campaign.csb")
	local var_8_2 = var_8_1:getChildByName("background")

	var_8_2:getChildByName("campaign_type_txt"):setVisible(false)
	var_8_2:getChildByName("left_times"):setVisible(false)

	local var_8_3 = arg_8_0.getWayTable:getIcon(arg_8_1)
	local var_8_4 = xyd.AssetLoader:get():loadSprite(var_8_3)

	var_8_4:setAnchorPoint(cc.p(0.5, 0.5))

	local var_8_5 = var_8_2:getChildByName("icon_node"):getContentSize().width / 2

	var_8_4:addTo(var_8_2:getChildByName("icon_node"))
	var_8_4:setPosition(cc.p(var_8_5, var_8_5))
	var_8_2:getChildByName("chapter_txt"):setString(arg_8_0.getWayTable:getName(arg_8_1))
	var_8_2:getChildByName("campaign_name"):setString(arg_8_0.getWayTable:getDesc(arg_8_1))
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_1:setName("source")
	var_8_1:setTouchEnabled(true)
	var_8_1:setTouchSwallowEnabled(false)
	var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_2:setScale(0.9)

			return true
		elseif arg_9_0.name == "moved" and arg_8_0.scrollViewMoved_ then
			var_8_2:setScale(1)
		elseif arg_9_0.name == "ended" and not arg_8_0.scrollViewMoved_ then
			var_8_2:setScale(1)

			local var_9_0 = arg_8_0.getWayTable:getFuncId(arg_8_1)

			if var_9_0 and arg_8_0.selfPlayer:isFuncOpen(var_9_0) ~= true then
				if xyd.WindowManager.get():isWindowOpen("toast") then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("FUNCTION_OPEN_TIP_OTHER")
				})

				return
			end

			if arg_8_0.getWayTable:getWindow(arg_8_1) == "peak_arena" then
				arg_8_0.shop_:loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.TOP
					})
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "arena" then
				arg_8_0.shop_:loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.ARENA
					})
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "shop" then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.MARCH
					})
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "team_main" then
				arg_8_0.shop_:loadShopList({}, function()
					xyd.WindowManager.get():openWindow("shop", {
						shop_type = xyd.ShopType.GUILD
					})
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "treasure_window" then
				xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):loadTreasureInfo(function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("treasure_window")
					end
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "pet_campaign" then
				xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_15_0)
					if arg_15_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("pet_campaign")
					end
				end)
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "march" then
				local var_9_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

				if var_9_1.mapInfo == nil then
					var_9_1:loadMarchInfo({}, function(arg_16_0)
						if arg_16_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("march")
						end
					end)
				else
					xyd.WindowManager.get():openWindow("march")
				end
			elseif arg_8_0.getWayTable:getWindow(arg_8_1) == "summon" then
				arg_8_0.selfPlayer:loadSummonInfo(nil, function()
					xyd.WindowManager.get():openWindow("summon")

					if xyd.StoryData.get():getGuideID() <= xyd.GuideStoryType.GUIDE_SUMMON_FREE_TWO then
						arg_8_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_SUMMON)
					end
				end, true)
			else
				xyd.WindowManager.get():openWindow(arg_8_0.getWayTable:getWindow(arg_8_1))
			end
		end
	end)

	return var_8_0
end

function var_0_0.layout(arg_18_0)
	arg_18_0:nodeByName("title_text"):setString(var_0_1:translation("ITEM_DETAIL_GAIN_WAY"))

	arg_18_0.campaignID = xyd.tables.item:map(arg_18_0.id)

	if arg_18_0.campaignID and arg_18_0.campaignID[1] == 0 then
		arg_18_0.campaignID = {}
	end

	arg_18_0:updateStoneCampaign()
end

function var_0_0.willClose(arg_19_0)
	return
end

function var_0_0.didClose(arg_20_0)
	return
end

return var_0_0
